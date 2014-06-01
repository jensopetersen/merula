xquery version "3.0";

module namespace tei2="http://exist-db.org/xquery/app/tei2html";

import module namespace config="http://exist-db.org/apps/shakes/config" at "config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace a8n="http://www.betterform.de/projects/mopane/annotation";

(:values for $action: 'store', 'display':)(:NB: not used yet:)
(:values for $base: 'stored', 'generated':)(:NB: not used yet:)
(:values used for $target-layer: 'base', 'feature', 'edition':) (:Should 'base' be moved to separate variable, target-text?:)
(:values used for $target-format: 'tei', 'html':)
declare function tei2:tei2html($nodes as node()*, $target-layer as xs:string, $target-format as xs:string) {
        
    (:Get the document's xml:id.:)
    (:Before recursion, $nodes is a single element.:) 
    let $doc-id := root($nodes)/*/@xml:id/string()
    
    (:Get all annotations for the document in question.:)
    (:NB: This is perhaps too much. One could collect annotations for each element being recursed instead. 
    One could also store annotations in collections created for each xml:id, in the hierarchy of their elements. 
    Would the frequence of the collection calls be worth it, compared to moving around all annotations for the document?:)
    let $annotations := collection(($config:a8ns) || "/" || $doc-id)/*
    
    return
        tei2:annotate-text($nodes, $annotations, $target-layer, $target-format)
};

declare function tei2:annotate-text($nodes as node()*, $annotations as element()*, $target-layer as xs:string, $target-format as xs:string) {
            
    (:Recurse though the document.:)
    let $node := tei2:tei2tei-recurser($nodes, $annotations, $target-layer, $target-format)
    
    (:Get the top-level edition annotations for the element in question, that is, 
    the edition annotations that connect to the base text through text ranges.:)
    let $top-level-a8ns := 
        if ($annotations)
        then tei2:get-a8ns($node, $annotations, 'edition')
        else ()
    
    (:Build up the top-level edition annotations, that is, 
    insert annotations that reference the top-level edition annotations recursively into the top-level edition annotations.:)
    let $built-up-a8ns := 
        if ($top-level-a8ns) 
        then tei2:build-up-annotations($top-level-a8ns, $annotations)
        else ()
    
    (:Collapse the built-up edition annotations, that is, prepare them for insertion into the base text
    by removing all elements except the contents of body and attaching attributes.:)
    let $collapsed-a8ns := 
        if ($built-up-a8ns) 
        then tei2:collapse-annotations($built-up-a8ns)
        else ()
    
    (:Insert the collapsed annotations into the base-text.:)
    let $text-with-merged-a8ns := 
        if ($collapsed-a8ns) 
        then tei2:merge-annotations($node, $collapsed-a8ns, 'edition', 'tei')
        else $node
    (:Result: base text with edition annotations inserted.:)
    (:TODO: Transform to show target text with edition annotations inserted; use this a basis for generating target text?:)
    
    (:On the basis of the inserted edition annotations, contruct the target text.:)
    (:TODO: Into the target text, spans identifying the edition annotations should be inserted, 
    in order to provide hooks to these annotations in the HTML. 
    Resurrect old code for layer-offset-difference and merge both edition and feature annotation with target text.:)  
    (:TODO: Make it possible for the whole text node to be wrapped up in an (inline) element.:)
    let $target-text := 
        if ($text-with-merged-a8ns/text())
        then tei2:tei2target($text-with-merged-a8ns, 'target')
        else $text-with-merged-a8ns
        
    (:Get the top-level feature annotations for the element in question, that is, 
    the feature annotations that connect to the target text though text ranges.:)
    let $top-level-a8ns := 
        if ($annotations)
        then tei2:get-a8ns($node, $annotations, 'feature')
        else ()
    
    (:Build up the top-level feature annotations, that is, 
    insert annotations that reference the top-level feature annotations recursively into the top-level feature annotations.:)
    let $built-up-a8ns := 
        if ($top-level-a8ns) 
        then tei2:build-up-annotations($top-level-a8ns, $annotations)
        else ()
    
    (:Collapse the built-up feature annotations, that is, prepare them for insertion into the target text
    by removing all elements except the contents of body.:) 
    let $collapsed-a8ns := 
        if ($built-up-a8ns) 
        then tei2:collapse-annotations($built-up-a8ns)
        else ()
    
    (:Insert the collapsed annotations into the target text, producing the marked-up TEI document.:)
    let $text-with-merged-a8ns := 
        if ($collapsed-a8ns) 
        then tei2:merge-annotations($target-text, $collapsed-a8ns, 'feature', $target-format)
        else $node
    
    (:Convert the TEI document to HTML: block-level elements become divs and inline element become spans.:)
    let $block-level-element-names := ('ab', 'body', 'castGroup', 'castItem', 'castList', 'div', 'front', 'head', 'l', 'lg', 'role', 'roleDesc', 'sp', 'speaker', 'stage', 'TEI', 'text', 'p', 'quote' )
    let $html := tei2:tei2div($text-with-merged-a8ns, $block-level-element-names)
    
    return
        $html
};

(: Based on a list of TEI elements that alter the text, 
construct the altered (target) or the unaltered (base) text :)
(:Only the value "base" is checked.:)
(:TODO: This function must in some way be included in the TEI header, 
or the choices must be expressed in a manner that can feed the function.:)
declare function tei2:separate-text-layers($input as node()*, $target-layer) as item()* {
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
                if ($target-layer eq 'base') 
                then () 
                else $node/string()
            
            case element(tei:rdg) return
                if (not($node/../tei:lem))
                then
                    if ($target-layer eq 'base')
                    then $node[contains(@wit/string(), 'TS1')] (:if there is no lem, choose a rdg for the base text:)
                    else
                        if ($target-layer ne 'base')
                        then $node[contains(@wit/string(), 'TS2')] (:if there is no lem, choose a rdg for the target text:)
                        else ()
                else
                    if ($target-layer eq 'base')
                    then $node[contains(@wit/string(), 'TS1')] (:if there is a lem, choose a rdg for the base text:)
                    else ()
            
            case element(tei:reg) return
                if ($target-layer eq 'base')
                then () 
                else $node/string()
            case element(tei:corr) return
                if ($target-layer eq 'base') 
                then () 
                else $node/string()
            case element(tei:expanded) return
                if ($target-layer eq 'base') 
                then () 
                else $node/string()
            case element(tei:orig) return
                if ($target-layer eq 'base') 
                then $node/string()
                else ()
            case element(tei:sic) return
                if ($target-layer eq 'base') 
                then $node/string()
                else ()
            case element(tei:abbr) return
                if ($target-layer eq 'base') 
                then $node/string()
                else ()

                default return tei2:separate-text-layers($node, $target-layer)
};

declare function tei2:tei2target($node as node()*, $target-layer as xs:string) {
        (:If the element has a text node, separate the text node.:)
        (:TODO: Make it possible for the whole text node to be wrapped up in an (inline) element.:)
        element {node-name($node)}{$node/@*,tei2:separate-text-layers($node, $target-layer)}
        
};

(:Convert TEI block-level elements into divs and inline elements into spans.:)
(:The usual way of converting TEI into "quasi-semantic" HTML is avoided.:)
declare function tei2:tei2div($node as node(), $block-level-element-names as xs:string+) {
    element {if (local-name($node) = $block-level-element-names) then 'div' else 'span'}
        {$node/@*, attribute {'class'}{local-name($node)}, attribute {'title'}{local-name($node)}
        , 
        for $child in $node/node()
        return 
            if ($child instance of element() and not($child/@class)) (:NB: Check! Class attributes come from above in the same function.:)
            then tei2:tei2div($child, $block-level-element-names)
            else $child
        }
};

declare function tei2:tei2tei-recurser($node as node(), $annotations as element()*, $target-layer as xs:string, $target-format as xs:string) {
    element {node-name($node)}
        {$node/@*
        , 
        for $child in $node/node()
        return
            if ($child instance of element())
            then tei2:annotate-text($child, $annotations, $target-layer, $target-format)
            else $child
        }
};

(:Among the annotations to the whole document, retrieve the annotations belonging to a particular element.:)
(:The only $target-layer value that is checked is 'edition'.:)
declare function tei2:get-a8ns($element as element(), $annotations as element()*, $target-layer as xs:string) {
    let $element-id := $element/@xml:id/string()
    let $top-level-edition-a8ns := $annotations[a8n:target/@type eq 'range'][a8n:target/@layer eq $target-layer][a8n:target/a8n:id eq $element-id]
    return 
        $top-level-edition-a8ns 
};

(:This function takes a sequence of top-level text-critical annotations, 
i.e annotations of @type 'range' and @layer 'edition', 
and inserts as children all annotations that refer to them through their @xml:id, recursively:)
declare function tei2:build-up-annotations($top-level-critical-annotations as element()*, $annotations as element()*) as element()* {
    for $annotation in $top-level-critical-annotations
    return
        tei2:build-up-annotation($annotation, $annotations)
};

declare function tei2:build-up-annotation($annotation as element(), $annotations as element()*) as element()* {
        let $annotation-id := $annotation/@xml:id/string()
        let $annotation-element-name := local-name($annotation//a8n:body/*)
        let $children := $annotations[a8n:target/a8n:id eq $annotation-id]
        let $children :=
            tei2:build-up-annotations($children, $annotations)
        return 
            local:insert-elements($annotation, $children, $annotation-element-name,  'first-child')            
};

(:Recurser for tei2:collapse-annotation().:)
(:TODO: Clear up why tei2:collapse-annotation() has to be run three times.:) 
declare function tei2:collapse-annotations($built-up-critical-annotations as element()*) {
    for $annotation in $built-up-critical-annotations
    return 
        tei2:collapse-annotation(tei2:collapse-annotation(tei2:collapse-annotation($annotation, 'annotation'), 'body'), 'base-layer')
        (:NB: 'base-layer' does not appear to be used.:)
};

(: This function takes a built-up annotation and 
1) attaches attributes, stored as grandchildren,
2) collapses it, i.e. removes levels from the hierarchy by substituting elements with their children, 
3) removes unneeded elements, and 
4) takes the string values of terminal text-critical elements that have child feature annotations. :)
declare function tei2:collapse-annotation($element as element(), $strip as xs:string+) as element() {
    element {node-name($element)}
    {$element/@*, 
        if ($element/*/*/a8n:attribute)
        then 
            for $attribute in $element/*/*/a8n:attribute
            return
                let $attribute-name := $attribute/a8n:name/string()
                let $attribute-value := $attribute/a8n:value/string()
                return
                    attribute {$attribute-name} {$attribute-value}
        else ()
        ,
        for $child in $element/node()
        return
            (:If the child is on the list of elements to be stripped, just bypass it and substitute its children.:)
            if ($child instance of element() and local-name($child) = $strip)
            then 
                for $child in $child/*
                return 
                    tei2:collapse-annotation(($child), $strip)
            else
                if ($child instance of element() and local-name($child) = ('attribute', 'layer-offset-difference', 'authoritative-layer')) (:we have no need for these two elements - actually, they have been removed, but should they be introduced again?:)
                then ()
                else
                    (:skip the attribute attached above:)
                    if ($child instance of element() and local-name($child) = 'target' and local-name($child/parent::element()) ne 'annotation') (:remove all target elements that are not at the base level:)
                    then ()
                    else
                        if ($child instance of element() and local-name($child/..) = ('lem', 'rdg', 'sic', 'reg') ) (:take string value of elements that are below terminal elements concerned with edition:)
                        then string-join($child//text(), ' ') (:NB: This is a hack (@token should be used) but in real life text-critical annotations will not have sibling children with text nodes, so this is only relevant to round-tripping with annotations that mix text-critical and feature annotations.:)
                        else
                            if ($child instance of text())
                            then $child
                            else tei2:collapse-annotation($child, $strip)
      }
};

(:This function merges the collapsed annotations with the base or target text. 
A sequence of slots (<segment/>), double the number of annotations plus 1, are created; 
annotations are filled into the even slots, whereas the text, 
with ranges calculated from the previous and following annotations, 
are filled into the uneven slots. Uneven slots with empty strings can occur, 
but even slots all have annotations (though they may consist of empty elements).:)
(:TODO: check annotations for superimposition, containment, overlap.:)
declare function tei2:merge-annotations($base-text as element(), $annotations as element()*, $target-layer as xs:string, $target-format as xs:string) as node()+ {
    let $segment-count := (count($annotations) * 2) + 1
    let $segments :=
        for $segment at $i in 1 to $segment-count
        return
            <segment>{attribute n {$i}}</segment>
    let $segments := 
            for $segment in $segments
            return
                if (number($segment/@n) mod 2 eq 0) (:An annotation is being processed.:)
                then
                    let $annotation-n := $segment/@n/number() div 2
                    let $annotation := $annotations[$annotation-n]
                    let $annotation-start := number($annotation//a8n:start)
                    let $annotation-offset := number($annotation//a8n:offset)
                    let $annotation := 
                        (:Add the @xml:id of the annotation, making retrieval possible.:)
                        if ($target-layer eq 'feature')
                            then
                                let $annotation-body-child := $annotation/(* except a8n:target)
                                let $annotation-body-child-name := node-name($annotation-body-child) 
                                let $annotated-string := substring($base-text, $annotation-start, $annotation-offset)
                                return
                                    element {$annotation-body-child-name}
                                    {
                                    $annotation-body-child/@*
                                    ,
                                    attribute xml:id {$annotation/@xml:id/string()}
                                    ,
                                    $annotated-string}
                        (:If the edition layer is to be output, take the element from the built-up annotation.:)
                        (:TODO: It should also be possible to output the edition layer as HTML.:)
                        else $annotation/(* except a8n:target)
                    return
                        local:insert-elements($segment, $annotation, 'segment', 'first-child')
                (:A text node is being processed.:)
                else
                    <segment n="{$segment/@n/string()}">
                        {
                        let $segment-n := number($segment/@n)
                        let $previous-annotation-n := ($segment-n - 1) div 2
                        let $following-annotation-n := ($segment-n + 1) div 2
                        let $start := 
                            if ($segment-n eq $segment-count) (:if it is the last text node:)
                            then $annotations[$previous-annotation-n]/a8n:target/a8n:start/number() + $annotations[$previous-annotation-n]/a8n:target/a8n:offset/number()
                            (:the start position is the length of of the base text minus the end position of the previous annotation plus 1:)
                            else
                                if (number($segment/@n) eq 1) (:if it is the first text node:)
                                then 1 (:start with position 1:)
                                else $annotations[$previous-annotation-n]/a8n:target/a8n:start/number() + $annotations[$previous-annotation-n]/a8n:target/a8n:offset/number()
                                (:if it is not the first or last text node, 
                                start with the position of the previous annotation plus its offset plus 1:)
                        let $offset := 
                            if ($segment-n eq count($segments))  (:if it is the last text node:)
                            then string-length($base-text) - ($annotations[$previous-annotation-n]/a8n:target/a8n:start/number() + $annotations[$previous-annotation-n]/a8n:target/a8n:offset/number()) + 1
                            (:if it is the last text node, then the offset is the length of the base text minus the end position of the last annotation plus 1:)
                            else
                                if ($segment-n eq 1) (:if it is the first text node:)
                                then $annotations[$following-annotation-n]/a8n:target/a8n:start/number() - 1
                                (:if it is the first text node, the the offset is the start position of the following annotation minus 1:)
                                else $annotations[$following-annotation-n]/a8n:target/a8n:start/number() - ($annotations[$previous-annotation-n]/a8n:target/a8n:start/number() + $annotations[$previous-annotation-n]/a8n:target/a8n:offset/number())
                                (:if it is not the first or the last text node, then the offset is the start position of the following annotation minus the end position of the previous annotation :)
                        return
                            if (number($start) and number($offset))
                            then substring($base-text, $start, $offset)
                            else ''
                        
                        }
                    </segment>
    let $segments :=
        for $segment in $segments
        return
            if ($segment/@n mod 2 eq 0)
            then $segment/*
            else $segment/string()
    return 
        element {node-name($base-text)}{$base-text/@*, $segments}
};

(: This function inserts elements supplied as $new-nodes at a certain position, 
determined by $element-names-to-check and $location, 
or removes the $element-names-to-check globally :)
(:NB: Unused portions of function are commented out.:)
declare function local:insert-elements($node as node(), $new-nodes as node()*, $element-names-to-check as xs:string+, $location as xs:string) {
        if ($node instance of element() and local-name($node) = $element-names-to-check)
        then
            (:if ($location eq 'before')
            then ($new-nodes, $node) 
            else 
                if ($location eq 'after')
                then ($node, $new-nodes)
                else:)
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
                    (:else
                        if ($location eq 'last-child')
                        then element {node-name($node)}
                            {
                                $node/@*
                                ,
                                for $child in $node/node()
                                return $child 
                                ,
                                $new-nodes
                            }:)
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