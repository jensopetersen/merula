xquery version "3.0";

declare boundary-space preserve;

declare function local:get-top-level-nodes-base-layer($input as element(), $edition-layer-elements) {
    for $node in $input/node()
        let $position-start := 
            string-length(string-join(local:separate-layers($node/preceding-sibling::node(), 'base'))) + 
            string-length(string-join($node/preceding-sibling::text()))
        let $position-end := $position-start + string-length(string-join(local:separate-layers(<node>{$node}</node>, 'base')))
        return
            <node type="element" xml:id="{concat('uuid-', util:uuid())}">
                <target type="range" layer="{
                    if (local-name($node) = $edition-layer-elements) 
                    then 'edition' 
                    else 
                        if ($node instance of element())
                        then 'feature'
                        else 'text'}">
                    <base-layer><id>{$node/../@xml:id}</id>
                    <start>{if ($position-end eq $position-start) then $position-start else $position-start + 1}</start>
                    <offset>{$position-end - $position-start}</offset>
                </base-layer></target>
                <body>{
                    if ($node instance of text()) 
                    then replace($node, ' ', '<space/>') 
                    else $node}</body>
                        <layer-offset-difference>{
                            let $off-set-difference :=
                                if (name($node) = $edition-layer-elements or $node//app or $node//choice) 
                                then 
                                    if (($node//app or name($node) = 'app') and $node//lem) 
                                    then string-length(string-join($node//lem)) - string-length(string-join($node//rdg))
                                    else 
                                        if (($node//app or name($node) = 'app') and $node//rdg) 
                                        then 
                                            let $non-base := string-length($node//rdg[@wit ne '#base'])
                                            let $base := string-length($node//rdg[@wit eq '#base'])(:NB: assumes only 2 rdg - one is the target rdg used instead of lem:)
                                                return 
                                                    $non-base - $base
                                        else
                                            if ($node//choice or name($node) = 'choice') 
                                            then string-length($node//reg) - string-length($node//sic)
                                            else 0
                                else 0
                            let $log := util:log("DEBUG", ("##$off-set-difference): ", $off-set-difference))
                                return $off-set-difference}</layer-offset-difference>
            </node>
};

declare function local:insert-element($node as node()?, $new-node as node(), 
    $element-name-to-check as xs:string, $location as xs:string) { 
        if (local-name($node) eq $element-name-to-check)
        then
            if ($location eq 'before')
            then ($new-node, $node) 
            else 
                if ($location eq 'after')
                then ($node, $new-node)
                else
                    if ($location eq 'first-child')
                    then element { node-name($node) } { 
                        $node/@*
                        ,
                        $new-node
                        ,
                        for $child in $node/node()
                            return 
                                (:local:insert-element($child, $new-node, $element-name-to-check, $location):)
                                $child
                    }
                    else
                        if ($location eq 'last-child')
                        then element { node-name($node) } { 
                            $node/@*
                            ,
                            for $child in $node/node()
                                return 
                                    (:local:insert-element($child, $new-node, $element-name-to-check, $location):)
                                    $child 
                            ,
                            $new-node
                        }
                        else () (:The $element-to-check is removed if none of the four options are used.:)
        else
            if ($node instance of element()) 
            then
                element { node-name($node) } { 
                    $node/@*
                    , 
                    for $child in $node/node()
                        return 
                            local:insert-element($child, $new-node, $element-name-to-check, $location) 
             }
         else $node
};

declare function local:insert-authoritative-layer($nodes as element()*) as element()* {
    for $node in $nodes/*
    
        let $id := concat('uuid-', util:uuid($node/target/base-layer/id/@xml:id))
        
        let $sum-of-previous-offsets := sum($node/preceding-sibling::node/layer-offset-difference, 0)
        let $base-level-start := $node/target/base-layer/start cast as xs:integer
        let $authoritative-layer-start := $base-level-start + $sum-of-previous-offsets
    
        let $layer-offset := $node/target/base-layer/offset/number() + $node/layer-offset-difference
    
        let $authoritative-layer := <authoritative-layer><id xml:id="{$id}"></id><start>{$authoritative-layer-start}</start><offset>{$layer-offset}</offset></authoritative-layer>
        
            return 
                local:insert-element($node, $authoritative-layer, 'base-layer', 'after')
    
};

declare function local:separate-layers($nodes as node()*, $target) as item()* {
    for $node in $nodes/node()
            return
            typeswitch($node)
                case text() return if (local-name($node/..) eq 'note') then () else $node/string()
                
                case element(lem) return if ($target eq 'base') then () else $node/string()
                case element(rdg) return 
                    if ($target eq 'base' and not($node/../lem))
                    then $node[@wit eq '#base']/string() 
                    else
                        if ($target ne 'base' and not($node/../lem))
                        then $node[@wit ne '#base']/string() 
                        else
                            if ($target eq 'base' and $node/../lem)
                            then $node/string()
                            else ()
                
                case element(reg) return if ($target eq 'base') then () else $node/string()
                case element(sic) return if ($target eq 'base') then $node/string() else ()
                
                (:NB: it is not clear what to do with "original annotations", e.g. notes in the original. Probably they should be collected on the same level as "edition" and "feature":)
                
                    default return local:separate-layers($node, $target)
};

let $input := <p xml:id="uuid-538a6e13-f88b-462c-a965-f523c3e02bbf">I <choice><reg>met</reg><sic>meet</sic></choice> <name ref="#SW" type="person"><forename><app><lem wit="#a">Steve</lem><rdg wit="#b">Stephen</rdg></app></forename> <surname>Winwood</surname></name> and <app><rdg wit="#base"><name ref="#AK" type="person">Alexis Korner</name></rdg><rdg wit="#c" ><name ref="#JM" type="person">John Mayall</name></rdg></app> <pb n="3"></pb>in <rs>the pub</rs><note resp="#JØP">The author is probably wrong here.</note>.</p>

let $edition-layer-elements := ('app', 'choice')

let $base-text := local:separate-layers($input, 'base')
    
let $authoritative-text := local:separate-layers($input, 'authoritative')

let $top-level-nodes-base-layer := <nodes>{local:get-top-level-nodes-base-layer($input, $edition-layer-elements)}</nodes>

let $top-level-nodes-base-and-authoritative-layer := local:insert-authoritative-layer($top-level-nodes-base-layer)

        return 
            <result>
                <div type="base-text">{string-join($base-text)}</div>
                <div type="authoritative-text">{string-join($authoritative-text)}</div>
                <div type="top-level-nodes-base-and-authoritative-layer">{$top-level-nodes-base-and-authoritative-layer}</div>
            </result>