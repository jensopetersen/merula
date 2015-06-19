xquery version "3.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare boundary-space preserve;

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
        let $marked-up-string := string-join(local:separate-text-layers(<annotation>{$node}</annotation>, 'base'))
        let $id := concat('uuid-', util:uuid())
        let $position-start := string-length($base-before-element) + string-length($base-before-text)
        let $position-end := $position-start + string-length($marked-up-string)
            return
                let $element-result :=
                    <annotation type="element" xml:id="{$id}" status="{
                            let $base-text := string-join(local:separate-text-layers($input, 'base'))
                            let $character-before := substring($base-text, $position-start, 1)
                            let $character-after := substring($base-text, $position-end + 1, 1)
                            let $characters-before-and-after := concat($character-before, $character-after)
                            let $characters-before-and-after := replace($characters-before-and-after, '\s|\p{P}', '')
                            return
                            if ($characters-before-and-after) then "string" else "token"}">(: If the targeted text is a word, i.e. has either space or punctuation on both sides, label it as "token" - in the editor tokens have to be labeled, since adding or removing a word has to take into consideration its isolation from neighbouring words. NB: think of a better label than "string":)
                        <target type="range" layer="{
                            if (local-name($node) = $edition-layer-elements) 
                            then 'edition' 
                            else 
                                if (local-name($node) = $documentary-elements)
                                then 'document' 
                                else 'feature'}">
                            <base-layer>
                                <id>{string($node/../@xml:id)}</id>
                                <start>{$position-start + 1}</start>
                                <offset>{$position-end - $position-start}</offset>
                            </base-layer>
                        </target>
                        <body>{element {node-name($node)}{$node/@xml:id, $node/node()}}</body>
                        <layer-offset-difference>{
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
                                    return $off-set-difference}</layer-offset-difference>
                        <admin/>
                    </annotation>
                let $attribute-result := 
                        for $attribute in $node/(@* except @xml:id)
                            return <annotation type="attribute" xml:id="{concat('uuid-', util:uuid())}">
                            <target type="element" layer="annotation">{$node/@xml:id}</target>
                            <body>
                                <attribute>
                                    <name>{name($attribute)}</name>
                                    <value>{$attribute/string()}</value>
                                </attribute>
                            </body>
                            <admin/>
                            </annotation>
            return ($element-result, $attribute-result)
};

(: For each annotation keyed to the base layer, insert its location in relation to the authoritative layer, adding the previous offsets to the start position  :)
(: NB: this function could be moved inside local:get-top-level-annotations-keyed-to-base-text():)
declare function local:insert-authoritative-layer-in-top-level-annotations($nodes as element()*) as element()* {
    (
    $nodes[@type ne 'element']
    ,
    for $node in $nodes[@type eq 'element']
        let $id := concat('uuid-', util:uuid($node/target/base-layer/id)) (:create a UUID based on the UUID of the base layer:)
        let $sum-of-previous-offsets := sum($node/preceding-sibling::annotation/layer-offset-difference, 0)
        let $base-level-start := $node/target/base-layer/start cast as xs:integer
        let $authoritative-layer-start := $base-level-start + $sum-of-previous-offsets
        let $layer-offset := $node/target/base-layer/offset + $node/layer-offset-difference
        let $authoritative-layer := <authoritative-layer><id>{$id}</id><start>{$authoritative-layer-start}</start><offset>{$layer-offset}</offset></authoritative-layer>
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
            let $layer-1-body-contents := $node//body/* (: get the element below body - this can ony be a single item :)
            let $layer-1-admin-contents := $node//admin/* (: get the elements below admin :)
            let $layer-1-id := $node/@xml:id/string() (: get id :)
            let $layer-1-body-attributes :=
                for $attribute in $layer-1-body-contents/(@* except @xml:id)
                    return 
                        <annotation type="attribute" xml:id="{concat('uuid-', util:uuid())}">
                            <target type="element" layer="annotation">{$layer-1-id}</target>
                            <body>
                                <attribute>
                                    <name>{name($attribute)}</name>
                                    <value>{$attribute/string()}</value>
                                </attribute>
                            </body>
                            <admin>{$layer-1-admin-contents}</admin>
                        </annotation>
            let $layer-1-body-contents := element {node-name($layer-1-body-contents)}{$layer-1-body-contents/@xml:id}
            (:construct empty element:)
            let $layer-1 := local:remove-elements($node, 'body') (:remove the old body,:)
            let $layer-1 := local:insert-elements($layer-1, <body>{$layer-1-body-contents}</body>, 'target', 'after') (: and insert the new body:)
                return ($layer-1, $layer-1-body-attributes)
                (:return the old annotation, with an empty element below body:)
            ,
            let $layer-1-id := $node/@xml:id/string() (: get id :)
            let $layer-1-status := $node/@status/string() (: get the status of original annotation :)
            let $layer-1-admin-contents := $node//admin/* (:get the elements below admin:)
            let $layer-2-body-contents := $node//body/*/* (: get the contents of what is below the body - the empty element in layer-1; there may be multiple elements here.:)
            for $element at $i in $layer-2-body-contents
                let $annotation-id := concat('uuid-', util:uuid())
            (: returns the new annotations, with the contents from the old annotation below body split over several annotations; record their order instead of start position and offset :)
                let $attribute-annotations := 
                    for $attribute in $element/(@* except @xml:id)
                        return 
                            <annotation type="attribute" xml:id="{concat('uuid-', util:uuid())}">
                                <target type="element" layer="annotation">{$annotation-id}</target>
                                <body>
                                    <attribute>
                                        <name>{name($attribute)}</name>
                                        <value>{$attribute/string()}</value>
                                    </attribute>
                                </body>
                                <admin>{$layer-1-admin-contents}</admin>
                            </annotation>
                let $element-annotations :=
                    <annotation type="element" xml:id="{$annotation-id}" status="{$layer-1-status}">
                        <target type="element" layer="annotation">
                            <annotation-layer>
                                <id>{$layer-1-id}</id>
                                <order>{$i}</order>
                            </annotation-layer>
                        </target>
                        <body>{element {node-name($element)}{$element/@xml:id, $element/node()}}</body>
                        <admin>{$layer-1-admin-contents}</admin>
                    </annotation>
                    return
                        (
                        if (not($element-annotations//body/string()) or $element-annotations//body/*/node() instance of text() or $element-annotations//body/node() instance of text())
                        then $element-annotations 
                        else local:whittle-down-annotations($element-annotations, $documentary-elements)
                        ,
                        $attribute-annotations
                        )
};

declare function local:handle-mixed-content-annotations($node as node(), $documentary-elements as xs:string+) as item()* {
    (:An annotation with mixed contents should be split up into text annotations and element annotations, in the same manner that the top-level annotations were extracted from the input, except that no edition-layer-elements are relevant:)
            let $layer-1-body-contents := $node//body/*(:get element below body - this can ony be a single element:)
            let $layer-1-body-contents := element {node-name($layer-1-body-contents)}{
                for $attribute in $layer-1-body-contents/(@* except @xml:id)
                    return attribute {name($attribute)} {$attribute}} (:construct empty element with attributes:)
            let $layer-1 := local:remove-elements($node, 'body')(:remove the body,:)
            let $layer-1 := local:insert-elements($layer-1, <body>{$layer-1-body-contents}</body>, 'target', 'after')(:and insert the new body:)
                return $layer-1
            ,
            let $layer-2-body-contents := local:get-top-level-annotations-keyed-to-base-text($node//body/*, '', $documentary-elements)
            let $layer-1-id := <id>{$node/@xml:id/string()}</id>
            for $layer-2-body-content in $layer-2-body-contents
                return
                    let $layer-2-body-content := local:remove-elements($layer-2-body-content, ('id', 'layer-offset-difference'))
                    let $layer-2 := local:insert-elements($layer-2-body-content, $layer-1-id, 'start', 'before')
                        return
                            if (not($layer-2//body/string()) or $layer-2//body/*/node() instance of text() or $layer-2//body/node() instance of text())
                        then $layer-2
                        else local:whittle-down-annotations($layer-2, $documentary-elements)
};

(: Removes one layer at a time from the upper-level annotations, reducing them, if neccesary, until they consist either of an empty element, or an element with a text node :)
declare function local:whittle-down-annotations($node as node(), $documentary-elements as xs:string+) as item()* {
            if (not($node//body/string())) (: there is no text anywhere, i.e it is an empty element, so extract its attributes:)
            then local:handle-element-only-annotations($node, $documentary-elements)
            else 
                if (local-name($node//body/*) eq 'attribute') (: it is an attribute annotation, so do not split it up, but pass through. :)
                then $node
                else
                    if (count($node//body/*/*) ge 1 and $node//body/*[./text()]) (: there is mixed contents, so send on and receive back in reduced form:) (: if there is an element (the second '*') and if its parent (the first '*') is a text node, then we are dealing with mixed contents:)
                    then local:handle-mixed-content-annotations($node, $documentary-elements)
                    else 
                        if ($node//body/*/node() instance of text()) (: there is one level until the text node (but no mixed contents), so pass through as an element with a text node. :)
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

(:recurse through the document, extracting annotations when hitting blocl-level elements:)
declare function local:generate-top-level-annotations-keyed-to-base-text($elements as element()*, $edition-layer-elements as xs:string+, $documentary-elements as xs:string+, $block-element-names as xs:string+) as element()* {
    for $element in $elements/*
        return
            if (local-name($element) = $block-element-names)
            then local:get-top-level-annotations-keyed-to-base-text($element, $edition-layer-elements, $documentary-elements)
            else local:generate-top-level-annotations-keyed-to-base-text($element, $edition-layer-elements, $documentary-elements, $block-element-names)
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
let $block-element-names := ('text', 'body', 'div', 'head', 'p', 'quote' )
(:TODO: the idea is that an element all of whose ancestors are element-only-elements is a block-level element, so this has to be refined in terms of $element-only-element-names; empty elements have been filtered away:)
let $element-only-element-names := ('TEI', 'abstract', 'accMat', 'acquisition', 'activity', 'additional', 'additions', 'addrLine', 'adminInfo', 'age', 'altIdent', 'altIdentifier', 'analytic', 'appInfo', 'application', 'arc', 'attDef', 'attList', 'attRef', 'authority', 'availability', 'back', 'bicond', 'binding', 'bindingDesc', 'birth', 'body', 'broadcast', 'cRefPattern', 'calendar', 'calendarDesc', 'castGroup', 'castItem', 'catDesc', 'catRef', 'category', 'cell', 'change', 'channel', 'char', 'charDecl', 'charName', 'charProp', 'classCode', 'classDecl', 'classes', 'closer', 'collation', 'collection', 'colophon', 'cond', 'condition', 'constitution', 'constraint', 'constraintSpec', 'content', 'correction', 'creation', 'custEvent', 'custodialHist', 'datatype', 'death', 'decoDesc', 'decoNote', 'defaultVal', 'derivation', 'div', 'div1', 'div2', 'div3', 'div4', 'div5', 'div6', 'div7', 'divGen', 'docEdition', 'docImprint', 'docTitle', 'domain', 'eLeaf', 'editionStmt', 'editorialDecl', 'education', 'encodingDesc', 'entry', 'entryFree', 'epilogue', 'equipment', 'equiv', 'event', 'exemplum', 'explicit', 'f', 'fDecl', 'fDescr', 'facsimile', 'factuality', 'faith', 'figDesc', 'fileDesc', 'filiation', 'finalRubric', 'floruit', 'foliation', 'front', 'fsConstraints', 'fsDecl', 'fsDescr', 'fsdDecl', 'fsdLink', 'geoDecl', 'glyph', 'glyphName', 'group', 'handDesc', 'handNote', 'handNotes', 'head', 'headItem', 'headLabel', 'history', 'hyphenation', 'iNode', 'if', 'iff', 'imprimatur', 'imprint', 'incipit', 'institution', 'interaction', 'interpretation', 'item', 'keywords', 'langKnowledge', 'langKnown', 'langUsage', 'language', 'layout', 'layoutDesc', 'leaf', 'lem', 'licence', 'listPrefixDef', 'localName', 'locale', 'mapping', 'memberOf', 'metDecl', 'metSym', 'moduleRef', 'monogr', 'msContents', 'msItem', 'msItemStruct', 'msName', 'msPart', 'musicNotation', 'namespace', 'nationality', 'node', 'normalization', 'notesStmt', 'nym', 'objectDesc', 'occupation', 'opener', 'org', 'origin', 'particDesc', 'performance', 'person', 'personGrp', 'physDesc', 'place', 'postBox', 'postCode', 'postscript', 'prefixDef', 'preparedness', 'profileDesc', 'projectDesc', 'prologue', 'provenance', 'publicationStmt', 'purpose', 'quotation', 'rdg', 'rdgGrp', 'recordHist', 'recording', 'recordingStmt', 'refState', 'refsDecl', 'relation', 'remarks', 'rendition', 'repository', 'residence', 'resp', 'revisionDesc', 'root', 'row', 'rubric', 'samplingDecl', 'scriptDesc', 'scriptNote', 'scriptStmt', 'seal', 'sealDesc', 'segmentation', 'seriesStmt', 'set', 'setting', 'settingDesc', 'sex', 'socecStatus', 'source', 'sourceDesc', 'sourceDoc', 'speaker', 'stdVals', 'street', 'styleDefDecl', 'summary', 'support', 'supportDesc', 'surfaceGrp', 'surrogates', 'tagUsage', 'tagsDecl', 'taxonomy', 'teiCorpus', 'teiHeader', 'text', 'textClass', 'then', 'titlePage', 'titlePart', 'titleStmt', 'trailer', 'transpose', 'triangle', 'typeDesc', 'typeNote', 'unicodeName', 'vDefault', 'vRange', 'valDesc', 'valItem', 'value', 'variantEncoding', 'when', 'witness')
let $base-text := local:generate-text-layer($doc-text, 'base')
let $base-text := local:remove-inline-elements($base-text, $block-element-names)

let $authoritative-text := local:generate-text-layer($doc-text, 'authoritative')
let $authoritative-text := local:remove-inline-elements($authoritative-text, $block-element-names)

let $top-level-annotations := local:generate-top-level-annotations-keyed-to-base-text($doc-text, $edition-layer-elements, $documentary-elements, $block-element-names)
let $top-level-annotations := local:insert-authoritative-layer-in-top-level-annotations($top-level-annotations)

let $annotations :=
    for $node in $top-level-annotations
        return local:whittle-down-annotations($node, $documentary-elements)

        return 
            <result>
                <top-level-annotations>{$top-level-annotations}</top-level-annotations>
                <input>{$doc-text}</input>
                <base-text>{element {node-name($doc-element)}{$doc-element/@*}}{$doc-header}{element {node-name($doc-text)}{$doc-text/@*, $base-text}}</base-text>
                <authoritative-text>{element {node-name($doc-element)}{$doc-element/@*}}{$doc-header}{element {node-name($doc-text)}{$doc-text/@*, $authoritative-text}}</authoritative-text>
                <annotations>{$annotations}</annotations>
            </result>
