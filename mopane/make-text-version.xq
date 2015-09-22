xquery version "3.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare boundary-space preserve;

declare variable $in-collection := '/db/test/in';
declare variable $out-collection := '/db/test/out';

declare function local:make-text-version($element as element(), $version as xs:string, $wit as xs:string?)
as element()
{
    element { node-name($element) } {
        $element/@*,
        for $child in $element/node()
        return
            if ($child instance of element()) 
            then
                if ($child instance of element(tei:app)) 
                then
                    if ($version eq 'target-text')
                    then
                        (:NB: no elements allowed in lem:)
                        $child/tei:lem/text()
                    else
                        if ($version eq 'base-text')
                        then 
                            (:NB: no elements allowed in lem or rdg:)
                            $child/tei:*[@wit eq $wit]/text()
                        else ()
                else
                    local:make-text-version($child, $version, $wit)
            else
                $child
    }
};

let $version := 'base-text'
let $wit := 'Shisan-1816'
let $in-doc-title := 'CHANT-0880-app.xml'
let $out-doc-title := 'CHANT-0880-app-base.xml'
let $doc := doc(concat($in-collection, '/', $in-doc-title))
let $doc-element := $doc/element()
let $doc-header := $doc-element/tei:teiHeader
let $doc-text := $doc-element/tei:text
(:let $log := util:log("DEBUG", ("##$doc-text-1): ", $doc-text)):)
let $doc-text := local:make-text-version($doc-text, $version, $wit)
(:let $log := util:log("DEBUG", ("##$doc-text-2): ", $doc-text)):)
let $result := element {node-name($doc-element)}{$doc-element/@*, $doc-header, $doc-text}
(:let $result := <export>{$doc-text}</export>:)
let $log := util:log("DEBUG", ("##$result): ", $result))
	return 
		xmldb:store($out-collection, $out-doc-title, $result)