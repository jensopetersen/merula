xquery version "3.0";

declare function local:insert-missing-xml-id($element as element()) as element() {
   element {node-name($element)}
      {$element/@*,
        for $child in $element/node()
            return
                if ($child instance of element())
                then 
                    if ($child/@xml:id)
                    then local:insert-missing-xml-id($child)
                    else local:insert-missing-xml-id(
                        element {node-name($child)}
                        {attribute {'xml:id'} {concat("uuid-",util:uuid())},
                        $child/@*, $child/node()}
                    )
                else $child
      }
};

let $input := 
<elements>
    <a1  xml:id="a">
        <b1 xml:id="q">
            <x1>text-x1</x1>
            <y1>text-y1</y1>
        </b1>
    </a1>
    <a2>
        <b2> text-b2 </b2>
    </a2>
    <a3>
        <b3>
            <c3 xml:id="c">
                <d3>text-b2</d3>
            </c3>
        </b3>
    </a3>
</elements>

return 
    local:insert-missing-xml-id($input)
    