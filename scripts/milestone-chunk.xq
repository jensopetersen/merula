xquery version "3.0";

(: based on function by David Sewell; http://wiki.tei-c.org/index.php/Milestone-chunk.xquery#Extended_version_which_keeps_the_namespace_declaration:)

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function local:get-common-ancestor($element as element(), $start-node as node(), $end-node as node())
as element()
{
    let $element :=
        ($element//*[. is $start-node]/ancestor::* intersect $element//*[. is $end-node]/ancestor::*)[last()]
    return
        $element
};

declare function local:milestone-chunk(
    $node as node()*,
    $start-node as element(),
    $end-node as element(),
    $include-start-and-end-nodes as xs:boolean
) as node()*
{
    typeswitch ($node)
    case element() return
        if ($node is $start-node or $node is $end-node)
        then
            if ($include-start-and-end-nodes)
            then $node
            else ()
        else
            if (some $node in $node/descendant::* satisfies ($node is $start-node or $node is $end-node))
            then
                element {node-name($node)}
                {
                if ($node/ancestor::*/@xml:base) then attribute{'xml:base'}{$node/ancestor::*/@xml:base[1]} else (),
                if ($node/ancestor::*/@xml:space) then attribute{'xml:space'}{$node/ancestor::*/@xml:space[1]} else (),
                if ($node/ancestor::*/@xml:lang) then attribute{'xml:lang'}{$node/ancestor::*/@xml:lang[1]} else (),
                for $node in $node/node()
                return local:milestone-chunk($node, $start-node, $end-node, $include-start-and-end-nodes) }
            else
                if ($node >> $start-node and $node << $end-node)
                then $node
                else ()
    case attribute() return 
        $node (: will never match attributes outside non-returned elements :)
    default return
        if ( $node >> $start-node and $node << $end-node ) 
        then $node
        else ()
};

declare function local:get-chunk(
    $node as node()*,
    $start-node as element(),
    $end-node as element(),
    $common-ancestor-only as xs:boolean,
    $include-start-and-end as xs:boolean
) as node()*
{
    let $node :=
        if ($common-ancestor-only)
        then local:get-common-ancestor($node, $start-node, $end-node)
        else $node
        return
            local:milestone-chunk($node, $start-node, $end-node, $include-start-and-end)
};

let $input := doc('/db/eebo/A00283.xml')/tei:TEI

return
    local:get-chunk($input, $input//tei:pb[@n="8"], $input//tei:pb[@n="10"], true(), true())
  
(:    util:get-fragment-between($input//tei:pb[@n eq "7"], $input//tei:pb[@n eq "8"], true(), true()):)