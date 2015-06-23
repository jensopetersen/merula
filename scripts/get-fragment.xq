xquery version "3.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function local:get-common-ancestor($element as element(), $start-node as node(), $end-node as node())
as element()
{
    let $element :=
        (
            $element//*[. is $start-node]/ancestor::* 
                intersect 
            $element//*[. is $end-node]/ancestor::*
        )
        [last()]
    return
        $element
};

(: the function return a fragment between two element nodes, wrapping it in the closest common ancestor (if local:get-common-ancestor() is run) or in all common ancestors:)
declare function local:get-page-from-pb($element as element(), $start-node as node(), $end-node as node())
as element()
{
    element { node-name($element) } {
        $element/@*,
        for $child in $element/node()
        return
            if ($child instance of element()) then 
                (: if the start or end node is a descendants of the child, recurse; :)
                (:NB: is end necessary?:)
                if ($child/descendant::tei:*[. is $start-node]
                    or $child/descendant::tei:*[. is $end-node])
                then
                    local:get-page-from-pb($child, $start-node, $end-node)
                (: if the start node precedes the child, recurse; if the end node follows the child, recurse :)
                else 
                    if ($child/preceding::tei:*[. is $start-node] and $child/following::tei:*[. is $end-node])
                    then
                        local:get-page-from-pb($child, $start-node, $end-node)
                    else ()
            else
                if ($child instance of text()) 
                then
                    (:if the text follows the start node or precedes the end node, include it:)
                    if (($child/following-sibling::tei:*[. is $start-node]) or ($child/preceding-sibling::tei:*[. is $end-node]))
                    then ()
                else
                    if ($child/preceding::tei:*[. is $start-node] or $child/following::tei:*[. is $end-node])
                    then
                        $child
                    else ()
            else
                (:pass through comments and PIs:)
                $child
    }
};

let $doc := doc('/db/eebo/A00283.xml')/tei:TEI
let $doc := local:get-common-ancestor($doc, $doc//tei:pb[@n eq "7"], $doc//tei:pb[@n eq "8"])

return
    local:get-page-from-pb($doc, $doc//tei:pb[@n eq "7"], $doc//tei:pb[@n eq "8"])

(:util:get-fragment-between($beginning-node as node()?, $ending-node as node()?, $make-fragment as xs:boolean?, $display-root-namespace as xs:boolean?) as xs:string:)

(:    util:get-fragment-between($doc//tei:pb[@n eq "6"], $doc//tei:pb[@n eq "7"], true(), true()):)