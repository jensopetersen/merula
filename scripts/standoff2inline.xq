xquery version "3.0";

(: Inserts elements supplied at a certain position (identity transform) :)
declare function local:insert-or-remove-nodes($node as node(), $new-nodes as node()*, $element-names-to-check as xs:string+, $location as xs:string) {
        if (local-name($node) = $element-names-to-check)
        then
            if ($location eq 'before')
            then ($new-nodes, $node) 
            else 
                if ($location eq 'after')
                then ($node, $new-nodes)
                else
                    if ($location eq 'first-child')
                    then element {node-name($node)}
                        {
                            $node/@*
                            ,
                            $new-nodes
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
                                $new-nodes
                            }
                        else () (:The $element-to-check is removed if none of the four options, e.g. 'remove', are used.:)
        else
            if ($node instance of element()) 
            then
                element {node-name($node)} {
                    $node/@*
                    , 
                    for $child in $node/node()
                        return 
                            local:insert-or-remove-nodes($child, $new-nodes, $element-names-to-check, $location) 
            }
            else $node
};

declare function local:collapse-annotation($element as element(), $strip as xs:string+) as element() {
    element {node-name($element)}
    {$element/@*,
        for $child in $element/node()
            return
                if ($child instance of element() and local-name($child) = $strip)
                then for $child in $child/* 
                    return 
                        local:collapse-annotation(($child), $strip)
                else
                    if ($child instance of element() and local-name($child) = ('layer-offset-difference', 'authoritative-layer')) (:we have no need for these two elements:)
                    then ()
                    else
                        if ($child instance of element() and local-name($child) = 'target' and local-name($child/parent::element()) ne 'annotation') (:remove all targets that not at the base level:)
                        then ()
                        else
                            if ($child instance of element() and local-name($child/..) = ('lem', 'rdg', 'sic', 'reg') ) (:take string value of elements that below terminal elements concerned with edition:)
                            then 
                                string-join($child//text(), ' ') (:NB: hack - @token should be used:)
                            else
                                if ($child instance of text())
                                then $child
                                else local:collapse-annotation($child, $strip)
      }
};

declare function local:build-up-annotations($top-level-critical-annotations as element()+, $annotations as element()) as element()* {
    for $annotation in $top-level-critical-annotations
    let $annotation-id := $annotation/@xml:id
    let $annotation-element-name := local-name($annotation//body/*)
    let $children :=
            $annotations/annotation[target/annotation-layer/id = $annotation-id]
    let $children :=
                    for $child in $children
                    let $child-id := $annotation/@xml:id/string()
                        return
                            if ($annotations/annotation[target/annotation-layer/id = $child-id]) (:something is wrong here - this does not catch cases where there is a further annotation, leaving empty <children> at dead ends:)
                            then local:build-up-annotations($child, $annotations)
                            else $child
        return 
            local:insert-or-remove-nodes($annotation, $children, $annotation-element-name,  'first-child')            
};

declare function local:collapse-annotations($built-up-critical-annotations as element()+) {
    for $annotation in $built-up-critical-annotations

        return 
            local:collapse-annotation(local:collapse-annotation(local:collapse-annotation($annotation, 'annotation'), 'body'), 'base-layer')
};

declare function local:mesh-annotations($base-text as element(), $annotations as element()+) as element()+ {
let $segment-count := (count($annotations) * 2) + 1
let $segments :=
    for $segment at $i in 1 to $segment-count
    return
        <segment>{attribute n {$i}}</segment>
let $segments := 
    <p>{
        for $segment in $segments
            return
                if (number($segment/@n) mod 2 eq 0)
                then 
                    let $annotation-n := $segment/@n/number() div 2
                    return
                        local:insert-or-remove-nodes($segment, $annotations[$annotation-n]/(* except target), 'segment', 'first-child')
                else 
                    <segment n="{$segment/@n/string()}">
                        {
                            let $segment-n := number($segment/@n)
                            let $previous-annotation-n := ($segment-n - 1) div 2
                            let $following-annotation-n := ($segment-n + 1) div 2
                            let $start := 
                                if ($segment-n eq $segment-count) (:if it is the last text node:)
                                then string-length($base-text) - $annotations[$previous-annotation-n]/target/start/number() + $annotations[$previous-annotation-n]/target/offset/number() + 4 (:the start position is the length of of the base text minus the end position of the previous annotation plus 1:)
                                else
                                    if (number($segment/@n) eq 1) (:if it is the first text node:)
                                    then 1 (:start with position 1:)
                                    else $annotations[$previous-annotation-n]/target/start/number() + $annotations[$previous-annotation-n]/target/offset/number() (:if it is not the first or last text node, start with the position of the previous annotation plus its offset plus 1:)
                            let $offset := 
                                if ($segment-n eq count($segments)) 
                                then string-length($base-text) - $annotations[$previous-annotation-n]/target/start/number() + $annotations[$previous-annotation-n]/target/offset/number() + 1 (:if it is the last text node, then the offset is the length of the bast etx minus the end position of the last annotation plus 1:)
                                else
                                    if ($segment-n eq 1)
                                    then $annotations[$following-annotation-n]/target/start/number() - 1 (:if it is the first text node, the the offset is the start position of the following annotation minus 1:)
                                    else $annotations[$following-annotation-n]/target/start/number() - ($annotations[number($previous-annotation-n)]/target/start/number() + $annotations[$previous-annotation-n]/target/offset/number()) (:if it is not the first or the last text node, then the offset is the start position of the following annotation minus the end position of the previous annotation :)
                                return
                                    substring($base-text, $start, $offset)
                        }
                    </segment>
        }</p>
    return
        $segments
};

let $base-text := <p xml:id="uuid-8227bf23-decc-3181-aed6-4148e2121d25">I meet Stephen Winwood and Alexis Korner in the pub.</p>
            
let $hoped-for-result := <p xml:id="uuid-af570732-2121-30d0-8b05-f53bad3fa04f">I met Steve Winwood and John Mayall in the pub.</p>
            
let $annotations := <annotations><annotation type="element" xml:id="uuid-4abd36a7-d505-4adc-91a3-a66a6cc9c9bc" status="token"><target type="range" layer="edition"><base-layer><id>uuid-538a6e13-f88b-462c-a965-f523c3e02bbf</id><start>3</start><offset>4</offset></base-layer><authoritative-layer><id>uuid-5f44133c-728d-30a5-a296-c5603f5218c3></id><start>3</start><offset>3</offset></authoritative-layer></target><body><choice/></body><layer-offset-difference>-1</layer-offset-difference></annotation><annotation type="element" xml:id="uuid-779d9ea8-25a9-4eb3-9312-9dcabfd4a52f" status="token"><target type="element" layer="annotation"><annotation-layer><id>uuid-4abd36a7-d505-4adc-91a3-a66a6cc9c9bc</id><order>1</order></annotation-layer></target><body><reg>met</reg></body></annotation><annotation type="element" xml:id="uuid-8f8950c1-c0cd-4259-8125-7c8a761f996b" status="token"><target type="element" layer="annotation"><annotation-layer><id>uuid-4abd36a7-d505-4adc-91a3-a66a6cc9c9bc</id><order>2</order></annotation-layer></target><body><sic>meet</sic></body></annotation><annotation type="element" xml:id="uuid-a17fe03e-ac7d-45d8-92ef-f0917164c94c" status="token"><target type="range" layer="edition"><base-layer><id>uuid-538a6e13-f88b-462c-a965-f523c3e02bbf</id><start>8</start><offset>15</offset></base-layer><authoritative-layer><id>uuid-5f44133c-728d-30a5-a296-c5603f5218c3></id><start>7</start><offset>13</offset></authoritative-layer></target><body><app/></body><layer-offset-difference>-2</layer-offset-difference></annotation><annotation type="element" xml:id="uuid-7e50d3e0-f4e2-4a8d-89a0-1421c50032ba" status="token"><target type="element" layer="annotation"><annotation-layer><id>uuid-a17fe03e-ac7d-45d8-92ef-f0917164c94c</id><order>1</order></annotation-layer></target><body><lem wit="#a"/></body></annotation><annotation type="element" xml:id="uuid-f12feba1-ef16-4a6a-ab13-c41f5dfaf42e" status="token"><target type="element" layer="annotation"><annotation-layer><id>uuid-7e50d3e0-f4e2-4a8d-89a0-1421c50032ba</id><order>1</order></annotation-layer></target><body><name ref="#SW" type="person"/></body></annotation><annotation type="element" xml:id="uuid-0f3e2942-7f86-4a85-a3ae-72d42e57306b" status="token"><target type="element" layer="annotation"><annotation-layer><id>uuid-f12feba1-ef16-4a6a-ab13-c41f5dfaf42e</id><order>1</order></annotation-layer></target><body><forename>Steve</forename></body></annotation><annotation type="element" xml:id="uuid-7a124001-e642-4c30-b381-8b787b2bec3c" status="token"><target type="element" layer="annotation"><annotation-layer><id>uuid-f12feba1-ef16-4a6a-ab13-c41f5dfaf42e</id><order>2</order></annotation-layer></target><body><surname>Winwood</surname></body></annotation><annotation type="element" xml:id="uuid-018636fc-c659-4426-a2eb-11863365465d" status="token"><target type="element" layer="annotation"><annotation-layer><id>uuid-a17fe03e-ac7d-45d8-92ef-f0917164c94c</id><order>2</order></annotation-layer></target><body><rdg wit="#b"/></body></annotation><annotation type="element" xml:id="uuid-5bcb9234-6d17-4416-98cc-416698c916ba" status="token"><target type="element" layer="annotation"><annotation-layer><id>uuid-018636fc-c659-4426-a2eb-11863365465d</id><order>1</order></annotation-layer></target><body><name ref="#SW" type="person"/></body></annotation><annotation type="element" xml:id="uuid-f5b5cdc3-a9de-41a4-988b-6cb7b1d93a29" status="token"><target type="element" layer="annotation"><annotation-layer><id>uuid-5bcb9234-6d17-4416-98cc-416698c916ba</id><order>1</order></annotation-layer></target><body><forename>Stephen</forename></body></annotation><annotation type="element" xml:id="uuid-9a566fff-274e-4d03-8046-d7508612edb4" status="token"><target type="element" layer="annotation"><annotation-layer><id>uuid-5bcb9234-6d17-4416-98cc-416698c916ba</id><order>2</order></annotation-layer></target><body><surname>Winwood</surname></body></annotation><annotation type="element" xml:id="uuid-eb6bbeaa-75f4-4b3d-8dfe-312ca12cbacc" status="token"><target type="range" layer="edition"><base-layer><id>uuid-538a6e13-f88b-462c-a965-f523c3e02bbf</id><start>28</start><offset>13</offset></base-layer><authoritative-layer><id>uuid-5f44133c-728d-30a5-a296-c5603f5218c3></id><start>25</start><offset>11</offset></authoritative-layer></target><body><app/></body><layer-offset-difference>-2</layer-offset-difference></annotation><annotation type="element" xml:id="uuid-06c94ca9-5795-4868-8192-8a2128703113" status="token"><target type="element" layer="annotation"><annotation-layer><id>uuid-eb6bbeaa-75f4-4b3d-8dfe-312ca12cbacc</id><order>1</order></annotation-layer></target><body><rdg wit="#base"/></body></annotation><annotation type="element" xml:id="uuid-27091a6a-1ff6-42cd-99a3-3bb809e0bbc3" status="token"><target type="element" layer="annotation"><annotation-layer><id>uuid-06c94ca9-5795-4868-8192-8a2128703113</id><order>1</order></annotation-layer></target><body><name ref="#AK" type="person">Alexis Korner</name></body></annotation><annotation type="element" xml:id="uuid-8438215a-30ae-48e8-b3c0-33f200ea6745" status="token"><target type="element" layer="annotation"><annotation-layer><id>uuid-eb6bbeaa-75f4-4b3d-8dfe-312ca12cbacc</id><order>2</order></annotation-layer></target><body><rdg wit="#c"/></body></annotation><annotation type="element" xml:id="uuid-d8ae2c43-4f9f-46d1-bc07-b9d3122801b7" status="token"><target type="element" layer="annotation"><annotation-layer><id>uuid-8438215a-30ae-48e8-b3c0-33f200ea6745</id><order>1</order></annotation-layer></target><body><name ref="#JM" type="person">John Mayall</name></body></annotation><annotation type="element" xml:id="uuid-fa784d06-4eb0-42e9-9a6c-9c480b54f87a" status="string"><target type="range" layer="feature"><base-layer><id>uuid-538a6e13-f88b-462c-a965-f523c3e02bbf</id><start>41</start><offset>0</offset></base-layer><authoritative-layer><id>uuid-5f44133c-728d-30a5-a296-c5603f5218c3></id><start>36</start><offset>0</offset></authoritative-layer></target><body><pb n="3"/></body><layer-offset-difference>0</layer-offset-difference></annotation><annotation type="element" xml:id="uuid-b85a56fb-6d78-42c0-9533-dd399306f793" status="token"><target type="range" layer="feature"><base-layer><id>uuid-538a6e13-f88b-462c-a965-f523c3e02bbf</id><start>45</start><offset>7</offset></base-layer><authoritative-layer><id>uuid-5f44133c-728d-30a5-a296-c5603f5218c3></id><start>40</start><offset>7</offset></authoritative-layer></target><body><rs>the pub</rs></body><layer-offset-difference>0</layer-offset-difference></annotation><annotation type="element" xml:id="uuid-4ae90f43-95f9-47c2-8fdd-20f9ee210457" status="string"><target type="range" layer="feature"><base-layer><id>uuid-538a6e13-f88b-462c-a965-f523c3e02bbf</id><start>51</start><offset>0</offset></base-layer><authoritative-layer><id>uuid-5f44133c-728d-30a5-a296-c5603f5218c3></id><start>46</start><offset>0</offset></authoritative-layer></target><body><note resp="#JØP"/></body><layer-offset-difference>0</layer-offset-difference></annotation><annotation type="text" xml:id="uuid-0b9c587b-2d3c-47d1-a5c3-2ece39790db8" status="token"><target type="range" layer="text"><base-layer><id>uuid-4ae90f43-95f9-47c2-8fdd-20f9ee210457</id><start>1</start><offset>14</offset></base-layer></target><body>The author is </body></annotation><annotation type="element" xml:id="uuid-698789b1-7df5-4730-b51a-193d31152b8e" status="token"><target type="range" layer="feature"><base-layer><id>uuid-4ae90f43-95f9-47c2-8fdd-20f9ee210457</id><start>15</start><offset>9</offset></base-layer></target><body><emph/></body></annotation><annotation type="text" xml:id="uuid-9117307c-9769-4f5b-8feb-c3600338ff5a" status="string"><target type="range" layer="text"><base-layer><id>uuid-698789b1-7df5-4730-b51a-193d31152b8e</id><start>1</start><offset>4</offset></base-layer></target><body>pro-</body></annotation><annotation type="element" xml:id="uuid-5fc67ed3-4f41-4781-b63c-8e296c7f0deb" status="string"><target type="range" layer="feature"><base-layer><id>uuid-698789b1-7df5-4730-b51a-193d31152b8e</id><start>4</start><offset>0</offset></base-layer></target><body><pb n="3"/></body></annotation><annotation type="text" xml:id="uuid-114d21ca-b04d-4c7a-b731-cbfeb30db1f6" status="token"><target type="range" layer="text"><base-layer><id>uuid-698789b1-7df5-4730-b51a-193d31152b8e</id><start>5</start><offset>5</offset></base-layer></target><body>bably</body></annotation><annotation type="text" xml:id="uuid-05553dfa-8fe9-4b2c-b98c-d9ef1714ee13" status="token"><target type="range" layer="text"><base-layer><id>uuid-4ae90f43-95f9-47c2-8fdd-20f9ee210457</id><start>15</start><offset>12</offset></base-layer></target><body> wrong here.</body></annotation></annotations>

let $top-level-critical-annotations := $annotations/annotation[target/@type eq 'range'][target/@layer eq 'edition']
let $built-up-annotations := local:build-up-annotations($top-level-critical-annotations, $annotations)
let $collapsed-annotations := local:collapse-annotations($built-up-annotations)
let $meshed-annotations := local:mesh-annotations($base-text, $collapsed-annotations)
    return $meshed-annotations