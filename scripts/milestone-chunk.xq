xquery version "3.0";

(: based on http://wiki.tei-c.org/index.php/Milestone-chunk.xquery#Extended_version_which_keeps_the_namespace_declaration:)

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function local:milestone-chunk(
  $ms1 as element(),
  $ms2 as element(),
  $node as node()*
) as node()*
{
  typeswitch ($node)
    case element() return
      if ($node is $ms1 or $node is $ms2) 
      then $node (:should the milestones be returned at all?:)
      else 
          if ( some $node in $node/descendant::* satisfies ($node is $ms1 or $node is $ms2) )
          then
              element {QName (namespace-uri($node), name($node))}
                { for $i in ( $node/node() | $node/@* )
                  return local:milestone-chunk($ms1, $ms2, $i) }
                  else
                      if ( $node >> $ms1 and $node << $ms2 ) 
                      then $node
                      else ()
    case attribute() return $node (: will never match attributes outside non-returned elements :)
    default return 
        if ( $node >> $ms1 and $node << $ms2 ) 
        then $node
        else ()
};

let $input := doc('/db/eebo/A00283.xml')/tei:TEI
(:let $input := doc('/db/test/chunk.xml')/tei:TEI/tei:text:)

return
    local:milestone-chunk($input//tei:pb[@n="7"], $input//tei:pb[@n="8"], $input)
  