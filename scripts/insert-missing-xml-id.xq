xquery version "3.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $out-collection := 'xmldb:exist:///db/test/out';

declare function local:insert-missing-xml-id($element as element()) as element() {
   element {node-name($element)}
      {$element/@*,
        for $child in $element/node()
            return
                if ($child instance of element())
                then 
                    if ($child/@xml:id)
                    then local:insert-missing-xml-id($child)
                    else local:insert-missing-xml-id(
                        element {node-name($child)}
                        {attribute {'xml:id'} {concat("uuid-",util:uuid())},
                        $child/@*, $child/node()}
                    )
                else $child
      }
};
let $doc-title := 'sample_MTDP10363.xml'
let $doc := doc(concat('/db/test/in/', $doc-title))/*
(: http://www.marktwainproject.org/sample_MTDP10363.xml:)
let $doc:= element{node-name($doc)}{($doc/@*, $doc/tei:teiHeader, local:insert-missing-xml-id($doc/tei:text))}
(: NB: how can one maintain unused namepsaces?:)
    return xmldb:store($out-collection, $doc-title, $doc)