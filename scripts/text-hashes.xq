xquery version "3.0";

declare function local:hash-leaves($element as element()) as element()* {
        for $child in $element/node()
            return
                if ($child instance of element())
                then 
                    if ($child/text())
                    then 
                        <annotation type="element" xml:id="{concat("uuid-",util:uuid())}" status="block">
                            <target type="element" layer="hash">
                                <id>{$child/@xml:id/string()}</id>
                            </target>
                            <body>
                                <hash>{util:hash($child,"SHA-1")}</hash>
                                <text>{$child/text()}</text>
                            </body>
                        </annotation>
                    else local:hash-leaves($child)
                else ()
};

let $input := 
<elements xml:id="b">
    <a1 xml:id="a">
        <b1 xml:id="q">
            <x1 xml:id="uuid-47b5356a-0d63-4916-8216-ae42f87423b6">text-x1</x1>
            <y1 xml:id="uuid-b7043e57-bf75-4c2f-9c47-b6246ad8dc24">text-y1</y1>
        </b1>
    </a1>
    <a2 xml:id="uuid-9a3b3372-c6e9-4d09-8afd-aba87f6dda64">
        <b2 xml:id="uuid-bc8c5e77-60a5-43fa-8060-554cd3637169"> text-b2 </b2>
    </a2>
    <a3 xml:id="uuid-ba5023b0-bf9c-488f-b2cb-940b728c823f">
        <b3 xml:id="uuid-5ce06abe-e1ca-45d6-9d2d-611be6df203a">
            <c3 xml:id="c">
                <d3 xml:id="uuid-97ab4519-9d9d-4832-a8f6-7e9f39309e52">text-b2</d3>
            </c3>
        </b3>
    </a3>
</elements>

let $hashed-leaves := local:hash-leaves($input)
let $hashed-whole := util:hash(string-join($hashed-leaves//hash),"SHA-1")
let $hashed-whole := (
                        <annotation type="element" xml:id="{concat("uuid-",util:uuid())}" status="block">
                            <target type="element" layer="hash">
                                <id>{$input/@xml:id/string()}</id>
                            </target>
                            <body>
                                <hash>{util:hash(string-join($hashed-leaves//hash),"SHA-1")}</hash>
                            </body>
                        </annotation>
                        ,
                        $hashed-leaves
                        )
                        
return 
    $hashed-whole