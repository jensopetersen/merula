xquery version "3.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $in-collection := '/db/test';
declare variable $out-collection := 'xmldb:exist:///db/test/out';

declare function local:insert-missing-xml-id($element as element(), $element-only-block-elements as xs:string+) as element() {
   element {node-name($element)}
      {$element/@*,
        for $child in $element/node()
            return
                if ($child instance of element())
                then 
                    if ($child/@xml:id)
                    then local:insert-missing-xml-id($child, $element-only-block-elements)
                    else 
                        if (local-name($child) = $element-only-block-elements or local-name($child/parent::*) = $element-only-block-elements)
                        then
                            local:insert-missing-xml-id(
                                element {node-name($child)}{attribute {'xml:id'} 
                                {concat("uuid-",util:uuid())},
                                $child/@*, $child/node()},
                                $element-only-block-elements)
                        else $child
                else $child
      }
};

let $element-only-block-elements := ('body', 'text', 'lg', 'div')

let $in-doc-title := 'dilthey.xml'
let $out-doc-title := 'dilthey-id.xml'

let $doc := doc(concat($in-collection, "/", $in-doc-title))/*
let $doc:= element{node-name($doc)}{($doc/@*, $doc/tei:teiHeader, local:insert-missing-xml-id($doc/tei:text, $element-only-block-elements))}

(: NB: how can one maintain unused namepsaces?:)

    return xmldb:store($out-collection, $out-doc-title, $doc)