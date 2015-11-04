xquery version "3.0";

import module namespace so2il="http://exist-db.org/xquery/app/standoff2inline" at "../modules/standoff2inline.xql";
import module namespace il2so="http://exist-db.org/xquery/app/inline2standoff" at "inline2standoff.xql";

declare namespace tei="http://www.tei-c.org/ns/1.0";

let $doc-id := 'sha-ham'
let $annotation-out-path := '/db/apps/merula/data/annotations'
let $annotation-out-collection-path := concat($annotation-out-path, "/", $doc-id)

let $doc-title := 'sample_MTDP10363.xml'
let $doc-title := 'CHANT-0874-clean-head-app-ref-wit.xml'
let $doc := doc(concat($il2so:text-in-collection, '/', $doc-title))
let $doc-element := $doc/element()
let $doc-header := $doc-element/tei:teiHeader
let $doc-text := $doc-element/tei:text
let $wit := $doc-header/tei:fileDesc/tei:sourceDesc/tei:listWit/tei:witness[@n eq '1']/@xml:id/string()
let $wit := '#' || $wit

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

let $editorial-element-names := ('app', 'rdg', 'lem', 'choice', 'corr', 'sic', 'orig', 'reg', 'abbr', 'expan', 'ex', 'mod', 'subst', 'add', 'del')
let $documentary-element-names := ('milestone', 'pb', 'lb', 'cb', 'hi', 'gap', 'damage', 'unclear', 'supplied', 'restore', 'space', 'handShift')
let $text-block-element-names := ('ab', 'castItem', 'l', 'role', 'roleDesc', 'speaker', 'stage', 'p', 'quote')
(: NB: adding seg – though it is not a $text-block-element – to handle CHANT documents :)
let $text-block-element-names := ($text-block-element-names, 'seg')
(: NB: removing p – though it is a $text-block-element – to handle CHANT documents :)
let $text-block-element-names := remove($text-block-element-names, index-of($text-block-element-names, 'p'))
(:TODO: the idea is that an element that can hold text, all of whose ancestors are element-only-elements, is a block-level element, 
so use of $text-block-element-names has to be dropped in favour of using in terms of $element-only-element-names.:)
let $barren-element-names := ('cb', 'gb', 'lb', 'milestone', 'pb', 'ptr', 'oRef', 'pRef', 'move', 'catRef', 'refState', 'binary', 'default', 'fsdLink', 'iff', 'numeric', 'symbol', 'then', 'alt', 'anchor', 'link', 'when', 'pause', 'shift', 'attRef', 'classRef', 'elementRef', 'equiv', 'macroRef', 'specDesc', 'specGrpRef', 'textNode', 'lacunaEnd', 'lacunaStart', 'variantEncoding', 'witEnd', 'witStart', 'addSpan', 'damageSpan', 'delSpan', 'handShift', 'redo', 'undo', 'caesura')
let $element-only-element-names := ('TEI', 'abstract', 'additional', 'address', 'adminInfo', 'altGrp', 'altIdentifier', 'alternate', 'analytic', 'app', 'appInfo', 'application', 'arc', 'argument', 'attDef', 'attList', 'availability', 'back', 'biblFull', 'biblStruct', 'bicond', 'binding', 'bindingDesc', 'body', 'broadcast', 'cRefPattern', 'calendar', 'calendarDesc', 'castGroup', 'castList', 'category', 'certainty', 'char', 'charDecl', 'charProp', 'choice', 'cit', 'classDecl', 'classSpec', 'classes', 'climate', 'cond', 'constraintSpec', 'correction', 'correspAction', 'correspContext', 'correspDesc', 'custodialHist', 'datatype', 'decoDesc', 'dimensions', 'div', 'div1', 'div2', 'div3', 'div4', 'div5', 'div6', 'div7', 'divGen', 'docTitle', 'eLeaf', 'eTree', 'editionStmt', 'editorialDecl', 'elementSpec', 'encodingDesc', 'entry', 'epigraph', 'epilogue', 'equipment', 'event', 'exemplum', 'fDecl', 'fLib', 'facsimile', 'figure', 'fileDesc', 'floatingText', 'forest', 'front', 'fs', 'fsConstraints', 'fsDecl', 'fsdDecl', 'fvLib', 'gap', 'glyph', 'graph', 'graphic', 'group', 'handDesc', 'handNotes', 'history', 'hom', 'hyphenation', 'iNode', 'if', 'imprint', 'incident', 'index', 'interpGrp', 'interpretation', 'join', 'joinGrp', 'keywords', 'kinesic', 'langKnowledge', 'langUsage', 'layoutDesc', 'leaf', 'lg', 'linkGrp', 'list', 'listApp', 'listBibl', 'listChange', 'listEvent', 'listForest', 'listNym', 'listOrg', 'listPerson', 'listPlace', 'listPrefixDef', 'listRef', 'listRelation', 'listTranspose', 'listWit', 'location', 'locusGrp', 'macroSpec', 'media', 'metDecl', 'moduleRef', 'moduleSpec', 'monogr', 'msContents', 'msDesc', 'msIdentifier', 'msItem', 'msItemStruct', 'msPart', 'namespace', 'node', 'normalization', 'notatedMusic', 'notesStmt', 'nym', 'objectDesc', 'org', 'particDesc', 'performance', 'person', 'personGrp', 'physDesc', 'place', 'population', 'postscript', 'precision', 'prefixDef', 'profileDesc', 'projectDesc', 'prologue', 'publicationStmt', 'punctuation', 'quotation', 'rdgGrp', 'recordHist', 'recording', 'recordingStmt', 'refsDecl', 'relatedItem', 'relation', 'remarks', 'respStmt', 'respons', 'revisionDesc', 'root', 'row', 'samplingDecl', 'schemaSpec', 'scriptDesc', 'scriptStmt', 'seal', 'sealDesc', 'segmentation', 'sequence', 'seriesStmt', 'set', 'setting', 'settingDesc', 'sourceDesc', 'sourceDoc', 'sp', 'spGrp', 'space', 'spanGrp', 'specGrp', 'specList', 'state', 'stdVals', 'styleDefDecl', 'subst', 'substJoin', 'superEntry', 'supportDesc', 'surface', 'surfaceGrp', 'table', 'tagsDecl', 'taxonomy', 'teiCorpus', 'teiHeader', 'terrain', 'text', 'textClass', 'textDesc', 'timeline', 'titlePage', 'titleStmt', 'trait', 'transpose', 'tree', 'triangle', 'typeDesc', 'vAlt', 'vColl', 'vDefault', 'vLabel', 'vMerge', 'vNot', 'vRange', 'valItem', 'valList', 'vocal')
(: NB: adding p – though it is not a $element-only-element – to handle CHANT documents :)
let $element-only-element-names := ($element-only-element-names, 'p')

let $base-text := il2so:generate-text-layer($doc-text, 'base-text', $wit)
let $base-text := il2so:remove-inline-elements($base-text, $text-block-element-names, $element-only-element-names)

let $target-text := il2so:generate-text-layer($doc-text, 'target-text', $wit)
let $target-text := il2so:remove-inline-elements($target-text, $text-block-element-names, $element-only-element-names)

let $annotations-1 := il2so:generate-top-level-annotations-keyed-to-base-text($doc-text, $editorial-element-names, $documentary-element-names, $text-block-element-names, $element-only-element-names, $barren-element-names, $wit)
let $annotations-2 :=
    for $annotation in $annotations-1
    return il2so:peel-off-annotations($annotation, $editorial-element-names, $documentary-element-names, $wit)
let $annotations-3 := il2so:prepare-annotations-for-output-to-doc($annotations-2)

let $output-format := 'exide'
(:let $output-format := 'doc':)
(:let $output-format := 'download':)

let $base-text := element {node-name($doc-element)}{$doc-element/@*, $doc-header, element {node-name($doc-text)}{$doc-text/@*, $base-text}}   
let $annotation-out-collection := 
    if (not(xmldb:collection-available($annotation-out-collection-path)) and $output-format eq 'doc')
    then xmldb:create-collection(xmldb:encode-uri($annotation-out-path), xmldb:encode-uri($doc-id))
    else ()
let $result :=
    <result>
        <base-text>{$base-text}</base-text>
        <target-text>{element {node-name($doc-element)}{$doc-element/@*, $doc-header, element {node-name($doc-text)}{$doc-text/@*, $target-text}}}</target-text>
        <annotations-1>{$annotations-1}</annotations-1>
        <annotations-3>{$annotations-3}</annotations-3>
    </result>
return
    if ($output-format eq 'exide')
    then
        $result
    else
        if ($output-format eq 'doc')
        then
            (for $annotation in $annotations-3
            let $annotation-home-name := il2so:find-annotation-home($annotations-3, $annotation//a8n-id)
            let $annotation-home-path := concat($annotation-out-collection-path, "/", $annotation-home-name)
            let $annotation-home-collection := 
                if (not(xmldb:collection-available($annotation-home-path)))
                then xmldb:create-collection(xmldb:encode-uri($annotation-out-collection-path), xmldb:encode-uri($annotation-home-name))
            else ()
    return
        xmldb:store($annotation-home-path,  concat($annotation/@xml:id, '.xml'), $annotation)
    ,
        xmldb:store($il2so:text-out-collection, $doc-title, $base-text)
    ) else
        if ($output-format eq 'download')
                then
                    let $timestamp := datetime:timestamp-to-datetime(datetime:timestamp())
                    let $timestamp := substring-before(string($timestamp), '.')
                    let $file-name := ('results-' || $timestamp || '.xml')
                    return 
                        il2so:download-xml($result, $file-name) 

            else ()