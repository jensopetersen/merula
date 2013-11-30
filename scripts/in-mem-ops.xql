xquery version "3.0";

module namespace in-mem-ops = "http://exist-db.org/apps/mopane/in-mem-ops";

(: This function facilitates several operations on elements. The parameters passed are 1) the node tree to be operated on, 2) any new item(s) to be inserted, 3) the action to be performed, 4) the name(s) of the element(s) targeted by the action. 
 : The function can insert one or more elements supplied as a parameter in a certain position relative to (before or after or as the first or last child of) target elements in the node tree. 
 : One or more elements can be inserted in the same position as the target element(s), i.e. they can substitute for them.
 : If the action is 'remove', the target element(s) are removed. If the action is 'remove-if-empty', the target element(s) are removed if they have no (normalized) string value.  If the action is 'substitute-children-for-parent', the target element(s) are substituted by their child element(s). (In the last three cases the new content parameter is not consulted and should, for clarity, be the empty sequence). 
 : If the action to be taken is 'change-name', the name of the element is changed to the first item of the new content. 
 : If the action to be taken is 'substitute-content', any children of the target element(s) are substituted with the new content. 
 : Note that context-free functions, for instance current-date(), can be passed as new content.:)
declare function local:change-elements($node as node(), $new-content as item()*, $action as xs:string, $target-element-names as xs:string+) as node()+ {
        
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
                            local:change-elements($child, $new-content, $action, $target-element-names) 
                }
            else $node
};
