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

(: Extracts all upper-level element nodes from the input element and records their position in relation to the base layer; extracts all attributes of the input element. :)
declare function local:get-top-level-annotations-keyed-to-base-text($input as element(), $edition-layer-elements) {
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
                                if (local-name($node) = ('milestone', 'pb', 'lb', 'hi')) (: NB: why can't $documentary-elements (down below) be used when $edition-layer-elements can be used?:)
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
                                if (local-name($node) = $edition-layer-elements or $node//app or $node//choice) 
                                then
                                    if (($node//app or local-name($node) = 'app') and $node//tei:lem) 
                                    then string-length(string-join($node//tei:lem)) - string-length(string-join($node//tei:rdg[not(contains(@wit/string(), 'TS1'))]))
                                    else 
                                        if (($node//tei:app or local-name($node) = 'app') and $node//tei:rdg)
                                        then 
                                            string-length($node//tei:rdg[not(contains(@wit/string(), 'TS1'))]) - string-length($node//tei:rdg[contains(@wit/string(), 'TS1')])
                                        else
                                            if (($node//tei:choice or local-name($node) = 'choice') and $node//tei:orig and $node//tei:reg)
                                            then string-length($node//tei:reg) - string-length($node//tei:orig)
                                            else
                                                if (($node//tei:choice or local-name($node) = 'choice') and $node//tei:expanded and $node//tei:expanded)
                                                then string-length($node//tei:expanded) - string-length($node//tei:abbr)
                                                else
                                                    if (($node//tei:choice or local-name($node) = 'choice') and $node//tei:sic and $node//tei:corr)
                                                    then string-length($node//tei:corr) - string-length($node//tei:sic)
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
                let $attribute-result := 
                        for $attribute in $node/(@* except @xml:id)
                            return <annotation type="attribute" xml:id="{concat('uuid-', util:uuid())}">
                            <target type="element" layer="annotation">{$id}</target>
                            <body>
                                <attribute>
                                    <name>{name($attribute)}</name>
                                    <value>{$attribute/string()}</value>
                                </attribute>
                            </body>
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
            return ($element-result, $attribute-result)
};

(: For each annotation keyed to the base layer, insert its location in relation to the authoritative layer, adding the previous offsets to the start position  :)
(: NB: this function could be moved inside local:get-top-level-annotations-keyed-to-base-text():)
declare function local:insert-authoritative-layer($nodes as element()*) as element()* {
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
    let $log := util:log("DEBUG", ("##$node): ", $node))
    let $log := util:log("DEBUG", ("##$nodelength): ", string-length($node)))
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
                case element(tei:corr) return
                    if ($target eq 'base') 
                    then () 
                    else $node
                case element(tei:expanded) return
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

(: This function removes inline elements from the result of separate-layers :)
declare function local:remove-inline-elements($nodes as node()*, $block-element-names as xs:string+) as node()* {
    for $node in $nodes/node()
    return
        if ($node instance of element())
        then
            if (local-name($node) = $block-element-names)
            then element {node-name($node)}
                    {
                    $node/@*
                    ,
                    local:remove-inline-elements($node, $block-element-names)
                    }
            else $node/node()
        else $node
};

declare function local:handle-element-only-annotations($node as node()) as item()* {
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
                        else local:whittle-down-annotations($element-annotations)
                        ,
                        $attribute-annotations
                        )
};

declare function local:handle-mixed-content-annotations($node as node()) as item()* {
    (:An annotation with mixed contents should be split up into text annotations and element annotations, in the same manner that the top-level annotations were extracted from the input, except that no edition-layer-elements are relevant:)
            let $layer-1-body-contents := $node//body/*(:get element below body - this can ony be a single element:)
            let $layer-1-body-contents := element {node-name($layer-1-body-contents)}{
                for $attribute in $layer-1-body-contents/(@* except @xml:id)
                    return attribute {name($attribute)} {$attribute}} (:construct empty element with attributes:)
            let $layer-1 := local:remove-elements($node, 'body')(:remove the body,:)
            let $layer-1 := local:insert-elements($layer-1, <body>{$layer-1-body-contents}</body>, 'target', 'after')(:and insert the new body:)
                return $layer-1
            ,
            let $layer-2-body-contents := local:get-top-level-annotations-keyed-to-base-text($node//body/*, '')
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

(: Removes one layer at a time from the upper-level annotations, reducing them, if neccesary, until they consist either of an empty element, or an element with a text node :)
declare function local:whittle-down-annotations($node as node()) as item()* {
            if (not($node//body/string())) (: there is no text anywhere, i.e it is an empty element, so extract its attributes:)
            then local:handle-element-only-annotations($node)
            else 
                if (local-name($node//body/*) eq 'attribute') (: it is an attribute annotation, so do not split it up, but pass through. :)
                then $node
                else 
                    if ($node//body/*/node() instance of text()) (: there is one level until the text node (but no mixed contents), so pass through as an element with a text node. :)
                    then $node
                    else 
                        if (count($node//body/*/*) ge 1 and $node//body/*[./text()]) (: there is mixed contents, so send on and receive back in reduced form:) (: if there is an element (the second '*') and if its parent (the first '*') is a text node, then we are dealing with mixed contents:)
                        then local:handle-mixed-content-annotations($node)
                        else local:handle-element-only-annotations($node) (:if it is not an empty element, and if it is not exclusively a text node, if it is not an attribute, and if it is not mixed contents, then it is a nested element node, so send it on and receive it back in reduced form :)
};

declare function local:generate-text-layer($element as element(), $target as xs:string) as element() {
    element {node-name($element)}
    {attribute{'xml:id'}{$element/@xml:id} (: all remaining attributes are saved as annotations :)(:NB: clean up - attribute declaration not needed:)
    ,
    for $node in $element/node()
        return
            if ($node instance of element() and not($node/text())) (: if the node is an element which does not have a child text node, then recurse. :)
            then local:generate-text-layer($node, $target)
            else
                if ($node instance of element() and exists($node/text())) (: if the node is an element which has a child text node, then reconstruct it with its @xml:id and get its text layer. :)
                then 
                    element {node-name($node)}
                    {attribute{'xml:id'}{$node/@xml:id}(:NB: clean up - attribute declaration not needed:)
                    ,
                    local:separate-text-layers($node, $target)
                    }
                else 
                    if ($node instance of comment()) (: pass through comments. :)
                    then $node
                    else ()
    }
};

declare function local:generate-top-level-annotations($elements as element()*, $edition-layer-elements as xs:string+) as element()* {
    for $element in $elements/*
        return
            if ($element/text())
            then local:get-top-level-annotations-keyed-to-base-text($element, $edition-layer-elements)
            else local:generate-top-level-annotations($element, $edition-layer-elements)
};

(:let $doc-title := 'sample_MTDP10363.xml':)
(:let $doc := doc(concat('/db/test/out/', $doc-title)):)
(:let $doc-element := $doc/element():)

let $doc-element := 
<TEI xmlns="http://www.tei-c.org/ns/1.0" xml:id="MTDP10363">
    <teiHeader> <fileDesc> <titleStmt> <title>Title</title> </titleStmt> <publicationStmt> <p>Publication Information</p> </publicationStmt> <sourceDesc> <p>Information about the source</p> </sourceDesc> </fileDesc> </teiHeader>
<text xml:id="text1"><body xml:id="uuid-fcc7ddd8-7e39-4032-ba3f-ba2dfc1f0eee" facs="#MTDP10363">
<div type="chapter" xml:id="dv0001">
<p rend="centerautosum" xml:id="pa000001">Government of new Territory of Nevada—Governor <name xml:id="xxx1" type="person">Nye</name> <lb xml:id="uuid-20d6643b-0a9d-4ef9-9d19-41ea08d0a196"/>and the practical jokers—<name xml:id="xxx2" type="person">Mr. Clemens</name> begins journalistic life <lb xml:id="uuid-50dea63f-c4c1-425c-b883-b9e06ea7d4a9"/>on <name xml:id="xxx3" type="place">Virginia City</name> <app from="dg0000" type="aet" xml:id="ap0000"><lem xml:id="uuid-f3fc4683-b570-403f-ae10-3d976c8f4568"><hi xml:id="uuid-98b78c33-a06c-4760-9f62-ff46166c8523" rend="italic"><name xml:id="xxx4" type="publication">Enterprise</name></hi></lem><rdg xml:id="uuid-ee95a0c8-a4df-4a47-b957-c49613eab3f0" wit="TS1, TS2"><name xml:id="xxx5" type="publication">Enterprise</name></rdg></app>—Reports legislative sessions—<lb xml:id="uuid-ffd47ef8-dce4-4a4a-a82c-59fcc839d95a"/>He and <name xml:id="xxx6" type="person">Orion</name> prosper—<name xml:id="xxx7" type="person">Orion</name> builds <app from="dg0001" type="aet" xml:id="ap0001"><lem xml:id="uuid-270b34bd-3b59-4a5c-935d-c4790682f1aa">twelve-thousand-dollar</lem><rdg xml:id="uuid-5a3e0774-13d5-45f2-ac87-08f98eb0341a" wit="TS1">$12,000.</rdg><rdg xml:id="uuid-f662b333-0ff0-4b08-b1cf-aabb3ef37c58" wit="TS2">$12,000</rdg></app> house—<app from="dg0002" type="aet" xml:id="ap0002"><lem xml:id="uuid-54d08490-608c-402a-a0e3-4ddaab0be26c">Governor</lem><rdg xml:id="uuid-7c692127-56e0-4730-a978-f7e1d4ab697a" wit="TS1, TS2">Gov.</rdg></app><name xml:id="xxx8" type="person">Nye</name> turns <name xml:id="xxx9" type="place">Territory of Nevada</name> into a <app from="dg0003" type="aet" xml:id="ap0003"><lem xml:id="uuid-cee18fca-11cc-4316-a0d6-55be002299ba">State.</lem><rdg xml:id="uuid-a9ee968e-1f5b-4bc6-907c-f18d141d61ae" wit="TS1, TS2">State. <lb xml:id="uuid-913f9666-6549-4d6b-b499-f5275431e97b"/> (Miss Hobby, please paste this in at this point, in record of April 1st, but I may not comment on it until later.)</rdg></app></p>
<quote xml:id="uuid-0150ce04-9901-4739-a767-a00b747953f2" rend="blockquote"><p rend="center" xml:id="pa000002"><hi xml:id="uuid-f391061f-7329-481f-8db8-ad1f42572a6f" rend="bold">PROMOTION FOR BARNES, WHOM TILLMAN&#160;BERATED</hi><ptr target="#en0001" type="an" xml:id="nv0001"/></p><milestone xml:id="uuid-b0ba1da0-4f9b-44af-b404-dd097eb2b284" rend="lightrule" unit="section"/><p rend="center" xml:id="pa000003"><hi xml:id="uuid-5888d6b7-48df-4d76-b01c-579cfbf2728d" rend="bold">Had Woman Ejected from White House; to be Postmaster.</hi></p><milestone xml:id="uuid-da7c0f15-25cf-4faa-9381-97650a7cc6f2" rend="lightrule" unit="section"/><p rend="center" xml:id="pa000004"><hi xml:id="uuid-046f291b-6922-42bf-a628-b569033170a9" rend="bold"> MERRITT GETS NEW PLACE</hi></p><milestone xml:id="uuid-704f3350-0d90-4718-a011-f5a9cd96f412" rend="lightrule" unit="section"/><p rend="center" xml:id="pa000005"><hi xml:id="uuid-602b35c7-b4cf-472e-b1ba-a31e62be3998" rend="bold">Present Postmaster at Washington to be Made <lb xml:id="uuid-7cf5bd55-4a62-4559-997f-bb64abe9cbfb"/>Collector at Niagara—Platt Not Consulted.</hi></p><p rend="center" xml:id="pa000006"><hi xml:id="uuid-c5c9d69e-8f0d-4c24-95ab-15e916d8516b" rend="italic">Special to The New York Times.</hi></p><p rend="text-indent:2" xml:id="pa000007">WASHINGTON, March 31.—President Roosevelt surprised the capital this afternoon by announcing that he would appoint Benjamin F. Barnes as Postmaster of Washington, to succeed John A. Merritt of New York. Mr. Merritt, who for several years has been Postmaster here, has been chosen for Collector of the Port of Niagara, succeeding the late Major James Low<ptr target="#en0002" type="an" xml:id="nv0002"/>.</p><p rend="text-indent:2" xml:id="pa000008">Mr. Barnes is at present assistant secretary to the President. Only a short time ago he figured extensively in the newspapers for having ordered the forcible ejection from the White House of Mrs. Minor Morris, a Washington woman who had called to see the President. What attracted attention to the case was not the ejection itself, but the violence with which it was performed.</p><p rend="text-indent:2" xml:id="pa000009">Mrs. Morris, who had been talking to Barnes in an ordinary conversational tone, and with no indications of excitement, so far as the spectators observed, was seized by two policemen and dragged by the arms out of the building and across the asphalt walk in front of the White House, a distance corresponding to that of two ordinary city blocks. During a part of the journey a negro carried her by the feet. Her dress was torn and trampled.</p><p rend="text-indent:2" xml:id="pa000010">She was locked up on a charge of disorderly conduct, and when it was learned that she would be released on that charge a policeman, a relative of Barnes’s, was sent to the House of Detention to prefer a charge of insanity against her so that she would have to be held. She was held accordingly until two physicians had examined her and pronounced her sane. He was denounced by Mrs. Morris, by various newspapers, and by Mr. Tillman in the Senate.</p> <p rend="text-indent:2" xml:id="pa000011">The appointment of Barnes to be Postmaster <app from="dg0005" type="aet" xml:id="ap0004"><lem xml:id="uuid-db312f17-7f15-4041-99f7-6a96b3e60fba">so</lem><rdg xml:id="uuid-ea3d9d83-8371-48cb-b9c1-1eabaa8867eb" wit="Times">so so</rdg><rdg xml:id="uuid-37300be1-2a22-4621-b292-e672fa264a5d" wit="TS2">so</rdg></app> soon after this incident has created endless talk here. It is taken to be the President’s way of expressing confidence in Barnes and repaying him for the pain he suffered as a result of the newspaper criticisms of his course.</p></quote>
</div>
</body></text></TEI>
let $doc-header := $doc-element/tei:teiHeader
let $doc-text := $doc-element/tei:text


let $edition-layer-elements := ('app', 'rdg', 'lem', 'choice', 'corr', 'sic', 'orig', 'reg', 'abbr', 'expanded')
let $documentary-elements := ('milestone', 'pb', 'lb', 'cb', 'hi', 'gap', 'damage', 'unclear', 'supplied', 'restore', 'space', 'handShift')
let $block-element-names := ('text', 'body', 'div', 'head', 'p', 'quote' )

let $base-text := local:generate-text-layer($doc-text, 'base')
let $log := util:log("DEBUG", ("##$base-text): ", $base-text))
let $base-text := local:remove-inline-elements($base-text, $block-element-names)

let $authoritative-text := local:generate-text-layer($doc-text, 'authoritative')
let $authoritative-text := local:remove-inline-elements($authoritative-text, $block-element-names)

let $top-level-annotations := local:generate-top-level-annotations($doc-text, $edition-layer-elements)
let $top-level-annotations := local:insert-authoritative-layer($top-level-annotations)

let $annotations :=
    for $node in $top-level-annotations
        return local:whittle-down-annotations($node)

        return 
            <result>
                <base-text>{element {node-name($doc-element)}{$doc-element/@*}}{$doc-header}{element {node-name($doc-text)}{$doc-text/@*, $base-text}}</base-text>
                <authoritative-text>{element {node-name($doc-element)}{$doc-element/@*}}{$doc-header}{element {node-name($doc-text)}{$doc-text/@*, $authoritative-text}}</authoritative-text>
                <annotations>{$annotations}</annotations>
            </result>
