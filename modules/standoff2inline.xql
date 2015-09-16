xquery version "3.0";

module namespace so2il="http://exist-db.org/xquery/app/standoff2inline";

import module namespace config="http://exist-db.org/apps/merula/config" at "config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

(: TODO :)
(:Every time an edition annotation is made, the range difference in relation to any previous annotation should be calculated and time stamped. More than one difference will then be stored in the annotation, the total difference being the sum of all differences. Each edition and feature annotation referencing a range that is subsequent in the text stream to the new annotation should then have the new range difference inserted into their annotation with the same time stamp. We have a 50 characters long text. 40-45 is a <name>. An editorial annotation expands characters 30-35 to 10 characters. This means that the <name> moves 5 characters to the right. If the editorial annotation concerned 46-50, there would be no consequences. If it concerned 40-45, human intervention would be required.:)

(:We have to find a way to allow multiple editorial targets, not just the base text and one target text. This also means that each feature annotation must be keyed to one or more targets.:)

(:values for $action: 'store', 'display':)(:NB: not used yet:)
(:values for $base: 'stored', 'generated':)(:NB: not used yet:)
(:values used for $target-format: 'tei', 'html':)
declare function so2il:standoff2inline($nodes as node()*, $editiorial-element-names as xs:string+, $target-format as xs:string) {
        
    (:Get the document's xml:id.:)
    let $doc-id := root($nodes)/*/@xml:id/string()
    
    return so2il:annotate-text($nodes, $doc-id, $editiorial-element-names, $target-format)
};

declare function so2il:annotate-text($nodes as node()*, $doc-id as xs:string, $editiorial-element-names as xs:string+, $target-format as xs:string) {

    (:Recurse though the document.:)
(:    let $log := util:log("DEBUG", ("##$nodes): ", $nodes)):)
    let $node := so2il:standoff2inline-recurser($nodes, $doc-id, $editiorial-element-names, $target-format)
(:    let $log := util:log("DEBUG", ("##$node): ", $node)):)
    let $doc-id := root($nodes)/*/@xml:id/string()
    (:Get all annotations for the block-level element in question. At first, only the top-level annotations are needed, but when the annotations are later built up, all annotations need to be referenced.:)
    let $annotations := collection(($config:a8ns) || "/" || $doc-id || "/" || $node/@xml:id)/*
    (:Get all top-level edition annotations for the element in question, that is, all annotations that target its id and belong to the 'edition' layer.:)
    let $top-level-edition-a8ns := 
        if ($annotations)
        then $annotations[a8n-target/a8n-offset][a8n-body/*/local-name() = $editiorial-element-names][a8n-target/a8n-id eq $node/@xml:id]
        else ()
(:    let $log := util:log("DEBUG", ("##$top-level-edition-a8ns): ", $top-level-edition-a8ns)):)

    (:Build up the top-level edition annotations, that is, 
    insert annotations that reference the top-level edition annotations, recursing until the whole annotation is assembled.:)
    let $built-up-edition-a8ns := 
        if ($top-level-edition-a8ns) 
        then so2il:build-up-annotations($top-level-edition-a8ns, $annotations)
        else ()
(:    let $log := util:log("DEBUG", ("##$built-up-edition-a8ns): ", $built-up-edition-a8ns)):)
    
    (:Collapse the built-up edition annotations, that is, prepare them for insertion into the base text
    by removing all elements except the contents of body and attaching attributes.:)
    let $collapsed-edition-a8ns := 
        if ($built-up-edition-a8ns) 
        then so2il:collapse-annotations($built-up-edition-a8ns)
        else ()
(:    let $log := util:log("DEBUG", ("##$collapsed-edition-a8ns): ", $collapsed-edition-a8ns)):)
    let $collapsed-edition-a8ns := 
        for $collapsed-edition-a8n in $collapsed-edition-a8ns
        order by number($collapsed-edition-a8n//a8n-offset) ascending, number($collapsed-edition-a8n//a8n-range) descending
        return $collapsed-edition-a8n
(:    let $log := util:log("DEBUG", ("##$collapsed-edition-a8ns): ", $collapsed-edition-a8ns)):)
    
    (:Insert the collapsed annotations into the base-text.:)
    let $text-with-merged-edition-a8ns := 
        if ($collapsed-edition-a8ns) 
        then so2il:merge-annotations-with-text($node, $collapsed-edition-a8ns, 'edition', 'tei')
        else $node
    (:Result: base text with edition annotations inserted.:)
    (:TODO: Transform to show the target text with edition annotations inserted; use this a basis for generating target text?:)
(:    let $log := util:log("DEBUG", ("##$text-with-merged-edition-a8ns): ", $text-with-merged-edition-a8ns)):)
    
    (:On the basis of the inserted edition annotations, contruct the target text.:)
    (:TODO: Into the $text-with-merged-edition-a8ns, spans identifying the edition annotations should be inserted, 
    in order to provide hooks to these annotations in the HTML. 
    Resurrect mopane code for layer-range-difference and merge both edition and feature annotation with target text.:)  
    (:TODO: Make it possible for the whole text node to be wrapped up in an (inline) element.:)
    let $target-text := 
        if ($text-with-merged-edition-a8ns/text())
        then so2il:tei2target($text-with-merged-edition-a8ns, 'target-text', $wit)
        else $text-with-merged-edition-a8ns
(:    let $log := util:log("DEBUG", ("##$target-text): ", $target-text)):)

    (:Get the top-level feature annotations for the element in question, that is, 
    the feature annotations that connect to the target text though text ranges.:)
    let $top-level-feature-a8ns := 
        if ($annotations)
        then $annotations[a8n-target/a8n-offset][not(a8n-body/*/local-name() = ($editiorial-element-names))][a8n-target/a8n-id eq $node/@xml:id]
        else ()
(:    let $log := util:log("DEBUG", ("##$top-level-feature-a8ns): ", $top-level-feature-a8ns)):)
    
    (:Build up the top-level feature annotations, that is, 
    insert annotations that reference the top-level feature annotations recursively into the top-level feature annotations.:)
    let $built-up-feature-a8ns := 
        if ($top-level-feature-a8ns) 
        then so2il:build-up-annotations($top-level-feature-a8ns, $annotations)
        else ()
(:    let $log := util:log("DEBUG", ("##$built-up-feature-a8ns): ", $built-up-feature-a8ns)):)
    
    (:Collapse the built-up feature annotations, that is, prepare them for insertion into the target text
    by removing all elements except the contents of body.:) 
    let $collapsed-feature-a8ns := 
        if ($built-up-feature-a8ns) 
        then so2il:collapse-annotations($built-up-feature-a8ns)
        else ()
(:    let $log := util:log("DEBUG", ("##$collapsed-feature-a8ns): ", $collapsed-feature-a8ns)):)
    let $collapsed-feature-a8ns := 
        for $collapsed-feature-a8n in $collapsed-feature-a8ns
        order by number($collapsed-feature-a8n//a8n-offset) ascending, number($collapsed-feature-a8n//a8n-range) descending
        return $collapsed-feature-a8n
(:    let $log := util:log("DEBUG", ("##$collapsed-feature-a8ns): ", $collapsed-feature-a8ns)):)
    
    (:Insert the collapsed annotations into the target text, producing a marked-up TEI document.:)
    let $text-with-merged-feature-a8ns := 
        if ($collapsed-feature-a8ns) 
        then so2il:merge-annotations-with-text($target-text, $collapsed-feature-a8ns, 'feature', $target-format)
        else $node
(:    let $log := util:log("DEBUG", ("##$text-with-merged-feature-a8ns): ", $text-with-merged-feature-a8ns)):)
    
    (:Convert the TEI document to HTML: block-level elements become divs and inline element become spans.:)
    let $block-element-names := ('ab', 'castItem', 'l', 'role', 'roleDesc', 'speaker', 'stage', 'p', 'quote')
    let $element-only-element-names := ('TEI', 'abstract', 'additional', 'address', 'adminInfo', 'altGrp', 'altIdentifier', 'alternate', 'analytic', 'app', 'appInfo', 'application', 'arc', 'argument', 'attDef', 'attList', 'availability', 'back', 'biblFull', 'biblStruct', 'bicond', 'binding', 'bindingDesc', 'body', 'broadcast', 'cRefPattern', 'calendar', 'calendarDesc', 'castGroup', 'castList', 'category', 'certainty', 'char', 'charDecl', 'charProp', 'choice', 'cit', 'classDecl', 'classSpec', 'classes', 'climate', 'cond', 'constraintSpec', 'correction', 'correspAction', 'correspContext', 'correspDesc', 'custodialHist', 'datatype', 'decoDesc', 'dimensions', 'div', 'div1', 'div2', 'div3', 'div4', 'div5', 'div6', 'div7', 'divGen', 'docTitle', 'eLeaf', 'eTree', 'editionStmt', 'editorialDecl', 'elementSpec', 'encodingDesc', 'entry', 'epigraph', 'epilogue', 'equipment', 'event', 'exemplum', 'fDecl', 'fLib', 'facsimile', 'figure', 'fileDesc', 'floatingText', 'forest', 'front', 'fs', 'fsConstraints', 'fsDecl', 'fsdDecl', 'fvLib', 'gap', 'glyph', 'graph', 'graphic', 'group', 'handDesc', 'handNotes', 'history', 'hom', 'hyphenation', 'iNode', 'if', 'imprint', 'incident', 'index', 'interpGrp', 'interpretation', 'join', 'joinGrp', 'keywords', 'kinesic', 'langKnowledge', 'langUsage', 'layoutDesc', 'leaf', 'lg', 'linkGrp', 'list', 'listApp', 'listBibl', 'listChange', 'listEvent', 'listForest', 'listNym', 'listOrg', 'listPerson', 'listPlace', 'listPrefixDef', 'listRef', 'listRelation', 'listTranspose', 'listWit', 'location', 'locusGrp', 'macroSpec', 'media', 'metDecl', 'moduleRef', 'moduleSpec', 'monogr', 'msContents', 'msDesc', 'msIdentifier', 'msItem', 'msItemStruct', 'msPart', 'namespace', 'node', 'normalization', 'notatedMusic', 'notesStmt', 'nym', 'objectDesc', 'org', 'particDesc', 'performance', 'person', 'personGrp', 'physDesc', 'place', 'population', 'postscript', 'precision', 'prefixDef', 'profileDesc', 'projectDesc', 'prologue', 'publicationStmt', 'punctuation', 'quotation', 'rdgGrp', 'recordHist', 'recording', 'recordingStmt', 'refsDecl', 'relatedItem', 'relation', 'remarks', 'respStmt', 'respons', 'revisionDesc', 'root', 'row', 'samplingDecl', 'schemaSpec', 'scriptDesc', 'scriptStmt', 'seal', 'sealDesc', 'segmentation', 'sequence', 'seriesStmt', 'set', 'setting', 'settingDesc', 'sourceDesc', 'sourceDoc', 'sp', 'spGrp', 'space', 'spanGrp', 'specGrp', 'specList', 'state', 'stdVals', 'styleDefDecl', 'subst', 'substJoin', 'superEntry', 'supportDesc', 'surface', 'surfaceGrp', 'table', 'tagsDecl', 'taxonomy', 'teiCorpus', 'teiHeader', 'terrain', 'text', 'textClass', 'textDesc', 'timeline', 'titlePage', 'titleStmt', 'trait', 'transpose', 'tree', 'triangle', 'typeDesc', 'vAlt', 'vColl', 'vDefault', 'vLabel', 'vMerge', 'vNot', 'vRange', 'valItem', 'valList', 'vocal')

    let $html := so2il:tei2html($text-with-merged-feature-a8ns, $block-element-names, $element-only-element-names)
(:    let $log := util:log("DEBUG", ("##$html): ", $html)):)
    
    return
        $html
};

(: Based on a list of TEI elements that alter the text, 
construct the altered (target) or the unaltered (base-text) text :)
(:Only the value "base" is checked.:)
(:TODO: This function must in some way be included in the TEI header, 
or the choices must be expressed in a manner that can feed the function.:)
declare function so2il:separate-text-layers($input as node()*, $target as xs:string, $wit as xs:string?) as item()* {
        for $node in $input/node()
        return
            typeswitch($node)
                
                case element(tei:note) return
                    ()
                    (:NB: it is not clear what to do with "original annotations", e.g. notes in the original. Probably they should be collected on the same level as "edition" and "feature" (along with other instances of "misplaced text", such as figure captions, which occur in the text stream, but should occur outside of it.)
                    Here we strip out all notes from the text itself and put them into the annotations.:)
                
                case element(tei:lem) return
                    if ($target eq 'base-text') 
                    then 
                        if ($node[tokenize(@wit/string(), " ") = $wit])
                        then so2il:separate-text-layers($node, $target, $wit)
                        else ()
                    else $node
                
                case element(tei:rdg) return
                    if ($target eq 'base-text')
                    then 
                        if ($node[tokenize(@wit/string(), " ") = $wit])
                        then so2il:separate-text-layers($node, $target, $wit)
                        else ()
                    else ()

                
                case element(tei:reg) return
                    if ($target eq 'base-text')
                    then () 
                    else so2il:separate-text-layers($node, $target, $wit)
                case element(tei:corr) return
                    if ($target eq 'base-text') 
                    then () 
                    else so2il:separate-text-layers($node, $target, $wit)
                case element(tei:expan) return
                    if ($target eq 'base-text') 
                    then () 
                    else so2il:separate-text-layers($node, $target, $wit)
                case element(tei:orig) return
                    if ($target eq 'base-text') 
                    then so2il:separate-text-layers($node, $target, $wit)
                    else ()
                case element(tei:sic) return
                    if ($target eq 'base-text') 
                    then so2il:separate-text-layers($node, $target, $wit)
                    else ()
                case element(tei:abbr) return
                    if ($target eq 'base-text') 
                    then so2il:separate-text-layers($node, $target, $wit)
                    else ()
                case text() return
                    $node
                default return so2il:separate-text-layers($node, $target, $wit)
};

declare function so2il:tei2target($node as node()*, $target-layer as xs:string, $wit as xs:string?) {
        (:If the element has a text node, separate the text node.:)
        (:TODO: Make it possible for the whole text node to be wrapped up in an (inline) element.:)
        element {node-name($node)}{$node/@*,so2il:separate-text-layers($node, $target-layer, $wit)}
        
};

(:Convert TEI block-level elements into divs and inline elements into spans.:)
(:For reasons of simplicity, te usual way of converting TEI into "quasi-semantic" HTML is avoided.:)
declare function so2il:tei2html($node as node(), $block-element-names as xs:string+, $element-only-element-names as xs:string+) {
    element {if (local-name($node) = ($block-element-names, $element-only-element-names)) then 'div' else 'span'}
        {$node/@*, attribute {'class'}{local-name($node)}, attribute {'title'}{if ($node/@type) then concat($node/@type, '-', local-name($node)) else local-name($node)}
        ,
        for $child in $node/node()
        return
            if ($child instance of element() and not($child/@class))
            (:NB: Check! Class attributes come from above in the same function, so elements will have more than one @class attached.:)
            then so2il:tei2html($child, $block-element-names, $element-only-element-names)
            else $child
        }
};

declare function so2il:standoff2inline-recurser($node as node(), $doc-id as xs:string, $editiorial-element-names as xs:string+, $target-format as xs:string) {
    element {node-name($node)}
        {$node/@*
        , 
        for $child in $node/node()
        return
            if ($child instance of element())
            then so2il:annotate-text($child, $doc-id, $editiorial-element-names, $target-format)
            else $child
        }
};

(:This function takes a sequence of top-level annotations and inserts as children all annotations that refer to them through their @xml:id, recursively:)
declare function so2il:build-up-annotations($top-level-annotations as element()*, $annotations as element()*) as element()* {
    for $annotation in $top-level-annotations
    return
        so2il:build-up-annotation($annotation, $annotations)
};

declare function so2il:build-up-annotation($annotation as element(), $annotations as element()*) as element()* {
        let $annotation-id := $annotation/@xml:id/string()
        let $annotation-element-name := local-name($annotation//a8n-body/*)
        let $children := $annotations[a8n-target//a8n-id eq $annotation-id]
(:        let $log := util:log("DEBUG", ("##$children): ", $children)):)
        let $children :=
            so2il:build-up-annotations($children, $annotations)
        return 
            local:insert-elements($annotation, $children, $annotation-element-name,  'first-child')            
};

(:Recurser for so2il:collapse-annotation().:)
(:TODO: Clear up why so2il:collapse-annotation() has to be run three times.:) 
declare function so2il:collapse-annotations($built-up-edition-a8ns as element()*) {
    for $annotation in $built-up-edition-a8ns
    return 
        so2il:collapse-annotation(so2il:collapse-annotation(so2il:collapse-annotation($annotation, 'a8n-annotation'), 'a8n-body'), 'a8n-base-layer')
        (:NB: 'base-layer' does not appear to be used.:)
};

(: This function takes a built-up annotation and 
1) attaches attributes, stored as grandchildren,
2) collapses it, i.e. removes levels from the hierarchy by substituting elements with their children, 
3) removes unneeded elements, and 
4) takes the string values of terminal text-critical elements that have child feature annotations. :)
declare function so2il:collapse-annotation($element as element(), $strip as xs:string+) as element() {
    let $log := util:log("DEBUG", ("##$element): ", $element)) return
        element {node-name($element)}
    {$element/@*, 
        if ($element/*/*/a8n-attribute/*)
        then 
            for $attribute in $element/*/*/a8n-attribute
            return
                let $attribute-name := $attribute/a8n-name/string()
                let $attribute-value := $attribute/a8n-value/string()
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
                    so2il:collapse-annotation(($child), $strip)
            else
                if ($child instance of element() and local-name($child) = ('a8n-attribute', 'a8n-layer-range-difference', 'a8n-target-layer')) (:we have no need for these two elements - actually, they have been removed, but should they be introduced again?:)
                then ()
                else
                    (:skip the attribute attached above:)
                    if ($child instance of element() and local-name($child) = 'a8n-target' and local-name($child/parent::element()) ne 'a8n-annotation') (:remove all target elements that are not at the base level:)
                    then ()
                    else
                        if ($child instance of element() and local-name($child/..) = ('lem', 'rdg', 'sic', 'reg') ) (:take string value of elements that are below terminal elements concerned with edition:)
                        then string-join($child//text(), ' ') (:NB: This is a hack (@token should be used) but in real life text-critical annotations will not have sibling children with text nodes, so this is only relevant to round-tripping with annotations that mix text-critical and feature annotations.:)
                        else
                            if ($child instance of text())
                            then $child
                            else so2il:collapse-annotation($child, $strip)
      }
};

(:This function merges the collapsed annotations with the target text. 
A sequence of slots (<segment/>), double the number of annotations plus 1, are created; 
annotations are filled into the even slots, whereas the text, 
with ranges calculated from the previous and following annotations, 
are filled into the uneven slots. Empty uneven slots can occur, 
but all even slots have annotations (though they may consist of an empty element).:)
(:TODO: check annotations for superimposition, containment, overlap. Use parent element and preceding-sibling nodes to get the correct hierarchical and sequential order:)
declare function so2il:merge-annotations-with-text($text as element(), $annotations as element()*, $target-layer as xs:string, $target-format as xs:string) as node()+ {
(:    let $log := util:log("DEBUG", ("##$text): ", $text)):)
    let $segment-count := (count($annotations) * 2) + 1
(:    let $log := util:log("DEBUG", ("##$segment-count): ", $segment-count)):)
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
                    let $annotation-offset := number($annotation//a8n-offset)
                    let $annotation-range := number($annotation//a8n-range)
                    let $annotation := $annotation/(* except a8n-target)
                    return
                        local:insert-elements($segment, $annotation, 'segment', 'first-child')
                (:A text node is being processed.:)
                else
                    <segment n="{$segment/@n/string()}">
                        {
                        let $segment-n := number($segment/@n)
                        let $previous-annotation-n := ($segment-n - 1) div 2
                        let $following-annotation-n := ($segment-n + 1) div 2
                        let $offset := 
                            if ($segment-n eq $segment-count) (:if it is the last text node:)
                            then $annotations[$previous-annotation-n]/a8n-target/a8n-offset/number() + $annotations[$previous-annotation-n]/a8n-target/a8n-range/number()
                            (:the offset is the length of of the base text minus the end position of the previous annotation plus 1:)
                            else
                                if (number($segment/@n) eq 1) (:if it is the first text node:)
                                then 1 (:start with position 1:)
                                else $annotations[$previous-annotation-n]/a8n-target/a8n-offset/number() + $annotations[$previous-annotation-n]/a8n-target/a8n-range/number()
                                (:if it is not the first or last text node, 
                                start with the position of the previous annotation plus its range plus 1:)
                        let $range := 
                            if ($segment-n eq count($segments))  (:if it is the last text node:)
                            then string-length($text) - ($annotations[$previous-annotation-n]/a8n-target/a8n-offset/number() + $annotations[$previous-annotation-n]/a8n-target/a8n-range/number()) + 1
                            (:if it is the last text node, then the range is the length of the base text minus the end position of the last annotation plus 1:)
                            else
                                if ($segment-n eq 1) (:if it is the first text node:)
                                then $annotations[$following-annotation-n]/a8n-target/a8n-offset/number() - 1
                                (:if it is the first text node, the the range is the offset of the following annotation minus 1:)
                                else $annotations[$following-annotation-n]/a8n-target/a8n-offset/number() - ($annotations[$previous-annotation-n]/a8n-target/a8n-offset/number() + $annotations[$previous-annotation-n]/a8n-target/a8n-range/number())
                                (:if it is not the first or the last text node, then the range is the offset of the following annotation minus the end position of the previous annotation :)
                        return
                            if (number($offset) and number($range))
                            then substring($text, $offset, $range)
                            else ''
                        
                        }
                    </segment>
(:    let $log := util:log("DEBUG", ("##$segments): ", $segments)):)
    let $segments :=
        for $segment in $segments
(:        let $log := util:log("DEBUG", ("##$segment): ", $segment)):)
        return
            if ($segment/@n mod 2 eq 0)
            then $segment/*
            else $segment/string()
    return 
        element {node-name($text)}{$text/@*, $segments}
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