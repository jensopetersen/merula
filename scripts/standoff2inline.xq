xquery version "3.0";

(: Inserts elements supplied at a certain position (identity transform) :)
declare function local:insert-element($node as node()?, $new-node as node(), 
    $element-name-to-check as xs:string, $location as xs:string) {
        if (local-name($node) eq $element-name-to-check)
        then
            if ($location eq 'before')
            then ($new-node, $node) 
            else 
                if ($location eq 'after')
                then ($node, $new-node)
                else
                    if ($location eq 'first-child')
                    then element {node-name($node)}
                        {
                            $node/@*
                            ,
                            $new-node
                            ,
                            for $child in $node/node()
                                return  $child
                        }
                    else
                        if ($location eq 'last-child')
                        then element {node-name($node)}
                            {
                                $node/@*
                                ,
                                for $child in $node/node()
                                    return $child 
                                ,
                                $new-node
                            }
                        else () (:The $element-to-check is removed if none of the four options are used.:)
        else
            if ($node instance of element()) 
            then
                element {node-name($node)} {
                    $node/@*
                    , 
                    for $child in $node/node()
                        return 
                            local:insert-element($child, $new-node, $element-name-to-check, $location) 
            }
         else $node
};

declare function local:remove-elements($nodes as node()*, $remove as xs:anyAtomicType+)  as node()* {
   for $node in $nodes
   return
     if ($node instance of element())
     then 
        if ((local-name($node) = $remove))
        then ()
        else element {node-name($node)}
                {$node/@*,
                  local:remove-elements($node/node(), $remove)}
     else 
        if ($node instance of document-node())
        then local:remove-elements($node/node(), $remove)
        else $node
} ;

declare function local:build-up-annotations($top-level-critical-annotations as element()+, $annotations as element()) as element()* {
    for $annotation in $top-level-critical-annotations
    let $annotation-id := $annotation/@xml:id
    let $annotation-element-name := local-name($annotation//body/*)
    let $children :=
            $annotations/annotation[target/annotation-layer/id = $annotation-id]
    let $children :=
                <children>
                {
                    for $child in $children
                    let $child-id := $annotation/@xml:id/string()
                    let $log := util:log("DEBUG", ("##$child-id): ", $child-id))
                        return
                            if ($annotations/annotation[target/annotation-layer/id = $child-id]) (:something is wrong here - this does not catch cases where there is a further annotation, leaving empty <children> at dead ends:)
                            then local:build-up-annotations($child, $annotations)
                            else $child
                }
                </children>
        return 
            local:insert-element($annotation, $children, $annotation-element-name,  'first-child')            
};

declare function local:collapse-annotations($built-up-critical-annotations as element()+) {
    for $annotation in $built-up-critical-annotations
    let $annotation-element-name := local-name($annotation/body/*)
    let $log := util:log("DEBUG", ("##$annotation-element-name): ", $annotation-element-name))
    let $children := 
        for $child in $annotation/body/*/children/*
        let $child := $child/body
            return $child
    let $log := util:log("DEBUG", ("##$children): ", $children))
    let $bare := local:remove-elements($annotation, 'children')
    let $full := local:insert-element($bare, $children, $annotation-element-name,  'first-child')
        return 
            $full
};

let $base-text := <p xml:id="uuid-8227bf23-decc-3181-aed6-4148e2121d25">I meet Stephen Winwood and Alexis Korner in the pub.</p>
            
let $hoped-for-result := <p xml:id="uuid-af570732-2121-30d0-8b05-f53bad3fa04f">I met Steve Winwood and John Mayall in the pub.</p>
            
let $annotations := <annotations><annotation type="element" xml:id="uuid-4abd36a7-d505-4adc-91a3-a66a6cc9c9bc" status="token"><target type="range" layer="edition"><base-layer><id>uuid-538a6e13-f88b-462c-a965-f523c3e02bbf</id><start>3</start><offset>4</offset></base-layer><authoritative-layer><id>uuid-5f44133c-728d-30a5-a296-c5603f5218c3></id><start>3</start><offset>3</offset></authoritative-layer></target><body><choice/></body><layer-offset-difference>-1</layer-offset-difference></annotation><annotation type="element" xml:id="uuid-779d9ea8-25a9-4eb3-9312-9dcabfd4a52f" status="token"><target type="element" layer="annotation"><annotation-layer><id>uuid-4abd36a7-d505-4adc-91a3-a66a6cc9c9bc</id><order>1</order></annotation-layer></target><body><reg>met</reg></body></annotation><annotation type="element" xml:id="uuid-8f8950c1-c0cd-4259-8125-7c8a761f996b" status="token"><target type="element" layer="annotation"><annotation-layer><id>uuid-4abd36a7-d505-4adc-91a3-a66a6cc9c9bc</id><order>2</order></annotation-layer></target><body><sic>meet</sic></body></annotation><annotation type="element" xml:id="uuid-a17fe03e-ac7d-45d8-92ef-f0917164c94c" status="token"><target type="range" layer="edition"><base-layer><id>uuid-538a6e13-f88b-462c-a965-f523c3e02bbf</id><start>8</start><offset>15</offset></base-layer><authoritative-layer><id>uuid-5f44133c-728d-30a5-a296-c5603f5218c3></id><start>7</start><offset>13</offset></authoritative-layer></target><body><app/></body><layer-offset-difference>-2</layer-offset-difference></annotation><annotation type="element" xml:id="uuid-7e50d3e0-f4e2-4a8d-89a0-1421c50032ba" status="token"><target type="element" layer="annotation"><annotation-layer><id>uuid-a17fe03e-ac7d-45d8-92ef-f0917164c94c</id><order>1</order></annotation-layer></target><body><lem wit="#a"/></body></annotation><annotation type="element" xml:id="uuid-f12feba1-ef16-4a6a-ab13-c41f5dfaf42e" status="token"><target type="element" layer="annotation"><annotation-layer><id>uuid-7e50d3e0-f4e2-4a8d-89a0-1421c50032ba</id><order>1</order></annotation-layer></target><body><name ref="#SW" type="person"/></body></annotation><annotation type="element" xml:id="uuid-0f3e2942-7f86-4a85-a3ae-72d42e57306b" status="token"><target type="element" layer="annotation"><annotation-layer><id>uuid-f12feba1-ef16-4a6a-ab13-c41f5dfaf42e</id><order>1</order></annotation-layer></target><body><forename>Steve</forename></body></annotation><annotation type="element" xml:id="uuid-7a124001-e642-4c30-b381-8b787b2bec3c" status="token"><target type="element" layer="annotation"><annotation-layer><id>uuid-f12feba1-ef16-4a6a-ab13-c41f5dfaf42e</id><order>2</order></annotation-layer></target><body><surname>Winwood</surname></body></annotation><annotation type="element" xml:id="uuid-018636fc-c659-4426-a2eb-11863365465d" status="token"><target type="element" layer="annotation"><annotation-layer><id>uuid-a17fe03e-ac7d-45d8-92ef-f0917164c94c</id><order>2</order></annotation-layer></target><body><rdg wit="#b"/></body></annotation><annotation type="element" xml:id="uuid-5bcb9234-6d17-4416-98cc-416698c916ba" status="token"><target type="element" layer="annotation"><annotation-layer><id>uuid-018636fc-c659-4426-a2eb-11863365465d</id><order>1</order></annotation-layer></target><body><name ref="#SW" type="person"/></body></annotation><annotation type="element" xml:id="uuid-f5b5cdc3-a9de-41a4-988b-6cb7b1d93a29" status="token"><target type="element" layer="annotation"><annotation-layer><id>uuid-5bcb9234-6d17-4416-98cc-416698c916ba</id><order>1</order></annotation-layer></target><body><forename>Stephen</forename></body></annotation><annotation type="element" xml:id="uuid-9a566fff-274e-4d03-8046-d7508612edb4" status="token"><target type="element" layer="annotation"><annotation-layer><id>uuid-5bcb9234-6d17-4416-98cc-416698c916ba</id><order>2</order></annotation-layer></target><body><surname>Winwood</surname></body></annotation><annotation type="element" xml:id="uuid-eb6bbeaa-75f4-4b3d-8dfe-312ca12cbacc" status="token"><target type="range" layer="edition"><base-layer><id>uuid-538a6e13-f88b-462c-a965-f523c3e02bbf</id><start>28</start><offset>13</offset></base-layer><authoritative-layer><id>uuid-5f44133c-728d-30a5-a296-c5603f5218c3></id><start>25</start><offset>11</offset></authoritative-layer></target><body><app/></body><layer-offset-difference>-2</layer-offset-difference></annotation><annotation type="element" xml:id="uuid-06c94ca9-5795-4868-8192-8a2128703113" status="token"><target type="element" layer="annotation"><annotation-layer><id>uuid-eb6bbeaa-75f4-4b3d-8dfe-312ca12cbacc</id><order>1</order></annotation-layer></target><body><rdg wit="#base"/></body></annotation><annotation type="element" xml:id="uuid-27091a6a-1ff6-42cd-99a3-3bb809e0bbc3" status="token"><target type="element" layer="annotation"><annotation-layer><id>uuid-06c94ca9-5795-4868-8192-8a2128703113</id><order>1</order></annotation-layer></target><body><name ref="#AK" type="person">Alexis Korner</name></body></annotation><annotation type="element" xml:id="uuid-8438215a-30ae-48e8-b3c0-33f200ea6745" status="token"><target type="element" layer="annotation"><annotation-layer><id>uuid-eb6bbeaa-75f4-4b3d-8dfe-312ca12cbacc</id><order>2</order></annotation-layer></target><body><rdg wit="#c"/></body></annotation><annotation type="element" xml:id="uuid-d8ae2c43-4f9f-46d1-bc07-b9d3122801b7" status="token"><target type="element" layer="annotation"><annotation-layer><id>uuid-8438215a-30ae-48e8-b3c0-33f200ea6745</id><order>1</order></annotation-layer></target><body><name ref="#JM" type="person">John Mayall</name></body></annotation><annotation type="element" xml:id="uuid-fa784d06-4eb0-42e9-9a6c-9c480b54f87a" status="string"><target type="range" layer="feature"><base-layer><id>uuid-538a6e13-f88b-462c-a965-f523c3e02bbf</id><start>41</start><offset>0</offset></base-layer><authoritative-layer><id>uuid-5f44133c-728d-30a5-a296-c5603f5218c3></id><start>36</start><offset>0</offset></authoritative-layer></target><body><pb n="3"/></body><layer-offset-difference>0</layer-offset-difference></annotation><annotation type="element" xml:id="uuid-b85a56fb-6d78-42c0-9533-dd399306f793" status="token"><target type="range" layer="feature"><base-layer><id>uuid-538a6e13-f88b-462c-a965-f523c3e02bbf</id><start>45</start><offset>7</offset></base-layer><authoritative-layer><id>uuid-5f44133c-728d-30a5-a296-c5603f5218c3></id><start>40</start><offset>7</offset></authoritative-layer></target><body><rs>the pub</rs></body><layer-offset-difference>0</layer-offset-difference></annotation><annotation type="element" xml:id="uuid-4ae90f43-95f9-47c2-8fdd-20f9ee210457" status="string"><target type="range" layer="feature"><base-layer><id>uuid-538a6e13-f88b-462c-a965-f523c3e02bbf</id><start>51</start><offset>0</offset></base-layer><authoritative-layer><id>uuid-5f44133c-728d-30a5-a296-c5603f5218c3></id><start>46</start><offset>0</offset></authoritative-layer></target><body><note resp="#JØP"/></body><layer-offset-difference>0</layer-offset-difference></annotation><annotation type="text" xml:id="uuid-0b9c587b-2d3c-47d1-a5c3-2ece39790db8" status="token"><target type="range" layer="text"><base-layer><id>uuid-4ae90f43-95f9-47c2-8fdd-20f9ee210457</id><start>1</start><offset>14</offset></base-layer></target><body>The author is </body></annotation><annotation type="element" xml:id="uuid-698789b1-7df5-4730-b51a-193d31152b8e" status="token"><target type="range" layer="feature"><base-layer><id>uuid-4ae90f43-95f9-47c2-8fdd-20f9ee210457</id><start>15</start><offset>9</offset></base-layer></target><body><emph/></body></annotation><annotation type="text" xml:id="uuid-9117307c-9769-4f5b-8feb-c3600338ff5a" status="string"><target type="range" layer="text"><base-layer><id>uuid-698789b1-7df5-4730-b51a-193d31152b8e</id><start>1</start><offset>4</offset></base-layer></target><body>pro-</body></annotation><annotation type="element" xml:id="uuid-5fc67ed3-4f41-4781-b63c-8e296c7f0deb" status="string"><target type="range" layer="feature"><base-layer><id>uuid-698789b1-7df5-4730-b51a-193d31152b8e</id><start>4</start><offset>0</offset></base-layer></target><body><pb n="3"/></body></annotation><annotation type="text" xml:id="uuid-114d21ca-b04d-4c7a-b731-cbfeb30db1f6" status="token"><target type="range" layer="text"><base-layer><id>uuid-698789b1-7df5-4730-b51a-193d31152b8e</id><start>5</start><offset>5</offset></base-layer></target><body>bably</body></annotation><annotation type="text" xml:id="uuid-05553dfa-8fe9-4b2c-b98c-d9ef1714ee13" status="token"><target type="range" layer="text"><base-layer><id>uuid-4ae90f43-95f9-47c2-8fdd-20f9ee210457</id><start>15</start><offset>12</offset></base-layer></target><body> wrong here.</body></annotation></annotations>

let $top-level-critical-annotations := $annotations/annotation[target/@type eq 'range'][target/@layer eq 'edition']
let $built-up-annotations := local:build-up-annotations($top-level-critical-annotations, $annotations)
(:let $collapsed-annotations := local:collapse-annotations($built-up-annotations):)
return $built-up-annotations