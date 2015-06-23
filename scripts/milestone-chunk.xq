xquery version "3.0";

(: based on http://wiki.tei-c.org/index.php/Milestone-chunk.xquery#Extended_version_which_keeps_the_namespace_declaration:)

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

declare function local:milestone-chunk(
  $node as node()*,
  $start-node as element(),
  $end-node as element()
) as node()*
{
  typeswitch ($node)
    case element() return
      if ($node is $start-node or $node is $end-node) 
      then $node (:should the milestones be returned at all?:)
      else 
          if (some $node in $node/descendant::* satisfies ($node is $start-node or $node is $end-node))
          then
              element {QName (namespace-uri($node), name($node))}
                { for $i in ( $node/node() | $node/@* )
                  return local:milestone-chunk($i, $start-node, $end-node) }
                  else
                      if ( $node >> $start-node and $node << $end-node ) 
                      then $node
                      else ()
    case attribute() return $node (: will never match attributes outside non-returned elements :)
    default return 
        if ( $node >> $start-node and $node << $end-node ) 
        then $node
        else ()
};
declare function local:get-chunk(
  $node as node()*,
  $start-node as element(),
  $end-node as element(),
  $common-ancestor as xs:boolean
) as node()*
{
  let $node :=
    if ($common-ancestor)
    then local:get-common-ancestor($node, $start-node, $end-node)
    else $node
    return
        local:milestone-chunk($node, $start-node, $end-node)
};

let $input := doc('/db/eebo/A00283.xml')/tei:TEI

return
    local:get-chunk($input, $input//tei:pb[@n="7"], $input//tei:pb[@n="8"], true())
  
(:    util:get-fragment-between($input//tei:pb[@n eq "7"], $input//tei:pb[@n eq "8"], true(), true()):)