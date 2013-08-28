xquery version "3.0";

declare boundary-space preserve;

declare function local:get-base-text($input, $filter-away) {
    string-join(
        for $node in $input/node()
    return
        if ($node instance of element()) 
        then
            if (not(local-name($node) = $filter-away))
            then local:get-base-text($node, $filter-away)
            else ()
        else $node
    ,'')
    };

declare function local:get-top-level-elements($input as element(), $skip, $edition-layer) {
    for $node in $input/node()
    let $position-start := string-length(string-join(local:get-base-text($node/preceding-sibling::node(), $skip))) + string-length(string-join($node/preceding-sibling::text(), ''))
    let $position-end := string-length(string-join(local:get-base-text($node/preceding-sibling::node(), $skip))) + string-length(string-join($node/preceding-sibling::text(), '')) + string-length(string-join(local:get-base-text($node, $skip)))
    return
        if ($node instance of element())
        then     
            <annotation type="element" xml:id="{concat('uuid-', util:uuid())}">
                <target type="range" layer="{if (local-name($node) = $edition-layer) then 'edition' else 'feature'}">
                    <start>
                        <id>{$node/../@xml:id}</id>
                        <position>{$position-start + 1}</position>
                    </start>
                    <end>
                        <id>{$node/../@xml:id}</id>
                        <position>{$position-end}</position>
                    </end>
                </target>
                <body>
                    <node>{
                        if ($node/node() instance of text() and not($node/node() instance of element())) 
                        then 
                            element {node-name($node)} 
                            {for $attribute in $node/@* 
                                return 
                                    attribute {node-name($attribute)} {$attribute/string()}}
                        else $node}        
                    </node>
                    <contents>{if ($node/node() instance of text() and not($node/node() instance of element())) then $node/text() else ()}</contents>
                </body>
                    
            </annotation> 
            else ()
    
};

let $input := <p xml:id="uuid-538a6e13-f88b-462c-a965-f523c3e02bbf">I <choice><reg>met</reg><sic>meet</sic></choice> <name target="#JM" type="person"><forename><app><lem wit="#a">Steve</lem><rdg wit="#b">Stephen</rdg></app></forename> <surname>Winwood</surname></name> and <name target="#AK" type="person">Alexis Korner</name> <pb n="3"></pb>in <rs>the pub</rs><note resp="#JØP">The author is probably wrong here.</note>.</p>

let $filter-away := ('rdg', 'del', 'reg', 'note')(:NB: note should only be removed if it is not an original note, so the value of @resp has to be part of the filter.:)
let $edition-layer := ('app', 'choice')

let $top-level-annotations :=

    <annotations>{local:get-top-level-elements($input, $filter-away, $edition-layer)}</annotations>
    (:local:get-base-text($input, $filter-away):)
    (:returns the base text::)
    (:I meet Steve Winwood and Alexis Korner in the pub.:)
    (:I meet Ste<10>ve Winwood<20> and Alexi<30>s Korner i<40>n the pub.:)

(: these are the base units in the annotation interface, i.e. an app and a choice are annotated as a whole :)
let $termina := ('app', 'name', 'choice')

(: annotations are finished if they have string contents, if they have empty node elements or if they correspond to termina, i.e. units in the interface that do not contain other termina:)
let $finished-top-level-annotations :=    
        for $top-level-annotation in $top-level-annotations/node()
        where 
            normalize-space($top-level-annotation/body/contents/string()) 
            or normalize-space($top-level-annotation/body/node/string()) eq ''
            or ($top-level-annotation/body/node/local-name(*) = $termina and count($top-level-annotation/body/node//local-name(*) = $termina) eq 1)(:the last part does not filter correctly:)
                return $top-level-annotation
(: 
<annotations>
    <annotation xmlns:xml="http://www.w3.org/XML/1998/namespace" type="element"
        xml:id="uuid-8956c7d9-5617-4f3a-af06-a4753c8cd6ee">
        <target type="range" layer="feature">
            <start>
                <id xml:id="uuid-538a6e13-f88b-462c-a965-f523c3e02bbf"/>
                <position>26</position>
            </start>
            <end>
                <id xml:id="uuid-538a6e13-f88b-462c-a965-f523c3e02bbf"/>
                <position>38</position>
            </end>
        </target>
        <body>
            <node>
                <name target="#AK" type="person"/>
            </node>
            <contents>Alexis Korner</contents>
        </body>
    </annotation>
    <annotation xmlns:xml="http://www.w3.org/XML/1998/namespace" type="element"
        xml:id="uuid-21e2df00-90f4-43d5-a558-276c09d51565">
        <target type="range" layer="feature">
            <start>
                <id xml:id="uuid-538a6e13-f88b-462c-a965-f523c3e02bbf"/>
                <position>40</position>
            </start>
            <end>
                <id xml:id="uuid-538a6e13-f88b-462c-a965-f523c3e02bbf"/>
                <position>39</position>
            </end>
        </target>
        <body>
            <node>
                <pb n="3"/>
            </node>
            <contents/>
        </body>
    </annotation>
    <annotation xmlns:xml="http://www.w3.org/XML/1998/namespace" type="element"
        xml:id="uuid-35285c3a-df48-4ab7-a693-a175889ec029">
        <target type="range" layer="feature">
            <start>
                <id xml:id="uuid-538a6e13-f88b-462c-a965-f523c3e02bbf"/>
                <position>43</position>
            </start>
            <end>
                <id xml:id="uuid-538a6e13-f88b-462c-a965-f523c3e02bbf"/>
                <position>49</position>
            </end>
        </target>
        <body>
            <node>
                <rs/>
            </node>
            <contents>the pub</contents>
        </body>
    </annotation>
    <annotation xmlns:xml="http://www.w3.org/XML/1998/namespace" type="element"
        xml:id="uuid-f9df61ca-8919-44c0-a945-d92c129faef5">
        <target type="range" layer="feature">
            <start>
                <id xml:id="uuid-538a6e13-f88b-462c-a965-f523c3e02bbf"/>
                <position>50</position>
            </start>
            <end>
                <id xml:id="uuid-538a6e13-f88b-462c-a965-f523c3e02bbf"/>
                <position>83</position>
            </end>
        </target>
        <body>
            <node>
                <note resp="#JØP"/>
            </node>
            <contents>The author is probably wrong here.</contents>
        </body>
    </annotation>
</annotations>

 :)

let $unfinished-top-level-annotations := $top-level-annotations/* except $finished-top-level-annotations
(: <annotations>
    <annotation xmlns:xml="http://www.w3.org/XML/1998/namespace" type="element"
        xml:id="uuid-28e61928-facd-4109-823a-bcd35875bdc1">
        <target type="range" layer="edition">
            <start>
                <id xml:id="uuid-538a6e13-f88b-462c-a965-f523c3e02bbf"/>
                <position>3</position>
            </start>
            <end>
                <id xml:id="uuid-538a6e13-f88b-462c-a965-f523c3e02bbf"/>
                <position>6</position>
            </end>
        </target>
        <body>
            <node>
                <choice>
                    <reg>met</reg>
                    <sic>meet</sic>
                </choice>
            </node>
            <contents/>
        </body>
    </annotation>
    <annotation xmlns:xml="http://www.w3.org/XML/1998/namespace" type="element"
        xml:id="uuid-92d5d711-3340-4421-be59-3af64d971e07">
        <target type="range" layer="feature">
            <start>
                <id xml:id="uuid-538a6e13-f88b-462c-a965-f523c3e02bbf"/>
                <position>8</position>
            </start>
            <end>
                <id xml:id="uuid-538a6e13-f88b-462c-a965-f523c3e02bbf"/>
                <position>20</position>
            </end>
        </target>
        <body>
            <node>
                <name target="#JM" type="person">
                    <forename>
                        <app>
                            <lem wit="#a">Steve</lem>
                            <rdg wit="#b">Stephen</rdg>
                        </app>
                    </forename>
                    <surname>Winwood</surname>
                </name>
            </node>
            <contents/>
        </body>
    </annotation>
</annotations>
 :)



            return $finished-top-level-annotations