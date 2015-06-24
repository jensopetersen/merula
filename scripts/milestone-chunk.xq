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

declare function local:get-fragment(
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
                (:the xml attributes that govern their descendants are carried over to the fragment; 
                if the fragment has several layers before it reaches text nodes, this information is duplicated, but this does no harm:)
                if ($node/@xml:base)
                then attribute{'xml:base'}{$node/@xml:base}
                else 
                    if ($node/ancestor::*/@xml:base)
                    then attribute{'xml:base'}{$node/ancestor::*/@xml:base[1]}
                    else (),
                if ($node/@xml:space)
                then attribute{'xml:space'}{$node/@xml:space}
                else
                    if ($node/ancestor::*/@xml:space)
                    then attribute{'xml:space'}{$node/ancestor::*/@xml:space[1]}
                    else (),
                if ($node/@xml:lang)
                then attribute{'xml:lang'}{$node/@xml:lang}
                else
                    if ($node/ancestor::*/@xml:lang)
                    then attribute{'xml:lang'}{$node/ancestor::*/@xml:lang[1]}
                    else ()
                ,
                (:recurse:)
                for $node in $node/node()
                return local:get-fragment($node, $start-node, $end-node, $include-start-and-end-nodes) }
        else
        (:if an element follows the start-node or precedes the end-note, carry it over:)
        if ($node >> $start-node and $node << $end-node)
        then $node
        else ()
    default return
        (:if a text, comment or PI node follows the start-node or precedes the end-node, carry it over:)
        if ($node >> $start-node and $node << $end-node)
        then $node
        else ()
};

declare function local:get-fragment-from-doc(
    $node as node()*,
    $start-node as element(),
    $end-node as element(),
    $wrap-in-common-ancestor-only as xs:boolean,
    $include-start-and-end-nodes as xs:boolean
) as node()*
{
    if ($node instance of element())
    then
        let $node :=
            if ($wrap-in-common-ancestor-only)
            then local:get-common-ancestor($node, $start-node, $end-node)
            else $node
            return
                local:get-fragment($node, $start-node, $end-node, $include-start-and-end-nodes)
    else 
        if ($node instance of document-node())
        then local:get-fragment-from-doc($node/element(), $start-node, $end-node, $wrap-in-common-ancestor-only, $include-start-and-end-nodes)
        else ()
        
};

let $input := doc('/db/eebo/A00283.xml')

return
    local:get-fragment-from-doc($input, $input//tei:pb[@n="7"], $input//tei:pb[@n="8"], true(), true())
  
(:    util:get-fragment-between($input//tei:pb[@n eq "7"], $input//tei:pb[@n eq "8"], true(), true()):)