xquery version "3.0";

module namespace in-mem-ops = "http://exist-db.org/apps/mopane/in-mem-ops";

(: This function facilitates several operations on elements. The parameters passed are 1) the node tree to be operated on, 2) any new item(s) to be inserted, 3) the action to be performed, 4) the name(s) of the element(s) targeted by the action. 
 : The function can insert one or more elements supplied as a parameter in a certain position relative to (before or after or as the first or last child of) target elements in the node tree. 
 : One or more elements can be inserted in the same position as the target element(s), i.e. they can substitute for them.
 : If the action is 'remove', the target element(s) are removed. If the action is 'remove-if-empty', the target element(s) are removed if they have no (normalized) string value.  If the action is 'substitute-children-for-parent', the target element(s) are substituted by their child element(s). (In the last three cases the new content parameter is not consulted and should, for clarity, be the empty sequence). 
 : If the action to be taken is 'change-name', the name of the element is changed to the first item of the new content. 
 : If the action to be taken is 'substitute-content', any children of the target element(s) are substituted with the new content. 
 : Note that context-free functions, for instance current-date(), can be passed as new content.:)
 
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

(: This function facilitates several operations on attributes. This is more complicated than working with elements, for element names have to be considered as well.
 : The parameters passed are 1) the node tree to be operated on, 2) a new attribute name, 3) an old attribute name, 4) the new attribute contents, 5) the action to be performed, 6) the name(s) of the element(s) targeted by the action, 7) the name(s) of the attribute(s) targeted by the action. 
 : By just using the action parameter, you can remove all empty-attributes.
 : If you wish to remove all named attributes, you need to supply the name of the attribute to be removed.
 : If you wish to change all values of named attributes, you need to supply the new value as well. 
 : If you wish to attach an attribute, with name and value, to a specific element, you need to supply parameters for the element the attribute is to be attached to, the name of the attribute, and the value of the attribute, as well as the action.
 : If you wish to remove an attribute from a specific element, you need to supply parameters for the element the attribute is to be attached to, the name of the attribute, as well as the action.
 : If you wish to change the name of an attribute attached to a specific element, you need to supply parameters for the element the attribute is attached to, the name the attribute has, the new the attribute is to have, as well as the action.:)

declare function in-mem-ops:change-attributes(
    $node as node(), 
    $new-name as xs:string, 
    $new-content as item(), 
    $action as xs:string, 
    $target-element-names as xs:string+, 
    $target-attribute-names as xs:string+
) as node()* 
{
    
            if ($node instance of element()) 
            then
                element {node-name($node)} 
                {
                    if ($action = 'remove-all-empty-attributes')
                    then $node/@*[string-length(.) ne 0]
                    else 
                        
                    if ($action = 'remove-all-named-attributes')
                    then $node/@*[name(.) != $target-attribute-names]
                    else 
                    
                    if ($action = 'change-all-values-of-named-attributes')
                    then element {node-name($node)}
                    {for $att in $node/@*
                        return 
                            if (name($att) = $target-attribute-names)
                            then attribute {name($att)} {$new-content}
                            else attribute {name($att)} {$att}
                    }
                    else
                        
                    if ($action = 'attach-attribute-to-element' and name($node) = $target-element-names)
                    then ($node/@*, attribute {$new-name} {$new-content})
                    else 

                    if ($action = 'remove-attribute-from-element' and name($node) = $target-element-names)
                    then $node/@*[name(.) != $target-attribute-names]
                    else 

                    if ($action = 'change-attribute-name-on-element' and name($node) = $target-element-names)
                    then 
                        for $att in $node/@*
                            return
                                if (name($att) = $target-attribute-names)
                                then attribute {$new-name} {$att}
                                else attribute {name($att)} {$att}
                    else
                    
                    if ($action = 'change-attribute-value-on-element' and name($node) = $target-element-names)
                    then
                        for $att in $node/@*
                            return 
                                if (name($att) = $target-attribute-names)
                                then attribute {name($att)} {$new-content}
                                else attribute {name($att)} {$att}
                    else 

                    $node/@*
                    ,
                    for $child in $node/node()
                        return 
                            in-mem-ops:change-attributes($child, $new-name, $new-content, $action, $target-element-names, $target-attribute-names) 
                }
            else $node
};