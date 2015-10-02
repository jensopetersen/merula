xquery version "3.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace so2il="http://exist-db.org/xquery/app/standoff2inline" at "../modules/standoff2inline.xql";
import module namespace il2so="http://exist-db.org/xquery/app/inline2standoff" at "inline2standoff.xql";

let $new-annotation :=
<a8n-annotation motivatedBy="editing" xml:id="uuid-79545eb1-8b75-4451-a72f-80bd0f1a6cbd">
    <a8n-target>
        <a8n-id>pa000001</a8n-id>
        <a8n-offset>85</a8n-offset>
        <a8n-range>6</a8n-range>
        <a8n-order>1</a8n-order>
    </a8n-target>
    <a8n-body>
    <app xmlns="http://www.tei-c.org/ns/1.0">
        <lem wit="#TS2">commences</lem>
        <rdg wit="#TS1">begins</rdg>
    </app>
    </a8n-body>
</a8n-annotation>

let $data-collection := '/db/apps/merula/data'
let $annotation-collection := $data-collection || "/" || 'annotations/sha-ham'
let $target-id := $new-annotation/a8n-target/a8n-id
let $annotation-collection-path := $annotation-collection || "/" || $target-id
let $annotation-collection := collection($annotation-collection-path)

let $offset := sum($new-annotation/a8n-target/a8n-offset)
let $range := $new-annotation/a8n-target/a8n-range/number()

let $base-text := $data-collection || "/" || 'sample_MTDP10363.xml'
let $base-text := doc($base-text)/element()
let $wit := $base-text/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:listWit/tei:witness[@n eq '1']/string()
let $base-text := $base-text//id($target-id)
let $base-text := substring($base-text, 1, $offset + $range)
let $base-text-length := string-length($base-text)
let $annotation-base-text-version := so2il:separate-text-layers($new-annotation/(* except a8n-target), 'base-text', $wit)
let $annotation-target-text-version := so2il:separate-text-layers($new-annotation/(* except a8n-target), 'target-text', $wit)
let $annotation-base-text-version-length := string-length($annotation-base-text-version)
let $annotation-target-text-version-length := string-length($annotation-target-text-version)
let $version-difference := $annotation-target-text-version-length - $annotation-base-text-version-length
let $version-difference := <a8n-offset timestamp="{datetime:timestamp-to-datetime(datetime:timestamp())}" cause="{$new-annotation/@xml:id}">{$version-difference}</a8n-offset>

let $editorial-element-names := ('app', 'rdg', 'lem', 'choice', 'corr', 'sic', 'orig', 'reg', 'abbr', 'expan', 'ex', 'mod', 'subst', 'add', 'del')
let $feature-annotations := $annotation-collection[not(local-name(a8n-annotation/a8n-body/*) = $editorial-element-names)]
let $feature-annotations := $feature-annotations/a8n-annotation[a8n-target/a8n-offset/number() gt $offset]

return
    
    (xmldb:store($annotation-collection-path,  concat($new-annotation/@xml:id, '.xml'), $new-annotation)
    ,
    for $feature-annotation in $feature-annotations
    let $revised-annotation := il2so:insert-elements($feature-annotation, $version-difference, 'a8n-offset', 'after')
    return
        (
            xmldb:store($annotation-collection-path,  concat($feature-annotation/@xml:id, '.xml'), $revised-annotation)
        )
    )