xquery version "3.0";

declare boundary-space preserve;

declare function local:get-base-text($input, $filter-away) {
    string-join(
        for $node in $input/node()
    return
        if ($node instance of element()) 
        then
            if (not(local-name($node) = $filter-away))
            then local:get-base-text($node, $filter-away)
            else ()
        else $node
    ,'')
    };

declare function local:get-top-level-elements($input as element(), $skip, $edition-layer) {
    for $node in $input/node()
    return
        if ($node instance of element())
        then     
            <annotation type="element" xml:id="{concat('uuid-', util:uuid())}">
                <target type="range" layer="{if (local-name($node) = $edition-layer) then 'edition' else 'feature'}">
                    <start>
                        <id>{$node/../@xml:id}</id>
                        <position>{string-length(string-join(local:get-base-text($node/preceding-sibling::node(), $skip))) + string-length(string-join($node/preceding-sibling::text(), ''))}</position>
                    </start>
                    <end>
                        <id>{$node/../@xml:id}</id>
                        <position>{
                            string-length(string-join(local:get-base-text($node/preceding-sibling::node(), $skip))) + string-length(string-join($node/preceding-sibling::text(), '')) + string-length(string-join(local:get-base-text($node, $skip)))}</position>
                    </end>
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
                </body>
                    <contents>{if ($node/node() instance of text() and not($node/node() instance of element())) then $node/text() else ()}</contents>
            </annotation> 
            else ()
    
};

let $input := <p xml:id="uuid-538a6e13-f88b-462c-a965-f523c3e02bbf">I <choice><reg>met</reg><sic>meet</sic></choice> <name target="#JM" type="person"><forename><app><lem wit="#a">Steve</lem><rdg wit="#b">Stephen</rdg></app></forename> <surname>Winwood</surname></name> and <name target="#AK" type="person">Alexis Korner</name> <pb n="3"></pb>in <rs>the pub</rs><note resp="#JØP">The author is probably wrong here.</note>.</p>

let $filter-away := ('rdg', 'del', 'reg')
let $edition-layer := ('app', 'choice')


return 
    <annotations>{local:get-top-level-elements($input, $filter-away, $edition-layer)}</annotations>