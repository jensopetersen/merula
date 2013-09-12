xquery version "3.0";

declare boundary-space preserve;

declare function local:get-top-level-elements($input as element(), $edition-layer) {
    for $node in $input/node()
        let $position-start := string-length(string-join(local:separate-layers($node/preceding-sibling::node(), 'base'))) + string-length(string-join($node/preceding-sibling::text()))
        let $position-end := string-length(string-join(local:separate-layers($node/preceding-sibling::node(), 'base'))) + string-length(string-join($node/preceding-sibling::text())) + string-length(string-join(local:separate-layers(<node>{$node}</node>, 'base')))
        return
            <annotation type="element" xml:id="{concat('uuid-', util:uuid())}">
                <target type="range" layer="{
                    if (local-name($node) = $edition-layer) 
                    then 'edition' 
                    else 
                        if ($node instance of element())
                        then 'feature'
                        else 'text'}">
                    <id>{$node/../@xml:id}</id>
                    <start>{if ($position-end eq $position-start) then $position-start else $position-start + 1}</start>
                    <offset>{$position-end - $position-start}</offset>
                </target>
                <body>{
                    if ($node instance of text()) 
                    then replace($node, ' ', '<space/>') 
                    else $node}</body>
                        <layer-offset-difference>{
                            let $off-set-difference :=
                                if (name($node) = $edition-layer or $node//app or $node//choice) 
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
            </annotation>
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

declare function local:insert-authoritative-layer-start($nodes as element()*) as element()* {
    for $annotation in $nodes/*
    
        let $id := concat('uuid-', util:uuid($annotation/target/id/@xml:id))
        
        let $previous-offsets := sum($annotation/preceding-sibling::annotation/layer-offset-difference, 0)
        let $present-start := $annotation/target/start cast as xs:integer
        let $authoritative-layer-start := $present-start + $previous-offsets
    
        let $layer-offset := $annotation/target/offset/number() + $annotation/layer-offset-difference
    
        let $authoritative-layer := <authoritative-layer><target><id xml:id="{$id}"></id><start>{$authoritative-layer-start}</start><offset>{$layer-offset}</offset></target></authoritative-layer>

            return local:insert-element($annotation, $authoritative-layer, 'annotation', 'last-child')
    
};

declare function local:insert-layer-offset($nodes as element()*) as element()* {
    for $annotation in $nodes/*
    let $layer-offset := $annotation/target/offset/number() + $annotation/layer-offset-difference
    let $layer-offset := <layer-offset>{$layer-offset}</layer-offset>
    
        return local:insert-element($annotation, $layer-offset, 'annotation', 'last-child')
    
};

declare function local:separate-layers($nodes as node()*, $target) as item()* {
    for $node in $nodes/node()
            return
            typeswitch($node)
                case text() return $node
                
                case element(lem) return if ($target eq 'base') then () else $node/string()
                case element(rdg) return 
                    if ($target eq 'base' and not($node/../lem))
                    then $node[@wit ne '#base']/string() 
                    else
                        if ($target ne 'base' and not($node/../lem))
                        then $node[@wit eq '#base']/string() 
                        else
                            if ($target eq 'base' and $node/../lem)
                            then $node/string()
                            else ()
                
                case element(reg) return if ($target eq 'base') then () else $node/string()
                case element(sic) return if ($target eq 'base') then $node/string() else ()
                
                case element(note) return if ($target eq 'base') then if ($node/@resp eq '#author') then $node/text() else () else ()
                (:NB: it is not clear what to do with "original annotations", e.g. notes in the original. Probably they should be collected on the same level as "edition" and "feature":)
                    default return local:separate-layers($node, $target)
};

let $input := <p xml:id="uuid-538a6e13-f88b-462c-a965-f523c3e02bbf">I <choice><reg>met</reg><sic>meet</sic></choice> <name ref="#SW" type="person"><forename><app><lem wit="#a">Steve</lem><rdg wit="#b">Stephen</rdg></app></forename> <surname>Winwood</surname></name> and <app><rdg wit="#base"><name ref="#AK" type="person">Alexis Korner</name></rdg><rdg wit="#c" ><name ref="#JM" type="person">John Mayall</name></rdg></app> <pb n="3"></pb>in <rs>the pub</rs><note resp="#JØP">The author is probably wrong here.</note>.</p>

let $edition-layer := ('app', 'choice')

let $base-text := local:separate-layers($input, 'base')
    
let $authoritative-text := local:separate-layers($input, 'authoritative')

let $top-level-annotations :=
    <annotations>{local:get-top-level-elements($input, $edition-layer)}</annotations>    

let $top-level-nodes := local:insert-layer-offset($top-level-annotations)
let $top-level-nodes := local:insert-authoritative-layer-start($top-level-annotations)


(: annotations are finished if they have string contents or if they have empty elements:)
let $finished-top-level-annotations :=    
        for $top-level-annotation in $top-level-annotations/*
        where 
            normalize-space($top-level-annotation/body/contents/string()) 
            or normalize-space($top-level-annotation/body/node/string()) eq ''
                return <annotations>{$top-level-annotation}</annotations>

let $unfinished-top-level-annotations := <annotations>{$top-level-annotations/* except $finished-top-level-annotations}</annotations>

     return 
            <result>
                <div type="inlined-text">{$input}</div>
                <div type="base-text">{$base-text}</div>
                <div type="authoritative-text">{$authoritative-text}</div>
                <div type="top-level-annotations">{$top-level-annotations}</div>
                <div type="top-level-nodes">{$top-level-nodes}</div>
            </result>