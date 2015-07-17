xquery version "3.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare boundary-space preserve;

declare variable $text-in-collection := '/db/apps/merula/mopane/';
declare variable $text-out-collection := '/db/apps/merula/data/';

(: Removes elements named :)
declare function local:remove-elements($nodes as node()*, $names-of-elements-to-remove as xs:anyAtomicType+)  as node()* {
    for $node in $nodes
    return
        if ($node instance of element())
        then
            if ((local-name($node) = $names-of-elements-to-remove))
            then ()
            else element {node-name($node)}
            {$node/@*, local:remove-elements($node/node(), $names-of-elements-to-remove)}
        else
            if ($node instance of document-node())
            then local:remove-elements($node/node(), $names-of-elements-to-remove)
            else $node
};

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

(: Extracts all inline elements from the text-block element and records their position in relation to the base text and target text, and extracts all attributes of the text-block element. The text-block elements are required to have an xml:id. :)
declare function local:get-top-level-annotations-keyed-to-base-text($text-block-element as element(), $editiorial-element-names as xs:string+, $documentary-element-names as xs:string+) {
    (:TODO: comments and PIs should also be handled as annotations:)
    for $element in $text-block-element/element()
        let $a8n-id := $element/parent::element()/@xml:id/string()
        let $base-text-before-element := string-join(local:separate-text-layers($element/preceding-sibling::node(), 'base-text'))
        let $base-text-before-text := string-join($element/preceding-sibling::text())
        let $base-text-marked-up-string := string-join(local:separate-text-layers($element, 'base-text'))
        let $base-text-position-start := string-length($base-text-before-element) + string-length($base-text-before-text)
        let $base-text-position-end := $base-text-position-start + string-length($base-text-marked-up-string)
        
        let $target-text-before-element := string-join(local:separate-text-layers($element/preceding-sibling::node(), 'target-text'))
        let $target-text-before-text := string-join($element/preceding-sibling::text()) (:NB: same as base:)
        let $target-text-marked-up-string := string-join(local:separate-text-layers($element, 'target-text'))
        let $target-text-position-start := string-length($target-text-before-element) + string-length($target-text-before-text)
        let $target-text-position-end := $target-text-position-start + string-length($target-text-marked-up-string)
        
        let $preceding-sibling-node := $element/preceding-sibling::node()[1]
        let $following-sibling-node := $element/following-sibling::node()[1]
        let $a8n-parent-element-name := local-name($element/parent::*)
        let $a8n-preceding-sibling-node :=
            if ($preceding-sibling-node instance of element())
            then (<a8n-node-type>element</a8n-node-type>, <a8n-node-name>{local-name($preceding-sibling-node)}</a8n-node-name>)
            else
                if ($preceding-sibling-node instance of text())
                then <a8n-node-type>text</a8n-node-type>
                else
                    if ($preceding-sibling-node instance of comment())
                    then <a8n-node-type>comment</a8n-node-type>
                    else
                        if ($preceding-sibling-node instance of processing-instruction())
                        then (<a8n-node-type>processing-instruction</a8n-node-type>, <a8n-node-name>{local-name($preceding-sibling-node)}</a8n-node-name>)
                        else ()
        let $a8n-following-sibling-node :=
            if ($following-sibling-node instance of element())
            then (<a8n-node-type>element</a8n-node-type>, <a8n-node-name>{local-name($following-sibling-node)}</a8n-node-name>)
            else
                if ($following-sibling-node instance of text())
                then <a8n-node-type>text</a8n-node-type>
                else
                    if ($following-sibling-node instance of comment())
                    then <a8n-node-type>comment</a8n-node-type>
                    else
                        if ($following-sibling-node instance of processing-instruction())
                        then (<a8n-node-type>processing-instruction</a8n-node-type>, <a8n-node-name>{local-name($following-sibling-node)}</a8n-node-name>)
                        else ()
        let $annotation-id := concat('uuid-', util:uuid())
        let $target :=
            if (local-name($element) = $editiorial-element-names)
            then
                <a8n-target>
                    <a8n-id>{$a8n-id}</a8n-id>
                    <a8n-offset>{$base-text-position-start + 1}</a8n-offset>
                    <a8n-range>{$base-text-position-end - $base-text-position-start}</a8n-range>
                </a8n-target>
            else
                <a8n-target>
                        <a8n-parent-element-name>{$a8n-parent-element-name}</a8n-parent-element-name>
                        <a8n-preceding-sibling-node>{$a8n-preceding-sibling-node}</a8n-preceding-sibling-node>
                        <a8n-following-sibling-node>{$a8n-following-sibling-node}</a8n-following-sibling-node>
                        <a8n-id>{$a8n-id}</a8n-id>
                        <a8n-offset>{
                            if (local-name($element) = $editiorial-element-names)
                            then $base-text-position-start + 1
                            else $target-text-position-start + 1
                        }</a8n-offset>
                        <a8n-range>{
                            if (local-name($element) = $editiorial-element-names)
                            then $base-text-position-end - $base-text-position-start
                            else $target-text-position-end - $target-text-position-start}</a8n-range>
                </a8n-target>
            return
                let $element-annotation-result :=
                    <a8n-annotation xml:id="{$annotation-id}">
                        {$target}
                        <a8n-body>{element {node-name($element)}{$element/@xml:id, $element/node()}}</a8n-body>
                        <a8n-admin/>
                    </a8n-annotation>
                let $attribute-annotation-result := local:make-attribute-annotations($element, $annotation-id)
            return 
                ($element-annotation-result, $attribute-annotation-result)
};

(: Creates annotations from the attributes of an element. :)
declare function local:make-attribute-annotations($element as element(), $parent-element-id as xs:string) as element()* {
    for $attribute in $element/(@* except @xml:id)
    return
        <a8n-annotation xml:id="{concat('uuid-', util:uuid())}">
            <a8n-target>
                <a8n-id>{$parent-element-id}</a8n-id>
            </a8n-target>
            <a8n-body>
                <a8n-attribute>
                    <a8n-name>{ name($attribute) }</a8n-name>
                    <a8n-value>{ $attribute/string() }</a8n-value>
                </a8n-attribute>
            </a8n-body>
            <a8n-admin/>
        </a8n-annotation>
};


(: Based on a list of TEI elements that alter the text, construct the altered (target) or the unaltered (base) text. This leaves non-edition inline elements in the text to be removed by local:remove-inline-elements(). :)
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
                    if ($target eq 'base-text') 
                    then ()
                    else $node
                
                case element(tei:rdg) return
                    if ($node/preceding-sibling::tei:lem)
                    then
                    (:if the app has a lem along with the rdg:)
                        if ($target eq 'base-text')
                        then 
                            if ($node[contains(@wit/string(), 'TS1')])
                            (:TODO: an approach using tokenize() should be used instead:)
                            then $node
                            else ()
                        (:if there is a lem, choose a rdg for the base text:)
                        else ()
                        (:disregard the rdg for the target text if there is a lem:)
                    else
                    (:if the app has no lem along with the rdg:)
                        if ($target eq 'base-text')
                        then 
                            if ($node[contains(@wit/string(), 'TS1')])
                            then $node
                            else ()
                            (:if there is no lem, choose a TS1 rdg for the base text if there is one:)
                        else
                            if ($node[contains(@wit/string(), 'TS2')])
                            then $node
                            else ()
                            (:if there is no lem, choose a TS2 rdg for the target text:)
                
                case element(tei:reg) return
                    if ($target eq 'base-text')
                    then () 
                    else $node
                case element(tei:corr) return
                    if ($target eq 'base-text') 
                    then () 
                    else $node
                case element(tei:expan) return
                    if ($target eq 'base-text') 
                    then () 
                    else $node
                case element(tei:orig) return
                    if ($target eq 'base-text') 
                    then $node
                    else ()
                case element(tei:sic) return
                    if ($target eq 'base-text') 
                    then $node
                    else ()
                case element(tei:abbr) return
                    if ($target eq 'base-text') 
                    then $node
                    else ()

                    default return local:separate-text-layers($node, $target)
};

(: This function removes inline elements from the result of generate-text-layer() :)
declare function local:remove-inline-elements($nodes as node()*, $text-block-element-names as xs:string+, $element-only-element-names as xs:string+) as node()* {
    for $node in $nodes/node()
    return
        if ($node instance of element())
        then
            if (local-name($node) = ($text-block-element-names, $element-only-element-names))
            then 
                element {node-name($node)}
                {$node/@*, local:remove-inline-elements($node, $text-block-element-names, $element-only-element-names)}
            else $node/text()
        else $node
};

(:This functions is fed annotations with empty elements and annotations with elements with element-only contents. In the case of empty elements, it return the empty element with its xml:id and peels off any attributes the element may have. In the case of elements with element-only contents, it returns the top element with its xml:id and recurses through its contents, generating annotatoin children from it and having the annotation children refer to the xml:id of their parent. :)
declare function local:handle-element-only-annotations($annotation as node(), $editiorial-element-names as xs:string+, $documentary-element-names as xs:string+) as item()* {
            let $parent-body-contents := $annotation//a8n-body/element() (: get the element below body.:)
            let $parent-attribute-annotations := local:make-attribute-annotations($parent-body-contents, $parent-body-contents/@xml:id/string()) (:peel off its attributes:)
            let $parent-admin-contents := $annotation//a8n-admin/element() (: get the elements below admin :)
            let $parent-id := $annotation/@xml:id/string() (: get the annotation's id :)
            let $parent-body-contents := element {node-name($parent-body-contents)}{$parent-body-contents/@xml:id}
            (:construct an empty element with its xml:id out of the element below body :)
            let $parent-annotation := local:remove-elements($annotation, 'a8n-body') (:remove the old body from the annotation:)
            let $parent-annotation := local:insert-elements($parent-annotation, <a8n-body>{$parent-body-contents}</a8n-body>, 'a8n-target', 'after')
            (:insert the new body into the empty top element :)
            return ($parent-annotation, $parent-attribute-annotations)
            ,
            (:this has taken the contents out of the annotation's parent element - now we will deal with the contents it had :)
            let $parent-id := $annotation/@xml:id/string() (: get the annotation id :)
            let $child-body-contents := $annotation//a8n-body/*/* (: get the contents of what is below the top element; there may be multiple elements here.:)
            for $element at $i in $child-body-contents
            (: return the new annotations, with the elements below the parent element of the old annotation split over as many annotations, recording their order (instead of their offset and range) and making them refer to the parent annotation:)
                let $child-attribute-annotations := local:make-attribute-annotations($element, $element/@xml:id/string())
                let $child-element-annotation :=
                    <a8n-annotation xml:id="{concat('uuid-', util:uuid())}">
                        <a8n-target>
                                <a8n-id>{$parent-id}</a8n-id>
                                <a8n-order>{$i}</a8n-order>
                        </a8n-target>
                        <a8n-body>{element {node-name($element)}{$element/@xml:id, $element/node()}}</a8n-body>
                        <a8n-admin/>
                    </a8n-annotation>
                    return
                        (
                        (: if the annotation body has no text node, it is an empty element, so let it pass through:)
                        if (not($child-element-annotation/aa8n-body//text()))
                        then $child-element-annotation 
                        else local:peel-off-annotations($child-element-annotation, $editiorial-element-names, $documentary-element-names)
                        ,
                        ($child-attribute-annotations)
                        )
};

(:An annotation with mixed contents should be split up into text annotations and element annotations, in the same manner that the top-level annotations were extracted from the input, except that no edition-layer-elements are relevant:)
declare function local:handle-mixed-content-annotations($annotation as node(), $editiorial-element-names as xs:string+, $documentary-element-names as xs:string+) as item()* {
            let $parent-body-contents := $annotation//a8n-body/* (:get element below body - this can ony be a single element:)
            let $parent-body-contents := element {node-name($parent-body-contents)}{
                for $attribute in $parent-body-contents/(@* except @xml:id)
                    return attribute {name($attribute)} {$attribute}} (:construct empty element with attributes - these will be peeled off later :)
            let $parent-annotation := local:remove-elements($annotation, 'a8n-body')(:remove the body,:)
            let $parent-annotation := local:insert-elements($parent-annotation, <a8n-body>{$parent-body-contents}</a8n-body>, 'a8n-target', 'after')(:and insert the new body:)
                return $parent-annotation
            ,
            let $child-body-contents := local:get-top-level-annotations-keyed-to-base-text($annotation//a8n-body/*, '', $documentary-element-names)
            let $parent-id := <a8n-id>{$annotation/@xml:id/string()}</a8n-id>
            for $child-body-content in $child-body-contents
                return
                    let $child-body-content := local:remove-elements($child-body-content, ('a8n-id', 'a8n-layer-range-difference'))
                    let $child-annotation := local:insert-elements($child-body-content, $parent-id, 'a8n-offset', 'before')
                        return
                            if (not($child-annotation//a8n-body//text()))
                            then $child-annotation
                            else local:peel-off-annotations($child-annotation, $editiorial-element-names, $documentary-element-names)
};

(: Removes one layer at a time from the upper-level annotations, reducing them, if neccesary, until they consist either of an empty element with an xml:id, or an element with a text node with an xml:id:)
declare function local:peel-off-annotations($annotation as node(), $editiorial-element-names as xs:string+, $documentary-element-names as xs:string+) as item()* {
            if (not($annotation//a8n-body/*/node()))
            (: if the body contents is an empty element, peel off any attributes it may have:)
            then local:handle-element-only-annotations($annotation, $editiorial-element-names, $documentary-element-names)
            else 
                if ($annotation//a8n-body/a8n-attribute)
                (: if it is an attribute annotation, pass it through. :)
                then $annotation
                else
                    if ($annotation/a8n-body/*/* and $annotation/a8n-body/*/text()[normalize-space(.) != ''])
                    (: if there is mixed contents, send it on and receive it back in reduced form:)
                    then local:handle-mixed-content-annotations($annotation, $editiorial-element-names, $documentary-element-names)
                    else 
                        if ($annotation/a8n-body/* and $annotation//a8n-body/*/text()[normalize-space(.) != ''])
                        (: if there is one level until the text node (but no mixed contents), that is, if we have an ordinary element with text contents,
                        pass it through. :)
                        then $annotation
                        else 
                            local:handle-element-only-annotations($annotation, $editiorial-element-names, $documentary-element-names)
                        (:if it is not an empty element, if it is not an attribute, and if it is not mixed contents, then it is a nested element node, so send it on to be (further) reduced :)
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
            (:NB: here the different kinds of elements should be referred to:)
            (: if the node is an element which does not have a child text node, then recurse. :)
            then local:generate-text-layer($node, $target)
            else
                if ($node instance of element() and exists($node/text()))
                (:NB: here the different kinds of elements should be referred to:)
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

(:recurse through the document, extracting annotations when visiting elements that can have text nodes.
Only elements with text nodes can serve as basis for annotations – all other elements will be block-level and these will occur identically in base and target version.:)
(:NB: be sure to catch an element which could have had a text node, but which happens not to have, e.g. a <p> wholly filled up with a <hi>. :)
(:There are 1) elements that can only have other elements as child nodes; 
 : there are 2) elements that can have no child nodes, only attributes; 
 : there are 3) elements that can have text nodes.:)
(: NB: We can define the elements that we are interested in as elements that can have text nodes, all of whose ancestors are element-only elements.:)
declare function local:generate-top-level-annotations-keyed-to-base-text($elements as element()*, $editiorial-element-names as xs:string+, $documentary-element-names as xs:string+, $text-block-element-names as xs:string+, $element-only-element-names as xs:string+) as element()* {
    for $element in $elements/element()
        return
        (: if the element is a block-level element that can hold text and if all its ancestors are element-only elements. :)
        if ($element/local-name() = $text-block-element-names and not($element/ancestor::*/local-name()[not(. = $element-only-element-names)]))
        (: then get its attributes and peel off its inline markup:)
        then (local:make-attribute-annotations($element, $element/@xml:id/string()), local:get-top-level-annotations-keyed-to-base-text($element, $editiorial-element-names, $documentary-element-names))
        (: otherwise get its attributes and descend one level:)
        else (local:make-attribute-annotations($element, $element/@xml:id/string()), local:generate-top-level-annotations-keyed-to-base-text($element, $editiorial-element-names, $documentary-element-names, $text-block-element-names, $element-only-element-names))
};

declare function local:prepare-annotations-for-output-to-doc($element as element()*)
as element()* {
    for $element in $element 
    return
    element { node-name($element) } {
        $element/@*,
        for $child in $element/node()
        return
            if ($child instance of element(a8n-base-layer) or $child instance of element(a8n-admin) or $child instance
                of element(a8n-layer-range-difference)) then
                ()
            else if ($child instance of element(a8n-target-layer)) then
                $child/*
            else if ($child instance of text()) then
                $child
            else
                local:prepare-annotations-for-output-to-doc($child)
    }
};

let $doc-id := 'sha-ham'
let $annotation-out-path := '/db/apps/merula/data/annotations'
let $annotation-out-collection-path := concat($annotation-out-path, "/", $doc-id)

let $doc-title := 'sample_MTDP10363.xml'
let $doc := doc(concat($text-in-collection, '/', $doc-title))
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

let $editiorial-element-names := ('app', 'rdg', 'lem', 'choice', 'corr', 'sic', 'orig', 'reg', 'abbr', 'expan', 'ex', 'mod', 'subst', 'add', 'del')
let $documentary-element-names := ('milestone', 'pb', 'lb', 'cb', 'hi', 'gap', 'damage', 'unclear', 'supplied', 'restore', 'space', 'handShift')
let $text-block-element-names := ('ab', 'castItem', 'l', 'role', 'roleDesc', 'speaker', 'stage', 'p', 'quote')
(:TODO: the idea is that an element that can hold text, all of whose ancestors are element-only-elements, is a block-level element, so use of $text-block-element-names has to be dropped in favour of using in terms of $element-only-element-names.:)
let $barren-element-names := ('cb', 'gb', 'lb', 'milestone', 'pb', 'ptr', 'oRef', 'pRef', 'move', 'catRef', 'refState', 'binary', 'default', 'fsdLink', 'iff', 'numeric', 'symbol', 'then', 'alt', 'anchor', 'link', 'when', 'pause', 'shift', 'attRef', 'classRef', 'elementRef', 'equiv', 'macroRef', 'specDesc', 'specGrpRef', 'textNode', 'lacunaEnd', 'lacunaStart', 'variantEncoding', 'witEnd', 'witStart', 'addSpan', 'damageSpan', 'delSpan', 'handShift', 'redo', 'undo', 'caesura')
let $element-only-element-names := ('TEI', 'abstract', 'additional', 'address', 'adminInfo', 'altGrp', 'altIdentifier', 'alternate', 'analytic', 'app', 'appInfo', 'application', 'arc', 'argument', 'attDef', 'attList', 'availability', 'back', 'biblFull', 'biblStruct', 'bicond', 'binding', 'bindingDesc', 'body', 'broadcast', 'cRefPattern', 'calendar', 'calendarDesc', 'castGroup', 'castList', 'category', 'certainty', 'char', 'charDecl', 'charProp', 'choice', 'cit', 'classDecl', 'classSpec', 'classes', 'climate', 'cond', 'constraintSpec', 'correction', 'correspAction', 'correspContext', 'correspDesc', 'custodialHist', 'datatype', 'decoDesc', 'dimensions', 'div', 'div1', 'div2', 'div3', 'div4', 'div5', 'div6', 'div7', 'divGen', 'docTitle', 'eLeaf', 'eTree', 'editionStmt', 'editorialDecl', 'elementSpec', 'encodingDesc', 'entry', 'epigraph', 'epilogue', 'equipment', 'event', 'exemplum', 'fDecl', 'fLib', 'facsimile', 'figure', 'fileDesc', 'floatingText', 'forest', 'front', 'fs', 'fsConstraints', 'fsDecl', 'fsdDecl', 'fvLib', 'gap', 'glyph', 'graph', 'graphic', 'group', 'handDesc', 'handNotes', 'history', 'hom', 'hyphenation', 'iNode', 'if', 'imprint', 'incident', 'index', 'interpGrp', 'interpretation', 'join', 'joinGrp', 'keywords', 'kinesic', 'langKnowledge', 'langUsage', 'layoutDesc', 'leaf', 'lg', 'linkGrp', 'list', 'listApp', 'listBibl', 'listChange', 'listEvent', 'listForest', 'listNym', 'listOrg', 'listPerson', 'listPlace', 'listPrefixDef', 'listRef', 'listRelation', 'listTranspose', 'listWit', 'location', 'locusGrp', 'macroSpec', 'media', 'metDecl', 'moduleRef', 'moduleSpec', 'monogr', 'msContents', 'msDesc', 'msIdentifier', 'msItem', 'msItemStruct', 'msPart', 'namespace', 'node', 'normalization', 'notatedMusic', 'notesStmt', 'nym', 'objectDesc', 'org', 'particDesc', 'performance', 'person', 'personGrp', 'physDesc', 'place', 'population', 'postscript', 'precision', 'prefixDef', 'profileDesc', 'projectDesc', 'prologue', 'publicationStmt', 'punctuation', 'quotation', 'rdgGrp', 'recordHist', 'recording', 'recordingStmt', 'refsDecl', 'relatedItem', 'relation', 'remarks', 'respStmt', 'respons', 'revisionDesc', 'root', 'row', 'samplingDecl', 'schemaSpec', 'scriptDesc', 'scriptStmt', 'seal', 'sealDesc', 'segmentation', 'sequence', 'seriesStmt', 'set', 'setting', 'settingDesc', 'sourceDesc', 'sourceDoc', 'sp', 'spGrp', 'space', 'spanGrp', 'specGrp', 'specList', 'state', 'stdVals', 'styleDefDecl', 'subst', 'substJoin', 'superEntry', 'supportDesc', 'surface', 'surfaceGrp', 'table', 'tagsDecl', 'taxonomy', 'teiCorpus', 'teiHeader', 'terrain', 'text', 'textClass', 'textDesc', 'timeline', 'titlePage', 'titleStmt', 'trait', 'transpose', 'tree', 'triangle', 'typeDesc', 'vAlt', 'vColl', 'vDefault', 'vLabel', 'vMerge', 'vNot', 'vRange', 'valItem', 'valList', 'vocal')

let $base-text := local:generate-text-layer($doc-text, 'base-text')
let $base-text := local:remove-inline-elements($base-text, $text-block-element-names, $element-only-element-names)

let $target-text := local:generate-text-layer($doc-text, 'target-text')
let $target-text := local:remove-inline-elements($target-text, $text-block-element-names, $element-only-element-names)

let $annotations-1 := local:generate-top-level-annotations-keyed-to-base-text($doc-text, $editiorial-element-names, $documentary-element-names, $text-block-element-names, $element-only-element-names)
let $annotations-2 :=
    for $node in $annotations-1
        return local:peel-off-annotations($node, $editiorial-element-names, $documentary-element-names)

let $output-format := 'exide'
let $output-format := 'doc'

let $annotations-3 := local:prepare-annotations-for-output-to-doc($annotations-2)
let $base-text := element {node-name($doc-element)}{$doc-element/@*, $doc-header, element {node-name($doc-text)}{$doc-text/@*, $base-text}}        

let $annotation-out-collection := 
    if (not(xmldb:collection-available($annotation-out-collection-path)) and $output-format eq 'doc')
    then xmldb:create-collection(xmldb:encode-uri($annotation-out-path), xmldb:encode-uri($doc-id))
    else ()

return
    if ($output-format eq 'exide')
    then
    <result>
        <base-text>{$base-text}</base-text>
        <target-text>{element {node-name($doc-element)}{$doc-element/@*, $doc-header, element {node-name($doc-text)}{$doc-text/@*, $target-text}}}</target-text>
        <annotations-1>{$annotations-1}</annotations-1>
        <annotations-2>{$annotations-2}</annotations-2>
        <annotations-3>{$annotations-3}</annotations-3>
    </result>
    else
    (for $annotation in $annotations-3
    let $annotation-home-name := $annotation//a8n-id
    let $annotation-home-path := concat($annotation-out-collection-path, "/", $annotation-home-name)
    let $annotation-home-collection := 
        if (not(xmldb:collection-available($annotation-home-path)))
        then xmldb:create-collection(xmldb:encode-uri($annotation-out-collection-path), xmldb:encode-uri($annotation-home-name))
        else ()
    return
        xmldb:store($annotation-home-path,  concat($annotation/@xml:id, '.xml'), $annotation)
    ,
        xmldb:store($text-out-collection, $doc-title, $base-text)
    )