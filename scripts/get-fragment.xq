xquery version "3.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function local:get-page-from-pb($element as element(), $start-element-name as xs:string,
                                        $start-attribute-name as xs:string, $start-attribute-value as xs:string,
                                        $end-element-name as xs:string, $end-attribute-name as xs:string,
                                        $end-attribute-value as xs:string)
as element()
{
(:    let $element :=:)
(:        ($element/descendant-or-self::tei:*[local-name(.) eq $start-element-name][@*[local-name(.) eq:)
(:            $start-attribute-name] eq $start-attribute-value]/ancestor::* intersect:)
(:            $element/descendant::tei:*[local-name(.) eq $end-element-name][@*[local-name(.) eq $end-attribute-name] eq:)
(:            $end-attribute-value]/ancestor::*)[last()]:)
(:    return:)
        element { node-name($element) } {
            $element/@*,
            for $child in $element/node()
            return
                if ($child instance of element()) then
                    (:if the start or end position is below the child, recurse; :)
                    if ($child/descendant::tei:*[local-name(.) eq $start-element-name][@*[local-name(.) eq
                        $start-attribute-name] eq $start-attribute-value] or $child/descendant::tei:*[local-name(.) eq
                        $end-element-name][@*[local-name(.) eq $end-attribute-name] eq $end-attribute-value]) then
                        local:get-page-from-pb($child, $start-element-name, $start-attribute-name,
                                               $start-attribute-value, $end-element-name, $end-attribute-name,
                                               $end-attribute-value)
                    (:if the start position is before the child and the child has a parent, recurse; if the end position is after the child and the child has a parent, recurse:)
                    (:NB: is parent necessary?:)
                    else if ($child/preceding::tei:*[local-name(.) eq $start-element-name][@*[local-name(.) eq
                        $start-attribute-name] eq $start-attribute-value]/parent::* and
                        $child/following::tei:*[local-name(.) eq $end-element-name][@*[local-name(.) eq
                        $end-attribute-name] eq $end-attribute-value]/parent::*) then
                        local:get-page-from-pb($child, $start-element-name, $start-attribute-name,
                                               $start-attribute-value, $end-element-name, $end-attribute-name,
                                               $end-attribute-value)
                    else
                        ()
                else if ($child instance of text()) then
                    if (($child/following-sibling::tei:*[local-name(.) eq $start-element-name][@*[local-name(.) eq
                        $start-attribute-name] eq $start-attribute-value]) or
                        ($child/preceding-sibling::tei:*[local-name(.) eq $end-element-name][@*[local-name(.) eq
                        $end-attribute-name] eq $end-attribute-value])) then
                        ()
                    else if ($child/preceding::tei:*[local-name(.) eq $start-element-name][@*[local-name(.) eq
                        $start-attribute-name] eq $start-attribute-value] or $child/following::tei:*[local-name(.) eq
                        $end-element-name][@*[local-name(.) eq $end-attribute-name] eq $end-attribute-value]) then
                        $child
                    else
                        ()
                else
                    ()
        }
};



(:
Could also restrict to common ancestor:
($v1/ancestor::* intersect $v2/ancestor::*)[last()]
:)

(:util:get-fragment-between($beginning-node as node()?, $ending-node as node()?, :)
(:$make-fragment as xs:boolean?, $display-root-namespace as xs:boolean?) as xs:)
(::string:)
(:Obviously, it is assumed that the two nodes are in the same document!:)

(:let $doc := doc('/db/common-ancestor.xml')/*:)
let $doc := doc('/db/eebo/A00283.xml')/tei:TEI

return
    local:get-page-from-pb($doc, "pb", "n", "7", "pb", "n", "8")
(:    local:get-page-from-pb($doc, "pb", "n", "7", "pb", "n", "8"):)
(:    parse-xml(util:get-fragment-between($doc//tei:pb[@n eq "6"], $doc//tei:pb[@n eq "7"], true(), true())):)