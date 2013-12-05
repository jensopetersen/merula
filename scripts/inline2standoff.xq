xquery version "3.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare boundary-space preserve;

(: Removes elements named (identity transform) :)
declare function local:remove-elements($nodes as node()*, $remove as xs:anyAtomicType+)  as node()* {
   for $node in $nodes
   return
     if ($node instance of element())
     then 
        if ((local-name($node) = $remove))
        then ()
        else element {node-name($node)}
                {$node/@*,
                  local:remove-elements($node/node(), $remove)}
     else 
        if ($node instance of document-node())
        then local:remove-elements($node/node(), $remove)
        else $node
} ;

(: This function inserts elements supplied as $new-nodes at a certain position, determined by $element-names-to-check and $location, or removes the $element-names-to-check globally :)
declare function local:insert-elements($node as node(), $new-nodes as node()*, $element-names-to-check as xs:string+, $location as xs:string) {
        if ($node instance of element() and local-name($node) = $element-names-to-check)
        then
            if ($location eq 'before')
            then ($new-nodes, $node) 
            else 
                if ($location eq 'after')
                then ($node, $new-nodes)
                else
                    if ($location eq 'first-child')
                    then element {node-name($node)}
                        {
                            $node/@*
                            ,
                            $new-nodes
                            ,
                            for $child in $node/node()
                                return $child
                        }
                    else
                        if ($location eq 'last-child')
                        then element {node-name($node)}
                            {
                                $node/@*
                                ,
                                for $child in $node/node()
                                    return $child 
                                ,
                                $new-nodes
                            }
                        else () (:The $element-to-check is removed if none of the four options, e.g. 'remove', are used.:)
        else
            if ($node instance of element()) 
            then
                element {node-name($node)} 
                {
                    $node/@*
                    ,
                    for $child in $node/node()
                        return 
                            local:insert-elements($child, $new-nodes, $element-names-to-check, $location) 
                }
            else $node
};

(: Lifts off all upper-level element (and text) nodes and records their position in relation to the base layer. :)
(: NB: the text nodes are later filtered away and should later be removed, but they are nice to have since they allow reconstructing the whole process :)
declare function local:get-top-level-annotations-keyed-to-base-layer($input as element(), $edition-layer-elements) {
    for $node in $input/node()
        let $base-before-element := string-join(local:separate-layers($node/preceding-sibling::node(), 'base'))
        let $base-before-text := string-join($node/preceding-sibling::text())
        let $marked-up-string := string-join(local:separate-layers(<annotation>{$node}</annotation>, 'base'))
        let $position-start := 
            string-length($base-before-element) + 
            string-length($base-before-text)
        let $position-end := $position-start + string-length($marked-up-string)
        return
            <annotation type="{
                if ($node instance of text())
                then 'text'
                else 
                    if ($node instance of element())
                    then 'element'
                    else 'unknown'
                }" xml:id="{concat('uuid-', util:uuid())}" status="{
                    let $base-text := string-join(local:separate-layers($input, 'base'))
                    let $character-before := substring($base-text, $position-start, 1)
                    let $character-after := substring($base-text, $position-end + 1, 1)
                    let $characters-before-and-after := concat($character-before, $character-after)
                    let $characters-before-and-after := replace($characters-before-and-after, '\s|\p{P}', '')
                    return
                    if ($characters-before-and-after) then "string" else "token"}">(: If the targeted text is a word, i.e. has either space or punctuation on both sides, label it as "token" - in the editor tokens have to be labeled, since adding or removing a word has to take into consideration its isolation from neighbouring words. NB: think of a better label than "string":)
                <target type="range" layer="{
                    if ($node instance of text())
                    then 'text'
                    else
                        if (local-name($node) = $edition-layer-elements) 
                        then 'edition' 
                        else 
                            if ($node instance of element())
                            then 'feature'
                            else 'unknown'}">
                    <base-layer>
                        <id>{string($node/../@xml:id)}</id>
                        <start>{if ($position-end eq $position-start) then $position-start else $position-start + 1}</start>
                        <offset>{$position-end - $position-start}</offset>
                    </base-layer>
                </target>
                <body>{$node}</body>
                <layer-offset-difference>{
                    let $off-set-difference :=
                        if (name($node) = $edition-layer-elements or $node//app or $node//choice) 
                        then
                            if (($node//app or name($node) = 'app') and $node//tei:lem) 
                            then string-length(string-join($node//tei:lem)) - string-length(string-join($node//tei:rdg[not(contains(@wit/string(), 'TS1'))]))
                            else 
                                if (($node//tei:app or name($node) = 'app') and $node//tei:rdg) 
                                then 
                                    let $non-base := string-length($node//tei:rdg[not(contains(@wit/string(), 'TS1'))])
                                    let $base := string-length($node//tei:rdg[contains(@wit/string(), 'TS1')])
                                        return 
                                            $non-base - $base
                                else
                                    if ($node//tei:choice or name($node) = 'choice') 
                                    then string-length($node//tei:reg) - string-length($node//tei:sic)
                                    else 0
                        else 0            
                            return $off-set-difference}</layer-offset-difference>
                <admin>
                    <creation>
                        <user>{xmldb:get-current-user()}</user>
                        <time>{current-dateTime()}</time>
                        <note/>
                    </creation>
                    <review><user/><time/><note/></review>
                    <imprimatur><user/><time/></imprimatur>
                </admin>
            </annotation>
};


(: For each annotation keyed to the base layer, insert its location in relation to the authoritative layer, adding the previous offsets to the start position  :)
(: NB: this function could be moved inside local:get-top-level-annotations-keyed-to-base-layer():)
declare function local:insert-authoritative-layer($nodes as element()*) as element()* {
    for $node in $nodes
        let $id := concat('uuid-', util:uuid($node/target/base-layer/id)) (:create a UUID based on the UUID of the base layer:)
        let $sum-of-previous-offsets := sum($node/preceding-sibling::annotation/layer-offset-difference, 0)
        let $base-level-start := $node/target/base-layer/start cast as xs:integer
        let $authoritative-layer-start := $base-level-start + $sum-of-previous-offsets
        let $layer-offset := $node/target/base-layer/offset/number() + $node/layer-offset-difference
        let $authoritative-layer := <authoritative-layer><id>{$id}</id><start>{$authoritative-layer-start}</start><offset>{$layer-offset}</offset></authoritative-layer>
            return
                local:insert-elements($node, $authoritative-layer, 'base-layer', 'after')
};

(: Based on a list of TEI elements that alter the text, construct the altered (authoritative) or the unaltered (base) text :)
declare function local:separate-layers($input as node()*, $target) as item()* {
    for $node in $input/node()
        return
            typeswitch($node)
                
                case text() return 
                    if ($node/ancestor-or-self::element(tei:note)) 
                    then () 
                    else $node
                    (:NB: it is not clear what to do with "original annotations", e.g. notes in the original. Probably they should be collected on the same level as "edition" and "feature" (along with other instances of "misplaced text")
                    Here we strip out all notes from the text itself and put them into the annotations.:)
                
                case element(tei:lem) return 
                    if ($target eq 'base') 
                    then () 
                    else $node
                
                case element(tei:rdg) return
                    if (not($node/../tei:lem))
                    then
                        if ($target eq 'base')
                        then $node[contains(@wit/string(), 'TS1')] (:if there is no lem, choose a rdg for the base text:)
                        else
                            if ($target ne 'base')
                            then $node[contains(@wit/string(), 'TS2')] (:if there is no lem, choose a rdg for the target text:)
                            else ()
                    else
                        if ($target eq 'base')
                        then $node[contains(@wit/string(), 'TS1')] (:if there is a lem, choose a rdg for the base text:)
                        else ()
                
                case element(tei:reg) return
                    if ($target eq 'base') 
                    then () 
                    else $node
                
                case element(tei:sic) return 
                    if ($target eq 'base') 
                    then $node
                    else ()
                
                        default return local:separate-layers($node, $target)
};

(: operates on result of separate-layers :)
declare function local:collapse-inline-elements($nodes as node()*, $block-elements as xs:string+) as node()* {
   for $node in $nodes/node()
   return
     if ($node instance of element())
     then
        if (local-name($node) = $block-elements)
        then element {node-name($node)}
                {$node/@*,
                  local:collapse-inline-elements($node, $block-elements)}
        else $node/node()
     else 
        if ($node instance of document-node())
        then local:collapse-inline-elements($node, $block-elements)
        else $node
};

declare function local:handle-element-annotations($node as node()) as item()* {
            let $layer-1-body-contents := $node//body/* (:get the element below body - this can ony be a single element:)
            let $layer-1-body-contents := element {node-name($layer-1-body-contents)}{
                for $attribute in $layer-1-body-contents/@*
                    return attribute {name($attribute)} {$attribute}} (:construct empty element with attributes:)
            let $layer-1 := local:remove-elements($node, 'body') (:remove the body,:)
            let $layer-1 := local:insert-elements($layer-1, <body>{$layer-1-body-contents}</body>, 'target', 'after') (:and insert the new body:)
                return $layer-1
                (:return the old annotation, with an empty element below body:)
            ,
            let $layer-1-id := $node/@xml:id/string() (: get id :)
            let $layer-1-status := $node/@status/string() (: get the status of original annotation :)
            let $layer-1-admin-contents := $node//admin/* (:get the elements below admin:)
            let $layer-2-body-contents := $node//body/*/* (: get the contents of what is below the body - the empty element in layer-1; there may be multiple elements here.:)
            for $element at $i in $layer-2-body-contents
            (: returns the new annotations, with the contents from the old annotation below body split over several annotations; record their order instead of start position and offset :)
                let $result :=
                    <annotation type="element" xml:id="{concat('uuid-', util:uuid())}" status="{$layer-1-status}">
                        <target type="element" layer="annotation">
                            <annotation-layer>
                                <id>{$layer-1-id}</id>
                                <order>{$i}</order>
                            </annotation-layer>
                        </target>
                        <body>{$element}</body>
                        <admin>{$layer-1-admin-contents}</admin>
                    </annotation>
                    return
                        if (not($result//body/string()) or $result//body/*/node() instance of text() or $result//body/node() instance of text())
                        then $result 
                        else local:whittle-down-annotations($result)
};

declare function local:handle-mixed-content-annotations($node as node()) as item()* {
    (:An annotation with mixed contents should be split up into text annotations and element annotations, in the same manner that the top-level annotations were extracted from the input:)
            let $layer-1-body-contents := $node//body/*(:get element below body - this can ony be a single element:)
            let $layer-1-body-contents := element {node-name($layer-1-body-contents)}{
                for $attribute in $layer-1-body-contents/@*
                    return attribute {name($attribute)} {$attribute}} (:construct empty element with attributes:)
            let $layer-1 := local:remove-elements($node, 'body')(:remove the body,:)
            let $layer-1 := local:insert-elements($layer-1, <body>{$layer-1-body-contents}</body>, 'target', 'after')(:and insert the new body:)
                return $layer-1
            ,
            let $layer-2-body-contents := local:get-top-level-annotations-keyed-to-base-layer($node//body/*, '')
            let $layer-1-id := <id>{$node/@xml:id/string()}</id>
            for $layer-2-body-content in $layer-2-body-contents
                return
                    let $layer-2-body-content := local:remove-elements($layer-2-body-content, ('id', 'layer-offset-difference'))
                    let $layer-2 := local:insert-elements($layer-2-body-content, $layer-1-id, 'start', 'before')
                        return
                            if (not($layer-2//body/string()) or $layer-2//body/*/node() instance of text() or $layer-2//body/node() instance of text())
                        then $layer-2
                        else local:whittle-down-annotations($layer-2)
};

(: Removes one layer at a time from the upper-level annotations, reducing them, if neccesary, until they consist either of an empty element, or an element exclusively with a text node :)
declare function local:whittle-down-annotations($node as node()) as item()* {
            if (not($node//body/string())) (: there is no text anywhere (an empty element), so pass through:)
            then $node
            else 
                if ($node//body/*/node() instance of text()) (: there is one level until text node (but no mixed contents), so pass through :)
                then $node
                else 
                    if (count($node//body/*/*) eq 1 and $node//body/*/*[../text()]) (: there is mixed contents, so send on and receive back in reduced form:) (: if there is an element (the second '*') and if its parent (backtracking to the first '*') is a text node, then we are dealing with mixed contents:)
                    then local:handle-mixed-content-annotations($node)
                    else local:handle-element-annotations($node) (:if it is not an empty element, if it is not exclusively a text node and if it is not mixed contents, then it is exclusively one or more element nodes, so send on and receive back in reduced form :)
};

declare function local:generate-text($element as element(), $target as xs:string) as element() {
    element {node-name($element)}
    {$element/@*,
    for $child in $element/node()
        return
            if ($child instance of element() and not($child/text()))
            then local:generate-text($child, $target)
            else
                if ($child instance of element() and exists($child/text()))
                then 
                    element {node-name($child)}
                    {
                        for $attribute in $child/@*
                            return
                                if (name($attribute) eq 'xml:id')
                                then attribute {'xml:id'}{concat('uuid-', util:uuid(concat('base-text', $child/@xml:id)))} (: construct a new UUID based on old one :)
                                else attribute {name($attribute)} {$attribute}
                            ,
                            string-join(local:separate-layers($child, $target))
                    }
                else $child
    }
};

declare function local:generate-top-level-annotations($element as element()*, $edition-layer-elements as xs:string+) as element()* {
    
    for $child in $element
        return
            if ($child instance of element() and $child/text())
            then local:get-top-level-annotations-keyed-to-base-layer($child, $edition-layer-elements)
            else 
                if ($child instance of element())
                then local:generate-top-level-annotations($child, $edition-layer-elements)
                else ()
};

let $doc-title := 'sample_MTDP10363.xml'
let $doc := doc(concat('/db/test/out/', $doc-title))
let $doc-element := $doc/*
let $doc-header := $doc-element/tei:teiHeader
let $doc-text := $doc-element/tei:text


let $edition-layer-elements := ('app', 'choice', 'reg', 'sic', 'rdg', 'lem')
let $block-elements := ('p', 'head', 'quote', 'div', 'body', 'text')

let $base-text := local:generate-text($doc-text, 'base')
let $base-text := local:collapse-inline-elements($base-text, $block-elements)

let $authoritative-text := local:generate-text($doc-text, 'authoritative')
let $authoritative-text := local:collapse-inline-elements($authoritative-text, $block-elements)

(: get all the block-level elements that have edition-layer-elements as children :)
let $doc-elements-with-annotations := $doc//*[local-name(.) = $edition-layer-elements][local-name(./..) = $block-elements]/..

let $top-level-annotations := local:generate-top-level-annotations($doc-elements-with-annotations, $edition-layer-elements)

let $top-level-annotations := local:insert-authoritative-layer($top-level-annotations)

let $annotations :=
    for $node in $top-level-annotations
        where $node/body/node() instance of element() (:filters away pure text nodes:)
    return 
        local:whittle-down-annotations($node)

        return 
            <result>
                <base-text>{element {node-name($doc-element)}{$doc-element/@*}}{$doc-header}{element {node-name($doc-text)}{$doc-text/@*, $base-text}}</base-text>
                <authoritative-text>{element {node-name($doc-element)}{$doc-element/@*}}{$doc-header}{element {node-name($doc-text)}{$doc-text/@*, $authoritative-text}}</authoritative-text>
                <annotations>{$annotations}</annotations>
            </result>