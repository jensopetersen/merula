xquery version "3.0";

(:local:buildTree() and local:getLevel(): code by Jens Erat, https://stackoverflow.com/questions/21527660.:)
(:$base-text-elements: code based on code by Jens Erat, https://stackoverflow.com/questions/20729593.:)

declare namespace in-mem-ops = "http://exist-db.org/apps/mopane/in-mem-ops";
declare namespace functx = "http://www.functx.com"; 

declare function functx:path-to-node 
  ( $nodes as node()* )  as xs:string* {
       
$nodes/string-join(ancestor-or-self::*/name(.), '/')
 } ;

declare function in-mem-ops:change-elements(
    $node as node(), 
    $new-content as item()*, 
    $action as xs:string, 
    $target-element-names as xs:string+
) as node()* 
{        
        if ($node instance of element() and local-name($node) = $target-element-names)
        then

            if ($action eq 'insert-before')
            then ($new-content, $node) 
            else
            
            if ($action eq 'insert-after')
            then ($node, $new-content)
            else
            
            if ($action eq 'insert-as-first-child')
            then element {node-name($node)}
                {
                $node/@*
                ,
                $new-content
                ,
                for $child in $node/node()
                    return $child
                }
            else
            
            if ($action eq 'insert-as-last-child')
            then element {node-name($node)}
                {
                $node/@*
                ,
                for $child in $node/node()
                    return $child 
                ,
                $new-content
                }
            else
                
            if ($action eq 'substitute')
            then $new-content
            else 
                
            if ($action eq 'remove')
            then ()
            else 
                
            if ($action eq 'remove-if-empty')
            then
                if (normalize-space($node) eq '')
                then ()
                else $node
            else

            if ($action eq 'substitute-children-for-parent')
            then $node/*
            else
            
            if ($action eq 'substitute-content')
            then
                element {name($node)}
                    {$node/@*,
                $new-content}
            else
                
            if ($action eq 'change-name')
            then
                element {$new-content[1]}
                    {$node/@*,
                for $child in $node/node()
                    return $child}
            else ()
        
        else
        
            if ($node instance of element()) 
            then
                element {node-name($node)} 
                {
                    $node/@*
                    ,
                    for $child in $node/node()
                        return 
                            in-mem-ops:change-elements($child, $new-content, $action, $target-element-names) 
                }
            else $node
};

declare function local:getLevel($node as element()) as xs:integer {
    $node/@depth
};

declare function local:buildTree($nodes as element()*) as element()* {
    for $node in $nodes
    let $level := local:getLevel($nodes[1])
    (: Find next node of current level, if available :)
    let $next := ($node/following-sibling::*[local:getLevel(.) le $level])[1]
    (: All nodes between the current node and the next node on same level are children :)
    let $children := $node/following-sibling::*[$node << . and (not($next) or . << $next)]
    where $level eq local:getLevel($node)
    return
    element { name($node) } {
      (: Copy node attributes :)
      $node/@*,
      (: Copy all other subnodes, including text, pi, elements, comments :)
      $node/node(),

      (: If there are children, recursively build the subtree :)
      if ($children)
      then local:buildTree($children)
      else ()
    }
};

let $base-text :=
    <tei>
    <text n="x" xml:id="a">
            <div xml:id="b">
                <div xml:id="c">
                    <p xml:id="d">a<inline>a</inline>a</p>
                    <p xml:id="e">b<inline>b</inline>b</p>
                </div>
                <div xml:id="f">
                    <lg xml:id="g">
                        <l xml:id="h">c<inline>c</inline></l>
                        <l xml:id="i"><inline>d</inline>d</l>
                    </lg>
                    <lg xml:id="j">
                        <l xml:id="k">a
                            <inline>e</inline>
                        </l>
                        <l xml:id="l">f<inline>f</inline></l>
                    </lg>
                </div>
            </div>
        </text>
    </tei>

(:let $base-text := doc('/db/test/dilthey.xml'):)

let $block-app := 
<text wit="y">
        <rdg><target>a</target><order>1</order><level>1</level><local-name>text</local-name></rdg>
        <rdg><target>b</target><order>2</order><level>2</level><local-name>div</local-name></rdg>
        <rdg><target>c</target><order>3</order><level>3</level><local-name>div</local-name></rdg>
        <rdg><target>e</target><order>4</order><level>4</level><local-name>p</local-name></rdg>
        <rdg><target>d</target><order>5</order><level>4</level><local-name>p</local-name></rdg>
        <rdg><target>m</target><order>6</order><level>4</level><contents><p xml:id="m">m<inline>m</inline>m</p></contents></rdg>
        <rdg><target>f</target><order>7</order><level>3</level><local-name>div</local-name></rdg>
        <rdg><target>j</target><order>8</order><level>4</level><local-name>lg</local-name></rdg>
        <rdg><target>k</target><order>9</order><level>5</level><local-name>l</local-name></rdg>
        <rdg><target>l</target><order>10</order><level>5</level><local-name>l</local-name></rdg>
    </text>

let $element-only-block-elements := ('body', 'text', 'lg', 'div')
let $empty-block-like-elements := ('pb', 'milestone', 'lb')
let $mixed-contents-block-elements := ('head', 'l', 'p', 'cit', 'fw')

let $base-text-elements :=
    for $element at $i in 
        (
            $base-text//*[local-name(.) = $element-only-block-elements]
                union
            $base-text//*[local-name(./parent::*) = $element-only-block-elements]
        )
        let $child-text-node-exists := 
            if ($element/text()) 
            then 'yes' 
            else 'no'
        let $descendant-text-node-exists := 
            if ($child-text-node-exists eq 'no') 
            then
                if (local-name($element) = ($element-only-block-elements, $empty-block-like-elements))
                then 'no'
                else
                    let $path-to-element := functx:path-to-node($element)
                    let $text-ancestor-elements := functx:path-to-node($element//text())
                    let $text-ancestor-elements := 
                        for $path in $text-ancestor-elements
                            return substring-after($path, $path-to-element)
                    let $text-ancestor-elements := string-join($text-ancestor-elements)
                    let $text-ancestor-elements := tokenize($text-ancestor-elements, '/')
                    let $text-ancestor-elements := distinct-values($text-ancestor-elements)
                        return 
                            if (not($text-ancestor-elements = ($element-only-block-elements, $empty-block-like-elements, $mixed-contents-block-elements)))
                            then 'yes' 
                            else 'no'
                else ()    
                return 
                
                (:either the element has a child text node or all descendant text nodes of the element have ancestors, up to the element node, all of which are all not block-level elements:)
            
                    if (($child-text-node-exists, $descendant-text-node-exists) = 'yes')
                    then element {local-name($element) }{ $element/@*, attribute{'depth'}{count($element/ancestor-or-self::node())-1}, attribute{'order'}{$i}, $element/node()}
                    else element {local-name($element) }{$element/@*, attribute{'depth'}{count($element/ancestor-or-self::node())-1}, attribute{'order'}{$i},  ''} 

let $rdg-in-base-text :=
    for $rdg in $block-app/*
    return $base-text-elements[@xml:id eq $rdg/target]
    (:they have to get the order attribute from the app:)

let $rdg-in-base-text :=
    for $rdg in $rdg-in-base-text
        return element {local-name($rdg) }{$rdg/(@* except @order), attribute{'order'}{$block-app/rdg[target = $rdg/@xml:id/string()]/order},  ''} 

let $base-text-ids :=
    $base-text//@xml:id/string()

let $rdg-not-in-base-text :=
    for $rdg in $block-app/*[not(./target = $base-text-ids)]
    return element {local-name($rdg/contents/*) }{ $rdg/@*, attribute{'depth'}{$rdg/level},  attribute{'order'}{$rdg/order}, $rdg/contents/*}

let $reconstructed-text :=
        <reconstructed-text>{
        for $element in ($rdg-not-in-base-text, $rdg-in-base-text)
        order by number($element/@order)
        return $element
        }</reconstructed-text>

return
    local:buildTree($reconstructed-text/*)