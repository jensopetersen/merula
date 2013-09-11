xquery version "3.0";

declare boundary-space preserve;

declare function local:get-top-level-elements($input as element(), $edition-layer) {
    for $node in $input/node()
        let $position-start := string-length(string-join(local:separate-layers($node/preceding-sibling::node(), 'base'))) + string-length(string-join($node/preceding-sibling::text()))
        let $position-end := string-length(string-join(local:separate-layers($node/preceding-sibling::node(), 'base'))) + string-length(string-join($node/preceding-sibling::text())) + string-length(string-join(local:separate-layers(<node>{$node}</node>, 'base')))
        return
            if ($node instance of element())
            then     
                <annotation type="element" xml:id="{concat('uuid-', util:uuid())}">
                    <target type="range" layer="{if (local-name($node) = $edition-layer) then 'edition' else 'feature'}">
                        <id>{$node/../@xml:id}</id>
                        <start>{$position-start + 1}</start>
                        <offset>{$position-end - $position-start}</offset>
                    </target>
                    <body>
                        <node>{
                            if ($node/node() instance of text() and not($node/node() instance of element())) 
                            then 
                                element {node-name($node)} 
                                {for $attribute in $node/@* 
                                    return 
                                        attribute {node-name($attribute)} {$attribute/string()}}
                            else $node}        
                        </node>
                        <contents>{if ($node/node() instance of text() and not($node/node() instance of element())) then $node/text() else ()}</contents>
                    </body>
                        
                </annotation> 
                else ()    
};

declare function local:separate-layers($nodes as node()*, $target) as item()* {
    for $node in $nodes/node()
            return
            typeswitch($node)
                case text() return $node
                
                case element(lem) return if ($target eq 'base') then () else $node/text()
                case element(rdg) return if ($target eq 'base') then $node/text() else ()
                
                case element(reg) return if ($target eq 'base') then () else $node/text()
                case element(sic) return if ($target eq 'base') then $node/text() else ()
                
                case element(note) return if ($target eq 'base') then if ($node/@resp eq '#author') then $node/text() else () else ()
                (:NB: it is not clear what to do with "original annotations", e.g. notes in the original. Probably they should be collected alongon the same level as "edition" and "feature":)
                    default return local:separate-layers($node, $target)
};

let $input := <p xml:id="uuid-538a6e13-f88b-462c-a965-f523c3e02bbf">I <choice><reg>met</reg><sic>meet</sic></choice> <name target="#JM" type="person"><forename><app><lem wit="#a">Steve</lem><rdg wit="#b">Stephen</rdg></app></forename> <surname>Winwood</surname></name> and <name target="#AK" type="person">Alexis Korner</name> <pb n="3"></pb>in <rs>the pub</rs><note resp="#JØP">The author is probably wrong here.</note>.</p>

let $edition-layer := ('app', 'choice')

let $base-text := local:separate-layers($input, 'base')
    
let $authoritative-text := local:separate-layers($input, 'authoritative')

let $top-level-annotations :=
    <annotations>{local:get-top-level-elements($input, $edition-layer)}</annotations>    

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
                
            </result>