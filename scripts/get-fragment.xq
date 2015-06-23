xquery version "3.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function local:get-common-ancestor( $element as element(),
                                            $start-element-name as xs:string,
                                            $start-attribute-name as xs:string,
                                            $start-attribute-value as xs:string,
                                            $end-element-name as xs:string,
                                            $end-attribute-name as xs:string,
                                            $end-attribute-value as xs:string)
as element()
{
    let $element :=
        ($element//*[local-name(.) eq $start-element-name][@*[local-name(.) eq $start-attribute-name] eq $start-attribute-value]/ancestor::* 
            intersect 
        $element//*[local-name(.) eq $end-element-name][@*[local-name(.) eq $end-attribute-name] eq $end-attribute-value]/ancestor::*)
        [last()]
    return
        $element
};

(: the function return a fragment between two element nodes, wrapping it in the closest common ancestor (if local:get-common-ancestor() is run) or in all common ancestors:)
declare function local:get-page-from-pb($element as element(), 
                                        $start-element-name as xs:string,
                                        $start-attribute-name as xs:string, 
                                        $start-attribute-value as xs:string,
                                        $end-element-name as xs:string, 
                                        $end-attribute-name as xs:string,
                                        $end-attribute-value as xs:string)
as element()
{
    element { node-name($element) } {
        $element/@*,
        for $child in $element/node()
        return
            if ($child instance of element()) then 
                (: if the start or end node is a descendants of the child, recurse; :)
                (:NB: is end necessary?:)
                if ($child/descendant::tei:*[local-name(.) eq $start-element-name][@*[local-name(.) eq $start-attribute-name] eq $start-attribute-value]
                    or $child/descendant::tei:*[local-name(.) eq $end-element-name][@*[local-name(.) eq $end-attribute-name] eq $end-attribute-value]) 
                then
                    local:get-page-from-pb($child, $start-element-name, $start-attribute-name, $start-attribute-value, $end-element-name, $end-attribute-name, $end-attribute-value)
                (: if the start node precedes the child, recurse; if the end node follows the child, recurse :)
                else 
                    if ($child/preceding::tei:*[local-name(.) eq $start-element-name][@*[local-name(.) eq $start-attribute-name] eq $start-attribute-value] and $child/following::tei:*[local-name(.) eq $end-element-name][@*[local-name(.) eq $end-attribute-name] eq $end-attribute-value])
                    then
                        local:get-page-from-pb($child, $start-element-name, $start-attribute-name, $start-attribute-value, $end-element-name, $end-attribute-name, $end-attribute-value)
                    else ()
            else
                if ($child instance of text()) 
                then
                    (:if the text follows the start node or precedes the end node, include it:)
                    if (($child/following-sibling::tei:*[local-name(.) eq $start-element-name][@*[local-name(.) eq $start-attribute-name] eq $start-attribute-value]) or ($child/preceding-sibling::tei:*[local-name(.) eq $end-element-name][@*[local-name(.) eq $end-attribute-name] eq $end-attribute-value]))
                    then ()
                else
                    if ($child/preceding::tei:*[local-name(.) eq $start-element-name][@*[local-name(.) eq $start-attribute-name] eq $start-attribute-value] or $child/following::tei:*[local-name(.) eq $end-element-name][@*[local-name(.) eq $end-attribute-name] eq $end-attribute-value]) 
                    then
                        $child
                    else ()
            else
                (:pass through comments and PIs:)
                $child
    }
};

let $start-element-name := 'pb'
let $start-attribute-name := 'n'
let $start-attribute-value := '7'
let $end-element-name := 'pb'
let $end-attribute-name := 'n'
let $end-attribute-value := '8'

let $doc := doc('/db/eebo/A00283.xml')/tei:TEI
let $doc := local:get-common-ancestor($doc, $start-element-name, $start-attribute-name, $start-attribute-value, $end-element-name, $end-attribute-name, $end-attribute-value)

return
    local:get-page-from-pb($doc, $start-element-name, $start-attribute-name, $start-attribute-value, $end-element-name, $end-attribute-name, $end-attribute-value)

(:util:get-fragment-between($beginning-node as node()?, $ending-node as node()?, $make-fragment as xs:boolean?, $display-root-namespace as xs:boolean?) as xs:string:)

(:    util:get-fragment-between($doc//tei:pb[@n eq "6"], $doc//tei:pb[@n eq "7"], true(), true()):)