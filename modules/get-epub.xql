xquery version "3.0";

import module namespace config="http://exist-db.org/apps/shakes/config" at "config.xqm";
import module namespace epub="http://exist-db.org/xquery/epub" at "epub.xql";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare option exist:serialize "method=xml media-type=text/xml";

declare function local:work2epub($id as xs:string, $work as element()) {
    let $root := $work/ancestor-or-self::tei:TEI
    let $fileDesc := $root/tei:teiHeader/tei:fileDesc
    let $title := $fileDesc/tei:titleStmt/tei:title/string()
    let $creator := $fileDesc/tei:titleStmt/tei:author/string()
    let $text := $root/tei:text/tei:body
    let $urn := util:uuid()
    return
        epub:generate-epub($title, $creator, $root, $urn, $config:app-root || "/resources/css/epub.css", $id)
};

let $id := request:get-parameter("id", ())
let $work := collection($config:data)//id($id)
let $entries := local:work2epub($id, $work)
return
    (
        response:set-header("Content-Disposition", concat("attachment; filename=", concat($id, '.epub')))
        ,
        response:stream-binary(
            compression:zip( $entries, true() ),
            'application/epub+zip',
            concat($id, '.epub')
        )
    )