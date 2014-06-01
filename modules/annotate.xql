xquery version "3.0";


(: sample annotation, tbd: setup annotation dynamicaly and save it :)
let $annotation := <annotation xmlns="http://www.betterform.de/projects/mopane/annotation" type="element" xml:id="" status="">
    <target type="element" layer="annotation">
        <id></id>
    </target>
    <body>
        <attribute>
            <name></name>
            <value></value>
        </attribute>
    </body>
</annotation>
return
    true