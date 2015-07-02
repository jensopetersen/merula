xquery version "3.0";

declare namespace a8n="http://exist-db.org/xquery/a8n";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare boundary-space preserve;

declare variable $in-collection := '/db/test/in';
declare variable $out-collection := '/db/test/out/annotations';

(: Removes elements named :)
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
                        else () (:The $element-to-check is removed if none of the four options are used, e.g. if 'remove' is used.:)
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

(: Extracts all upper-level element nodes from the input element and records their position in relation to the base layer; extracts all attributes of the input element. :)
declare function local:get-top-level-annotations-keyed-to-base-text($input as element(), $edition-layer-elements as xs:string+, $documentary-elements as xs:string+) {
    for $node in $input/element()
        let $base-before-element := string-join(local:separate-text-layers($node/preceding-sibling::node(), 'base'))
        let $base-before-text := string-join($node/preceding-sibling::text())
        let $marked-up-string := string-join(local:separate-text-layers(<a8n:annotation>{$node}</a8n:annotation>, 'base'))
        let $id := concat('uuid-', util:uuid())
        let $position-start := string-length($base-before-element) + string-length($base-before-text)
        let $position-end := $position-start + string-length($marked-up-string)
        let $preceding-sibling-node := $node/preceding-sibling::node()[1]
        let $following-sibling-node := $node/following-sibling::node()[1]

            return
                let $element-result :=
                    <a8n:annotation type="element" xml:id="{$id}" status="{
                            let $base-text := string-join(local:separate-text-layers($input, 'base'))
                            let $character-before := substring($base-text, $position-start, 1)
                            let $character-after := substring($base-text, $position-end + 1, 1)
                            let $characters-before-and-after := concat($character-before, $character-after)
                            let $characters-before-and-after := replace($characters-before-and-after, '\s|\p{P}', '')
                            return
                            if ($characters-before-and-after) then "string" else "token"
                            (: If the targeted text is a word, i.e. has either space or punctuation on both sides, label it as "token" - in the editor tokens have to be labeled, since adding or removing a word has to take into consideration its isolation from neighbouring words. NB: think of a better label than "string":)
                        }">
                        <a8n:target type="range" layer="{
                            if (local-name($node) = $edition-layer-elements) 
                            then 'edition' 
                            else 
                                if (local-name($node) = $documentary-elements)
                                then 'document' 
                                else 'feature'}">
                            <a8n:base-layer>
                                <a8n:parent-element-name>{local-name($node/parent::*)}</a8n:parent-element-name>
                                <a8n:preceding-sibling-node>{
                                    if ($preceding-sibling-node instance of element())
                                    then (<a8n:node-type>element</a8n:node-type>, <a8n:node-name>{local-name($preceding-sibling-node)}</a8n:node-name>)
                                    else 
                                        if ($preceding-sibling-node instance of text())
                                        then <a8n:node-type>text</a8n:node-type>
                                        else
                                            if ($preceding-sibling-node instance of comment())
                                            then <a8n:node-type>comment</a8n:node-type>
                                            else 
                                                if ($preceding-sibling-node instance of processing-instruction())
                                            then (<a8n:node-type>processing-instruction</a8n:node-type>, <a8n:node-name>{local-name($preceding-sibling-node)}</a8n:node-name>)
                                            else ()
                                }</a8n:preceding-sibling-node>
                                <a8n:following-sibling-node>{
                                    if ($following-sibling-node instance of element())
                                    then (<a8n:node-type>element</a8n:node-type>, <a8n:node-name>{local-name($following-sibling-node)}</a8n:node-name>)
                                    else 
                                        if ($following-sibling-node instance of text())
                                        then <a8n:node-type>text</a8n:node-type>
                                        else
                                            if ($following-sibling-node instance of comment())
                                            then <a8n:node-type>comment</a8n:node-type>
                                            else 
                                                if ($following-sibling-node instance of processing-instruction())
                                            then (<a8n:node-type>processing-instruction</a8n:node-type>, <a8n:node-name>{local-name($following-sibling-node)}</a8n:node-name>)
                                            else ()
                                }</a8n:following-sibling-node>
                                <a8n:id>{$node/parent::*/@xml:id/string()}</a8n:id>
                                <a8n:start>{$position-start + 1}</a8n:start>
                                <a8n:offset>{$position-end - $position-start}</a8n:offset>
                            </a8n:base-layer>
                        </a8n:target>
                        <a8n:body>{element {node-name($node)}{$node/@xml:id, $node/node()}}</a8n:body>
                        <a8n:layer-offset-difference>{
                            let $off-set-difference :=
                                if (local-name($node) = $edition-layer-elements or $node//tei:app or $node//tei:choice) 
                                then
                                    if (($node//tei:app or local-name($node) = 'app') and $node//tei:lem) 
                                    then string-length(string-join($node//tei:lem)) - string-length(string-join($node//tei:rdg[not(contains(@wit/string(), 'TS1'))]))
                                    else 
                                        if (($node//tei:app or local-name($node) = 'app') and $node//tei:rdg)
                                        then 
                                            string-length($node//tei:rdg[not(contains(@wit/string(), 'TS1'))]) - string-length($node//tei:rdg[contains(@wit/string(), 'TS1')])
                                        else
                                            if (($node//tei:choice or local-name($node) = 'choice') and $node//tei:orig and $node//tei:reg)
                                            then string-length($node//tei:reg) - string-length($node//tei:orig)
                                            else
                                                if (($node//tei:choice or local-name($node) = 'choice') and $node//tei:expan and $node//tei:expan)
                                                then string-length($node//tei:expan) - string-length($node//tei:abbr)
                                                else
                                                    if (($node//tei:choice or local-name($node) = 'choice') and $node//tei:sic and $node//tei:corr)
                                                    then string-length($node//tei:corr) - string-length($node//tei:sic)
                                                    else 0
                                                
                                else 0            
                                    return $off-set-difference}</a8n:layer-offset-difference>
                        <a8n:admin/>
                    </a8n:annotation>
                let $attribute-result := 
                        for $attribute in $node/(@* except @xml:id) (:NB: what about xml:base and xml:space?:)
                            return 
                                <a8n:annotation type="attribute" xml:id="{concat('uuid-', util:uuid())}">
                                    <a8n:target type="element" layer="annotation">
                                        <a8n:id>{$node/@xml:id/string()}</a8n:id>
                                    </a8n:target>
                                    <a8n:body>
                                        <a8n:attribute>
                                            <a8n:name>{name($attribute)}</a8n:name>
                                            <a8n:value>{$attribute/string()}</a8n:value>
                                        </a8n:attribute>
                                    </a8n:body>
                                    <a8n:admin/>
                                </a8n:annotation>
            return ($element-result, $attribute-result)
};

(: For each annotation keyed to the base layer, insert its location in relation to the authoritative layer by adding the previous offsets to the start position. :)
(: NB: this function could be moved inside local:get-top-level-annotations-keyed-to-base-text():)
declare function local:insert-authoritative-layer-in-top-level-annotations($nodes as element()*) as element()* {
    (
    $nodes[@type ne 'element']
    ,
    for $node in $nodes[@type eq 'element']
        let $id := concat('uuid-', util:uuid($node/a8n:target/a8n:base-layer/a8n:id))
        let $sum-of-previous-offsets := sum($node/preceding-sibling::a8n:annotation/a8n:layer-offset-difference, 0)
        let $base-level-start := $node/a8n:target/a8n:base-layer/a8n:start cast as xs:integer
        let $authoritative-layer-start := $base-level-start + $sum-of-previous-offsets
        let $layer-offset := $node/a8n:target/a8n:base-layer/a8n:offset + $node/a8n:layer-offset-difference
        let $authoritative-layer := 
            <a8n:authoritative-layer>
                <a8n:id>{$id}</a8n:id>
                <a8n:start>{$authoritative-layer-start}</a8n:start>
                <a8n:offset>{$layer-offset}</a8n:offset>
                </a8n:authoritative-layer>
            return
                local:insert-elements($node, $authoritative-layer, 'base-layer', 'after')
    )
};

(: Based on a list of TEI elements that alter the text, construct the altered (authoritative) or the unaltered (base) text :)
declare function local:separate-text-layers($input as node()*, $target) as item()* {
    for $node in $input/node()
        return
            typeswitch($node)
                
                case text() return
                    if ($node/ancestor-or-self::element(tei:note)) 
                    then ()
                    else $node
                    (:NB: it is not clear what to do with "original annotations", e.g. notes in the original. Probably they should be collected on the same level as "edition" and "feature" (along with other instances of "misplaced text", such as figure captions)
                    Here we strip out all notes from the text itself and put them into the annotations.:)
                
                case element(tei:lem) return 
                    if ($target eq 'base') 
                    then ()
                    else $node
                
                case element(tei:rdg) return
                    if ($node/preceding-sibling::tei:lem)
                    then
                    (:if the app has a lem along with the rdg:)
                        if ($target eq 'base')
                        then 
                            if ($node[contains(@wit/string(), 'TS1')])
                            (:TODO: an approach using tokenize() should be used instead:)
                            then $node
                            else ()
                        (:if there is a lem, choose a rdg for the base text:)
                        else ()
                        (:disregard the rdg for the authoritative text if there is a lem:)
                    else
                    (:if the app has no lem along with the rdg:)
                        if ($target eq 'base')
                        then 
                            if ($node[contains(@wit/string(), 'TS1')])
                            then $node
                            else ()
                            (:if there is no lem, choose a TS1 rdg for the base text if there is one:)
                        else
                            if ($node[contains(@wit/string(), 'TS2')])
                            then $node
                            else ()
                            (:if there is no lem, choose a TS2 rdg for the authoritative text:)
                
                case element(tei:reg) return
                    if ($target eq 'base')
                    then () 
                    else $node
                case element(tei:corr) return
                    if ($target eq 'base') 
                    then () 
                    else $node
                case element(tei:expan) return
                    if ($target eq 'base') 
                    then () 
                    else $node
                case element(tei:orig) return
                    if ($target eq 'base') 
                    then $node
                    else ()
                case element(tei:sic) return
                    if ($target eq 'base') 
                    then $node
                    else ()
                case element(tei:abbr) return
                    if ($target eq 'base') 
                    then $node
                    else ()

                    default return local:separate-text-layers($node, $target)
};
(: This function removes inline elements from the result of generate-text-layer() :)
declare function local:remove-inline-elements($nodes as node()*, $block-element-names as xs:string+) as node()* {
    for $node in $nodes/node()
    return
        if ($node instance of element())
        then
            if (local-name($node) = $block-element-names)
            then element {node-name($node)}
                    {$node/@*,local:remove-inline-elements($node, $block-element-names)}
            else $node/text()
        else $node
};

declare function local:handle-element-only-annotations($node as node(), $documentary-elements as xs:string+) as item()* {
            let $layer-1-body-contents := $node//a8n:body/* (: get the element below body - this can ony be a single item :)
            let $layer-1-admin-contents := $node//a8n:admin/* (: get the elements below admin :)
            let $layer-1-id := $node/@xml:id/string() (: get id :)
            let $layer-1-body-attributes :=
                for $attribute in $layer-1-body-contents/(@* except @xml:id)
                (:NB: does this occur at all?:)
                    return 
                        <a8n:annotation type="attribute" xml:id="{concat('uuid-', util:uuid())}">
                            <a8n:target type="element" layer="annotation">
                                <a8n:id>{$layer-1-id}</a8n:id>
                            </a8n:target>
                            <a8n:body>
                                <a8n:attribute>
                                    <a8n:name>{name($attribute)}</a8n:name>
                                    <a8n:value>{$attribute/string()}</a8n:value>
                                </a8n:attribute>
                            </a8n:body>
                            <a8n:admin/>
                        </a8n:annotation>
            let $layer-1-body-contents := element {node-name($layer-1-body-contents)}{$layer-1-body-contents/@xml:id}
            (:construct empty element:)
            let $layer-1 := local:remove-elements($node, 'body') (:remove the old body,:)
            let $layer-1 := local:insert-elements($layer-1, <a8n:body>{$layer-1-body-contents}</a8n:body>, 'target', 'after') (: and insert the new body:)
                return ($layer-1, $layer-1-body-attributes)
                (:return the old annotation, with an empty element below body:)
            ,
            let $layer-1-id := $node/@xml:id/string() (: get id :)
            let $layer-1-status := $node/@status/string() (: get the status of original annotation :)
            let $layer-1-admin-contents := $node//a8n:admin/* (:get the elements below admin:)
            let $layer-2-body-contents := $node//a8n:body/*/* (: get the contents of what is below the body - the empty element in layer-1; there may be multiple elements here.:)
            for $element at $i in $layer-2-body-contents
                let $annotation-id := concat('uuid-', util:uuid())
            (: returns the new annotations, with the contents from the old annotation below body split over several annotations; record their order instead of start position and offset :)
                let $attribute-annotations := 
                    for $attribute in $element/(@* except @xml:id)
                        return 
                            <a8n:annotation type="attribute" xml:id="{concat('uuid-', util:uuid())}">
                                <a8n:target type="element" layer="annotation">
                                    <a8n:id>{$annotation-id}</a8n:id>
                                </a8n:target>
                                <a8n:body>
                                    <a8n:attribute>
                                        <a8n:name>{name($attribute)}</a8n:name>
                                        <a8n:value>{$attribute/string()}</a8n:value>
                                    </a8n:attribute>
                                </a8n:body>
                                <a8n:admin/>
                            </a8n:annotation>
                let $element-annotations :=
                    <a8n:annotation type="element" xml:id="{$annotation-id}" status="{$layer-1-status}">
                        <a8n:target type="element" layer="annotation">
                            <a8n:annotation-layer>
                                <a8n:id>{$layer-1-id}</a8n:id>
                                <a8n:order>{$i}</a8n:order>
                            </a8n:annotation-layer>
                        </a8n:target>
                        <a8n:body>{element {node-name($element)}{$element/@xml:id, $element/node()}}</a8n:body>
                        <a8n:admin/>
                    </a8n:annotation>
                    return
                        (
                        if (not($element-annotations//a8n:body/string()) or $element-annotations//a8n:body/*/node() instance of text() or $element-annotations//a8n:body/node() instance of text())
                        then $element-annotations 
                        else local:whittle-down-annotations($element-annotations, $documentary-elements)
                        ,
                        $attribute-annotations
                        )
};

declare function local:handle-mixed-content-annotations($node as node(), $documentary-elements as xs:string+) as item()* {
    (:An annotation with mixed contents should be split up into text annotations and element annotations, in the same manner that the top-level annotations were extracted from the input, except that no edition-layer-elements are relevant:)
            let $layer-1-body-contents := $node//a8n:body/*(:get element below body - this can ony be a single element:)
            let $layer-1-body-contents := element {node-name($layer-1-body-contents)}{
                for $attribute in $layer-1-body-contents/(@* except @xml:id)
                    return attribute {name($attribute)} {$attribute}} (:construct empty element with attributes:)
            let $layer-1 := local:remove-elements($node, 'body')(:remove the body,:)
            let $layer-1 := local:insert-elements($layer-1, <a8n:body>{$layer-1-body-contents}</a8n:body>, 'target', 'after')(:and insert the new body:)
                return $layer-1
            ,
            let $layer-2-body-contents := local:get-top-level-annotations-keyed-to-base-text($node//a8n:body/*, '', $documentary-elements)
            let $layer-1-id := <a8n:id>{$node/@xml:id/string()}</a8n:id>
            for $layer-2-body-content in $layer-2-body-contents
                return
                    let $layer-2-body-content := local:remove-elements($layer-2-body-content, ('id', 'layer-offset-difference'))
                    let $layer-2 := local:insert-elements($layer-2-body-content, $layer-1-id, 'start', 'before')
                        return
                            if (not($layer-2//a8n:body/string()) or $layer-2//a8n:body/*/node() instance of text() or $layer-2//a8n:body/node() instance of text())
                        then $layer-2
                        else local:whittle-down-annotations($layer-2, $documentary-elements)
};

(: Removes one layer at a time from the upper-level annotations, reducing them, if neccesary, until they consist either of an empty element, or an element with a text node :)
declare function local:whittle-down-annotations($node as node(), $documentary-elements as xs:string+) as item()* {
            if (not($node//a8n:body/string())) (: it is an empty element, so extract its attributes, if any:)
            then local:handle-element-only-annotations($node, $documentary-elements)
            else 
                if (local-name($node//a8n:body/*) eq 'attribute') (: it is an attribute annotation, so do not split it up, but pass it through. :)
                then $node
                else
                    if (count($node//a8n:body/*/*) ge 1 and $node//a8n:body/*[./text()]) (: there is mixed contents, so send on and receive back in reduced form; if there is an element (the second '*') and if its parent (the first '*') is a text node, then we are dealing with mixed contents:)
                    then local:handle-mixed-content-annotations($node, $documentary-elements)
                    else 
                        if ($node//a8n:body/*/node() instance of text()) (: there is one level until the text node (but no mixed contents), so pass through as an element with a text node. :)
                        then $node
                        else local:handle-element-only-annotations($node, $documentary-elements) (:if it is not an empty element, if it is not an attribute, and if it is not mixed contents, then it is a nested element node, so send it on to be reduced :)
};

declare function local:generate-text-layer($element as element(), $target as xs:string) as element() 
    (:reconstruct the passed element with xml attributes:)
    {
    element {node-name($element)}
    {if ($element/@xml:id) then attribute{'xml:id'}{$element/@xml:id} else attribute{'xml:id'}{concat('uuid-', util:uuid())},
    if ($element/@xml:base) then attribute{'xml:base'}{$element/@xml:base} else (),
    if ($element/@xml:space) then attribute{'xml:space'}{$element/@xml:space} else (),
    if ($element/@xml:lang) then attribute{'xml:lang'}{$element/@xml:lang} else ()
    (: all remaining attributes are saved as annotations :)
    ,
    (:and recurse through its element and text contents:)
    for $node in $element/node()
        return
            if ($node instance of element() and not($node/text()))
            (: if the node is an element which does not have a child text node, then recurse. :)
            then local:generate-text-layer($node, $target)
            else
                if ($node instance of element() and exists($node/text()))
                (: if the node is an element which has a child text node, then reconstruct it and get its text layer. :)
                then 
                    element {node-name($node)}
                    {if ($node/@xml:id) then attribute{'xml:id'}{$node/@xml:id} else (),
                    if ($node/@xml:base) then attribute{'xml:base'}{$node/@xml:base} else (),
                    if ($node/@xml:space) then attribute{'xml:space'}{$node/@xml:space} else (),
                    if ($node/@xml:lang) then attribute{'xml:lang'}{$node/@xml:lang} else ()
                    ,
                    local:separate-text-layers($node, $target)
                    }
                else 
                    if ($node instance of comment()) (: pass through comments. :)
                    then $node
                    else ()
    }
};

(:recurse through the document, extracting annotations when visiting elements with text nodes.
 : Only elements with text nodes can serve as basis for annotations – all other elements will be block-level and occur in both base and target version.:)
(:NB: this will not catch an element which could have had a text node, but which happens not to have, e.g. a <p> wholly filled up with a <hi>. :)
(:There are 1) elements that can only have other elements as child nodes; 
 : there are 2) elements that can have no child nodes; 
 : there are 3) elements that can have text nodes.:)
(: NB: We can define the elements that we are interested in as elements that can have text nodes, all of whose ancestors are element-only elements.:)
declare function local:generate-top-level-annotations-keyed-to-base-text($elements as element()*, $edition-layer-elements as xs:string+, $documentary-elements as xs:string+, $block-element-names as xs:string+) as element()* {
    for $element in $elements/element()
        return
            if ($element/text())
            then local:get-top-level-annotations-keyed-to-base-text($element, $edition-layer-elements, $documentary-elements)
            else local:generate-top-level-annotations-keyed-to-base-text($element, $edition-layer-elements, $documentary-elements, $block-element-names)
};

declare function local:prepare-annotations-for-output-to-file($element as element())
as element()
{
    element { node-name($element) } {
        $element/@*,
        for $child in $element/node()
        return
            if ($child instance of element(a8n:base-layer) or $child instance of element(a8n:admin) or $child instance
                of element(a8n:layer-offset-difference)) then
                ()
            else if ($child instance of element(a8n:authoritative-layer)) then
                $child/*
            else if ($child instance of text()) then
                $child
            else
                local:prepare-annotations-for-output-to-file($child)
    }
};

let $doc-title := 'sample_MTDP10363.xml'
let $doc := doc(concat('/db/test/in/', $doc-title))
let $doc-element := $doc/element()
let $doc-header := $doc-element/tei:teiHeader
let $doc-text := $doc-element/tei:text

let $admin-metadata :=
<admin>
	<creation>
		<user>{xmldb:get-current-user()}</user>
		<time>{current-dateTime()}</time>
		<note/>
	</creation>
	<review><user/><time/><note/></review>
	<imprimatur><user/><time/></imprimatur>
</admin>

let $edition-layer-elements := ('app', 'rdg', 'lem', 'choice', 'corr', 'sic', 'orig', 'reg', 'abbr', 'expan', 'ex', 'mod', 'subst', 'add', 'del')
let $documentary-elements := ('milestone', 'pb', 'lb', 'cb', 'hi', 'gap', 'damage', 'unclear', 'supplied', 'restore', 'space', 'handShift')
let $block-element-names := ('ab', 'body', 'castGroup', 'castItem', 'castList', 'div', 'front', 'head', 'l', 'lg', 'role', 'roleDesc', 'sp', 'speaker', 'stage', 'TEI', 'text', 'p', 'quote' )
(:TODO: the idea is that an element all of whose ancestors are element-only-elements is a block-level element, so this has to be refined in terms of $element-only-element-names; empty elements have been filtered away:)
let $element-only-element-names := ('TEI', 'abstract', 'additional', 'address', 'adminInfo', 'altGrp', 'altIdentifier', 'alternate', 'analytic', 'app', 'appInfo', 'application', 'arc', 'argument', 'attDef', 'attList', 'availability', 'back', 'biblFull', 'biblStruct', 'bicond', 'binding', 'bindingDesc', 'body', 'broadcast', 'cRefPattern', 'calendar', 'calendarDesc', 'castGroup', 'castList', 'category', 'certainty', 'char', 'charDecl', 'charProp', 'choice', 'cit', 'classDecl', 'classSpec', 'classes', 'climate', 'cond', 'constraintSpec', 'correction', 'correspAction', 'correspContext', 'correspDesc', 'custodialHist', 'datatype', 'decoDesc', 'dimensions', 'div', 'div1', 'div2', 'div3', 'div4', 'div5', 'div6', 'div7', 'divGen', 'docTitle', 'eLeaf', 'eTree', 'editionStmt', 'editorialDecl', 'elementSpec', 'encodingDesc', 'entry', 'epigraph', 'epilogue', 'equipment', 'event', 'exemplum', 'fDecl', 'fLib', 'facsimile', 'figure', 'fileDesc', 'floatingText', 'forest', 'front', 'fs', 'fsConstraints', 'fsDecl', 'fsdDecl', 'fvLib', 'gap', 'glyph', 'graph', 'graphic', 'group', 'handDesc', 'handNotes', 'history', 'hom', 'hyphenation', 'iNode', 'if', 'imprint', 'incident', 'index', 'interpGrp', 'interpretation', 'join', 'joinGrp', 'keywords', 'kinesic', 'langKnowledge', 'langUsage', 'layoutDesc', 'leaf', 'lg', 'linkGrp', 'list', 'listApp', 'listBibl', 'listChange', 'listEvent', 'listForest', 'listNym', 'listOrg', 'listPerson', 'listPlace', 'listPrefixDef', 'listRef', 'listRelation', 'listTranspose', 'listWit', 'location', 'locusGrp', 'macroSpec', 'media', 'metDecl', 'moduleRef', 'moduleSpec', 'monogr', 'msContents', 'msDesc', 'msIdentifier', 'msItem', 'msItemStruct', 'msPart', 'namespace', 'node', 'normalization', 'notatedMusic', 'notesStmt', 'nym', 'objectDesc', 'org', 'particDesc', 'performance', 'person', 'personGrp', 'physDesc', 'place', 'population', 'postscript', 'precision', 'prefixDef', 'profileDesc', 'projectDesc', 'prologue', 'publicationStmt', 'punctuation', 'quotation', 'rdgGrp', 'recordHist', 'recording', 'recordingStmt', 'refsDecl', 'relatedItem', 'relation', 'remarks', 'respStmt', 'respons', 'revisionDesc', 'root', 'row', 'samplingDecl', 'schemaSpec', 'scriptDesc', 'scriptStmt', 'seal', 'sealDesc', 'segmentation', 'sequence', 'seriesStmt', 'set', 'setting', 'settingDesc', 'sourceDesc', 'sourceDoc', 'sp', 'spGrp', 'space', 'spanGrp', 'specGrp', 'specList', 'state', 'stdVals', 'styleDefDecl', 'subst', 'substJoin', 'superEntry', 'supportDesc', 'surface', 'surfaceGrp', 'table', 'tagsDecl', 'taxonomy', 'teiCorpus', 'teiHeader', 'terrain', 'text', 'textClass', 'textDesc', 'timeline', 'titlePage', 'titleStmt', 'trait', 'transpose', 'tree', 'triangle', 'typeDesc', 'vAlt', 'vColl', 'vDefault', 'vLabel', 'vMerge', 'vNot', 'vRange', 'valItem', 'valList', 'vocal')

let $base-text := local:generate-text-layer($doc-text, 'base')
let $base-text := local:remove-inline-elements($base-text, $block-element-names)

let $authoritative-text := local:generate-text-layer($doc-text, 'authoritative')
let $authoritative-text := local:remove-inline-elements($authoritative-text, $block-element-names)


let $annotations-1 := local:generate-top-level-annotations-keyed-to-base-text($doc-text, $edition-layer-elements, $documentary-elements, $block-element-names)
let $annotations-2 := local:insert-authoritative-layer-in-top-level-annotations($annotations-1)
let $annotations-3 :=
    for $node in $annotations-2
        return local:whittle-down-annotations($node, $documentary-elements)

let $output-format := 'test'
(:let $output-format := 'file':)
let $annotations-4 :=
    if ($output-format eq 'test')
    then $annotations-3
    else local:prepare-annotations-for-output-to-file(<annotations>{$annotations-3}</annotations>)
        
return
    if ($output-format eq 'test')
    then
    <result>
        <base-text>{element {node-name($doc-element)}{$doc-element/@*}}{$doc-header}{element {node-name($doc-text)}{$doc-text/@*, $base-text}}</base-text>
        <authoritative-text>{element {node-name($doc-element)}{$doc-element/@*}}{$doc-header}{element {node-name($doc-text)}{$doc-text/@*, $authoritative-text}}</authoritative-text>
        <annotations-1>{$annotations-1}</annotations-1>
        <annotations-2>{$annotations-2}</annotations-2>
        <annotations-3>{$annotations-3}</annotations-3>
        <annotations-4>{$annotations-4}</annotations-4>
    </result>
    else
    for $annotation in $annotations-4/*
    return
        xmldb:store($out-collection,  concat($annotation/@xml:id, '.xml'), $annotation)