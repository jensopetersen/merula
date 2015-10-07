xquery version "3.0";

module namespace il2so="http://exist-db.org/xquery/app/inline2standoff";

import module namespace so2il="http://exist-db.org/xquery/app/standoff2inline" at "../modules/standoff2inline.xql";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare boundary-space preserve;

declare variable $il2so:text-in-collection := '/db/apps/merula/mopane/';
declare variable $il2so:text-out-collection := '/db/apps/merula/data/';

declare function il2so:download-xml($node, $filename) { 
response:set-header("Content-Disposition", concat("attachment; 
filename=", $filename)), response:stream($node, 'indent=yes') 
};

(: Removes elements named :)
declare function il2so:remove-elements($nodes as node()*, $names-of-elements-to-remove as xs:anyAtomicType+)  as node()* {
    for $node in $nodes
    return
        if ($node instance of element())
        then
            if ((local-name($node) = $names-of-elements-to-remove))
            then ()
            else element {node-name($node)}
            {$node/@*, il2so:remove-elements($node/node(), $names-of-elements-to-remove)}
        else
            if ($node instance of document-node())
            then il2so:remove-elements($node/node(), $names-of-elements-to-remove)
            else $node
};

declare function il2so:generate-base-text($input as node()*, $wit as xs:string) as item()* {
    for $node in $input/node()
    return
        typeswitch($node)
            case element(tei:note) return
                ()
            case element(tei:lem) return
                if (tokenize($node/@wit/string(), " ") = $wit)
                then il2so:generate-base-text($node, $wit)
                else ()
            case element(tei:rdg) return
                if (tokenize($node/@wit/string(), " ") = $wit)
                then il2so:generate-base-text($node, $wit)
                else ()
            case element(tei:sic) return il2so:generate-base-text($node, $wit)
            case element(tei:corr) return ()
            case element(tei:abbr) return il2so:generate-base-text($node, $wit)
            case element(tei:expan) return ()
            case element(tei:orig) return il2so:generate-base-text($node, $wit)
            case element(tei:reg) return ()
            case text() return $node
            default return il2so:generate-base-text($node, $wit)
};

(: This function inserts elements supplied as $new-nodes at a certain position, determined by $element-names-to-check and $location, or removes the $element-names-to-check globally :)
declare function il2so:insert-elements($node as node(), $new-nodes as node()*, $element-names-to-check as xs:string+, $location as xs:string) {
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
                            il2so:insert-elements($child, $new-nodes, $element-names-to-check, $location) 
                }
            else $node
};

(: Extracts all inline elements from the text-block element and records their position in relation to the base text and target text, and extracts all attributes of the text-block element. The text-block elements are required to have an xml:id. All annotations directly or indirectly target the xml:ids of the text-block-elements - even though other elements may have xml:ids, these are not used, but their annotations refer to the text-block-element's xml:id with an offset and a range. :)
declare function il2so:get-inline-annotations-keyed-to-base-text($text-block-element as element(), $editorial-element-names as xs:string+, $documentary-element-names as xs:string+, $wit as xs:string?) {
    (:TODO: comments and PIs should also be handled as annotations:)
    for $element in $text-block-element/element()
        let $a8n-id := $element/parent::element()/@xml:id/string()
        
        (: Get the the text before the editorial markup in question, by constructing the base text version of it. :)
        let $base-text-before-element := string-join(il2so:generate-base-text(<base>{$element/preceding-sibling::node()}</base>, $wit))
        (: Add 1 to the length of this to get the markup offset. :)
        let $base-text-offset := string-length($base-text-before-element) + 1
        (: Get the base-text version of the editorial markup in question. :)
        let $base-text-marked-up-string := string-join(il2so:generate-base-text($element, $wit))
        (: The length of this is the markup range. :)
        let $base-text-range := string-length($base-text-marked-up-string)
        
        (: Get the the text before the feature markup in quetion, by constructing the target text version of it. Add 1 to get the offset. :)
        let $target-text-before-element := string-join(so2il:generate-target-text(<target>{$element/preceding-sibling::node()}</target>))
        (: Add 1 to the length of this to get the markup offset. :)
        let $target-text-offset := string-length($target-text-before-element) + 1
        (: Get the target-text version of the feature markup in question. :)
        let $target-text-marked-up-string := string-join(so2il:generate-target-text($element))
        (: The length of this is the markup range. :)
        let $target-text-range := string-length($target-text-marked-up-string)
        let $motivatedBy :=
            if (local-name($element) = $editorial-element-names)
            then 'editing'
            else 'describing'
        let $annotation-id := concat('uuid-', util:uuid())
        let $order := il2so:get-order($element)
        (: Whereas editorial annotations target the base text, all other annotations target the target text. Editorial annotations are surrounded by text nodes (possibly empty, if the beginning and end of a text block is referred to) and refer only to the text block xml:id and an offset and a range. Other annotations can have siblings that are not text nodes. The precise sibling nodes that a non-editorial annotation is positioned in relation to must be registered if the correct sequence of empty elements is to be maintained. :)
        let $target :=
            if (local-name($element) = $editorial-element-names)
            then
                <a8n-target>
                    <a8n-id>{$a8n-id}</a8n-id>
                    <a8n-offset>{$base-text-offset}</a8n-offset>
                    <a8n-range>{$base-text-range}</a8n-range>
                    <a8n-order>{$order}</a8n-order>
                    <a8n-exact>{string-join(il2so:generate-base-text(<base>{$element}</base>, $wit))}</a8n-exact>
                </a8n-target>
            else
                <a8n-target>
                        <a8n-id>{$a8n-id}</a8n-id>
                        <a8n-offset>{$target-text-offset}</a8n-offset>
                        <a8n-range>{$target-text-range}</a8n-range>
                        <a8n-order>{$order}</a8n-order>
                        <a8n-exact>{string-join(so2il:generate-target-text(<target>{$element}</target>))}</a8n-exact>
                </a8n-target>
            return
                let $element-annotation-result :=
                    <a8n-annotation motivatedBy="{$motivatedBy}" xml:id="{$annotation-id}">
                        {$target}
                        <a8n-body>{element {node-name($element)}{$element/@xml:id, 
                            if ($element/text() and not($element/element()) and not(local-name($element) = $editorial-element-names))
                            then ()
                            else $element/node()
                        }}</a8n-body>
                        <a8n-admin/>
                    </a8n-annotation>
                let $attribute-annotation-result := il2so:make-attribute-annotations($element, $motivatedBy, $annotation-id)
            return 
                ($element-annotation-result, $attribute-annotation-result)
};

(: Creates annotations from the attributes of an element. :)
declare function il2so:make-attribute-annotations($element as element(), $motivatedBy as xs:string, $parent-id as xs:string) as element()* {
    (: xml:id is not peeled off, since it is not open to editing. :)
    for $attribute in $element/(@* except (@xml:id, @motivatedBy))
    return
        <a8n-annotation motivatedBy="{$motivatedBy}" xml:id="{concat('uuid-', util:uuid())}">
            <a8n-target>
                <a8n-id>{$parent-id}</a8n-id>
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



(: This function removes inline elements from the result of generate-text-layer() :)
declare function il2so:remove-inline-elements($nodes as node()*, $text-block-element-names as xs:string+, $element-only-element-names as xs:string+) as node()* {
    for $node in $nodes/node()
    return
        if ($node instance of element())
        then
            if (local-name($node) = ($text-block-element-names, $element-only-element-names))
            then 
                element {node-name($node)}
                {$node/@*, il2so:remove-inline-elements($node, $text-block-element-names, $element-only-element-names)}
            else $node/text()
        else $node
};

(:This functions is fed annotations with empty elements and annotations with elements with element-only contents. In the case of empty elements, it returns the empty element with its xml:id (any attributes have already been peeled off). In the case of elements with element-only contents, it returns the top element with its xml:id and recurses through its contents, generating annotation children from it and having the annotation children refer to the xml:id of their parent's annotation. :)
declare function il2so:peel-off-element-only-annotations($annotation as node(), $editorial-element-names as xs:string+, $documentary-element-names as xs:string+, $wit as xs:string?) as item()* {
            let $parent-body-contents := $annotation/a8n-body/element() (: get the element below body.:)
            let $parent-body-contents := element {node-name($parent-body-contents)}{$parent-body-contents/@xml:id} (:construct an empty element with its xml:id out of the element below body :)
            let $parent-admin-contents := $annotation//a8n-admin/element() (: get the elements below admin :)
            let $parent-annotation := il2so:remove-elements($annotation, 'a8n-body') (:remove the old body from the annotation:)
            let $parent-annotation := il2so:insert-elements($parent-annotation, <a8n-body>{$parent-body-contents}</a8n-body>, 'a8n-target', 'after') (:insert the new body into the empty top element :)
            return 
                $parent-annotation
            ,
            (:the above has taken the contents out of the annotation's a8n-body element - now we will deal with its contents :)
            let $parent-motivatedBy := $annotation/@motivatedBy/string()
            let $parent-annotation-id := $annotation/@xml:id/string() (: get the parent annotation's id :)
            let $child-body-contents := $annotation/a8n-body/*/* (: get the contents of what is below the top element; there may be multiple elements here.:)
            return
                for $child-body-content at $i in $child-body-contents
            (: return the new annotations, with the elements below the parent element of the old annotation split over as many annotations, recording their order (instead of their offset and range) and making them refer to the parent annotation:)
                let $child-annotation-id := concat('uuid-', util:uuid())
                let $motivatedBy :=
                    if (local-name($child-body-content) = $editorial-element-names)
                    then 'editing'
                    else 'describing'
                let $child-attribute-annotations := il2so:make-attribute-annotations($child-body-content, $parent-motivatedBy, $child-annotation-id)
                let $child-element-annotation :=
                    <a8n-annotation motivatedBy="{$motivatedBy}" xml:id="{$child-annotation-id}">
                        <a8n-target>
                                <a8n-id>{$parent-annotation-id}</a8n-id>
                                <a8n-order>{$i}</a8n-order>
                        </a8n-target>
                        <a8n-body>{element {node-name($child-body-content)}{$child-body-content/@xml:id, $child-body-content/node()}}</a8n-body>
                        <a8n-admin/>
                    </a8n-annotation>
                    return
                        (
                        if (not($child-element-annotation/a8n-body/*/*))
                        then $child-element-annotation 
                        else il2so:peel-off-annotations($child-element-annotation, $editorial-element-names, $documentary-element-names, $wit)
                        ,
                        ($child-attribute-annotations)
                        )
};

(:NB: NOT CALLED:)
(:An annotation with mixed contents should be split up into text annotations and element annotations, in the same manner that the top-level inline annotations were extracted from the text blocks, except that no edition-layer-elements are relevant. :)
declare function il2so:handle-mixed-content-annotations($annotation as node(), $editorial-element-names as xs:string+, $documentary-element-names as xs:string+, $wit as xs:string?) as item()* {
            let $parent-body-contents := $annotation/a8n-body/* (:get element below body - this can ony be a single element:)
            let $parent-body-contents := element {node-name($parent-body-contents)}{
                for $attribute in $parent-body-contents/(@* except @xml:id)
                    return attribute {name($attribute)} {$attribute}} (:construct empty element with attributes - these will be peeled off later :)
            let $parent-annotation := il2so:remove-elements($annotation, 'a8n-body')(:remove the body,:)
            let $parent-annotation := il2so:insert-elements($parent-annotation, <a8n-body>{$parent-body-contents}</a8n-body>, 'a8n-target', 'after')(:and insert the new body:)
                return $parent-annotation
            ,
            let $child-body-contents := il2so:get-inline-annotations-keyed-to-base-text($annotation/a8n-body/*, '', $documentary-element-names, $wit)
            let $parent-id := <a8n-id>{$annotation/@xml:id/string()}</a8n-id>
            for $child-body-content in $child-body-contents
                return
                    let $child-body-content := il2so:remove-elements($child-body-content, ('a8n-id'))
                    let $child-annotation := il2so:insert-elements($child-body-content, $parent-id, 'a8n-offset', 'before')
                        return
                            if (not($child-annotation//a8n-body//text()))
                            then $child-annotation
                            else il2so:peel-off-annotations($child-annotation, $editorial-element-names, $documentary-element-names, $wit)
};

(: Removes one layer at a time from the upper-level annotations, reducing them, if neccesary, until they consist either of an empty element with an xml:id, or an element with a text node with an xml:id. Leave attributes on their elements. :)
declare function il2so:peel-off-annotations($annotation as node(), $editorial-element-names as xs:string+, $documentary-element-names as xs:string+, $wit as xs:string?) as item()* {
    if ($annotation/a8n-body/a8n-attribute)
        (: if it is an attribute annotation, pass it through, since it has nothing to be peeled off. :)
        then $annotation
        else
            if (not($annotation/a8n-body/*/text()))
            then
            il2so:peel-off-element-only-annotations($annotation, $editorial-element-names, $documentary-element-names, $wit)
            (: send it on to be (further) peeled off :)
            else $annotation
(:            else il2so:handle-mixed-content-annotations($annotation, $editorial-element-names, $documentary-element-names, $wit):)
};

declare function il2so:generate-text-layer($element as element(), $target as xs:string, $wit as xs:string?) as element() 
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
            then il2so:generate-text-layer($node, $target, $wit)
            else
                if ($node instance of element() and exists($node/text()))
                (:NB: here the different kinds of elements should be referred to instead of checking for actual occurrence of text node:)
                (: if the node is an element which has a child text node, then reconstruct it and get its text layer. :)
                then 
                    element {node-name($node)}
                    {if ($node/@xml:id) then attribute{'xml:id'}{$node/@xml:id} else (),
                    if ($node/@xml:base) then attribute{'xml:base'}{$node/@xml:base} else (),
                    if ($node/@xml:space) then attribute{'xml:space'}{$node/@xml:space} else (),
                    if ($node/@xml:lang) then attribute{'xml:lang'}{$node/@xml:lang} else ()
                    ,
                    if ($target eq 'base-text')
                    then 
                        il2so:generate-base-text($node, $wit)
                        else
                        so2il:generate-target-text($node)
                    }
                else 
                    if ($node instance of comment()) (: pass through comments. :)
                    then $node
                    else ()
    }
};

(:recurse through the document, extracting annotations when visiting elements that can have text nodes.
Only elements with text nodes can serve as basis for annotations (except barren elements) – all other elements will be block-level and these will be the same in the base and target texts. :)
(:NB: be sure to catch an element which could have had a text node, but which happens not to have, e.g. a <p> wholly filled up with a <hi>. :)
(:There are 
1) elements that can only have other elements as child nodes; 
2) elements that are barren , i.e. that can have no child nodes, (possibly) only attributes; 
3) elements that can have text nodes.:)
(: NB: We can define the elements that we are interested in as elements that can have text nodes, all of whose ancestors are element-only elements.:)
declare function il2so:generate-top-level-annotations-keyed-to-base-text($elements as element()*, $editorial-element-names as xs:string+, $documentary-element-names as xs:string+, $text-block-element-names as xs:string+, $element-only-element-names as xs:string+, $barren-element-names as xs:string+, $wit as xs:string?) as element()* {
    for $element in $elements/element()
        return
        (: if the element is a text block element and if all its ancestors are element-only elements, :)
        if ($element/local-name() = $text-block-element-names and not($element/ancestor::*/local-name()[not(. = $element-only-element-names)]))
        then
            (
            (: then get its attributes :)
            if ($element/(attribute() except @xml:id))
            then
                il2so:make-attribute-annotations($element, 'structuring', $element/@xml:id/string())
            else ()
            ,
            (: and process its inline markup :)
            il2so:get-inline-annotations-keyed-to-base-text($element, $editorial-element-names, $documentary-element-names, $wit)
            )
        (: otherwise just get its attributes and descend one level:)
        else
            (: if the element cannot have element or text children, e.g. a milestone element which is sibling to text block elements, :)
            if ($element/local-name() = $barren-element-names and not($element/ancestor::*/local-name()[not(. = $element-only-element-names)])) 
            then
                (: then construct an annotation for it, noting its order in relation to its text block element siblings. :)
                (: TODO: Think of a method for inlining this kind of annotation. :)
                let $annotation-id := concat('uuid-', util:uuid())
                let $order := il2so:get-order($element)
                return
                (
                <a8n-annotation motivatedBy="milestone" xml:id="{$annotation-id}">
                    <a8n-target>
                        <a8n-id>{$element/parent::element()/@xml:id/string()}</a8n-id>
                        <a8n-order>{$order}</a8n-order>
                    </a8n-target>
                    <a8n-body>{element {node-name($element)}{$element/@xml:id, $element/node()}}</a8n-body>
                    <a8n-admin/>
                </a8n-annotation>
                ,
                (: and get its attributes :)
                if ($element/(attribute() except @xml:id))
                then
                    il2so:make-attribute-annotations($element, 'milestone', $annotation-id)
                else ()
                )
            (: if the element is not a text block element and if it is not the case that all its ancestors are element-only elements, :)
            else
                (
                (: then get its attributes :)    
                if ($element/(attribute() except @xml:id))
                then il2so:make-attribute-annotations($element, 'structuring', $element/@xml:id/string())
                else ()
                ,
                (: and recurse. :)
                il2so:generate-top-level-annotations-keyed-to-base-text($element, $editorial-element-names, $documentary-element-names, $text-block-element-names, $element-only-element-names, $barren-element-names, $wit)
                )
};

(: Calculates how many preceding element nodes have to be traversed in order to reach a text node sibling of the context node or what number child of its parent the context node is. :)
declare function il2so:get-order($element as element()*)
as xs:integer
{
    if ($element/preceding-sibling::node()[1] instance of text() or $element/parent::element()/child::node()[1] is $element) 
        then 1
    else if ($element/preceding-sibling::node()[2] instance of text() or $element/parent::element()/child::node()[2] is $element) 
    then 2
    else if ($element/preceding-sibling::node()[3] instance of text() or $element/parent::element()/child::node()[3] is $element) 
    then 3
    else if ($element/preceding-sibling::node()[4] instance of text() or $element/parent::element()/child::node()[4] is $element) 
    then 4
    else if ($element/preceding-sibling::node()[5] instance of text() or $element/parent::element()/child::node()[5] is $element) 
    then 5
    else if ($element/preceding-sibling::node()[6] instance of text() or $element/parent::element()/child::node()[6] is $element) 
    then 6
    else 999
};




declare function il2so:prepare-annotations-for-output-to-doc($element as element()*)
as element()* {
    for $element in $element 
    return
    element { node-name($element) } {
        $element/@*,
        for $child in $element/node()
        return
            if ($child instance of element(a8n-admin) or $child instance of element(a8n-exact)) then
                ()
            else if ($child instance of text()) then
                $child
            else
                il2so:prepare-annotations-for-output-to-doc($child)
    }
};

declare function il2so:find-annotation-home($annotations as element()+, $a8n-id as xs:string?) {
        let $parent-annotation := 
            if ($annotations[@xml:id = $a8n-id][a8n-target/a8n-offset])
            then $annotations[@xml:id = $a8n-id]
            else 
                if ($annotations[a8n-body/*[@xml:id = $a8n-id]])
                then $annotations[a8n-body/*[@xml:id = $a8n-id]]
                else $annotations[@xml:id = $a8n-id]
        return
        if ($parent-annotation)
        then 
            let $home-id := $parent-annotation//a8n-id
            return
                il2so:find-annotation-home($annotations, $home-id)
        else $a8n-id
};
