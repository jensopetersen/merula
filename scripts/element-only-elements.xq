xquery version "3.0";

declare namespace rng="http://relaxng.org/ns/structure/1.0";


declare function local:content-to-element($content-name as xs:string) as xs:string* {
    let $elements := collection('/db/test/rng')//rng:define[not(@combine)][./@name eq $content-name]//rng:ref
        for $element in $elements
        let $name := $element/@name/string()
        return 
            if (not((contains($name, '.') and not($name eq 'macro.anyXML'))))
            then $name
            else local:content-to-element($name)
};

let $all-definitions := collection('/db/test/rng')//rng:define[not(@combine)][not(contains(./@name, '.'))]
let $text-container-definitions := collection('/db/test/rng')//rng:define[not(@combine)][contains(./@name, '.')][.//rng:text]

let $all-elements :=
    for $definition in $all-definitions
    return $definition/@name/string()
let $all-text-elements :=
    for $definition in $text-container-definitions
    let $class-name := $definition/@name/string()
    let $element-names := 
        for $element-name in collection('/db/test/rng')//rng:ref[./@name eq $class-name]/ancestor::rng:define/@name/string()
        return local:content-to-element($element-name)
    let $element-names := distinct-values($element-names)
    return $element-names
let $all-element-only-elements :=  
    for $element in $all-elements
    where not($element = $all-text-elements)
    order by $element
    return $element
    
return string-join($all-element-only-elements, ' | ')