xquery version "3.0";

declare namespace functx = "http://www.functx.com";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function functx:get-matches-and-non-matches
  ( $string as xs:string? ,
    $regex as xs:string )  as element()* {

   let $iomf := functx:index-of-match-first($string, $regex)
   return
   if (empty($iomf))
   then <non-match>{$string}</non-match>
   else
   if ($iomf > 1)
   then (<non-match>{substring($string,1,$iomf - 1)}</non-match>,
         functx:get-matches-and-non-matches(
            substring($string,$iomf),$regex))
   else
   let $length :=
      string-length($string) -
      string-length(functx:replace-first($string, $regex,''))
   return (<match>{substring($string,1,$length)}</match>,
           if (string-length($string) > $length)
           then functx:get-matches-and-non-matches(
              substring($string,$length + 1),$regex)
           else ())
 } ;

declare function functx:replace-first
  ( $arg as xs:string? ,
    $pattern as xs:string ,
    $replacement as xs:string )  as xs:string {

   replace($arg, concat('(^.*?)', $pattern),
             concat('$1',$replacement))
 } ;
declare function functx:index-of-match-first
  ( $arg as xs:string? ,
    $pattern as xs:string )  as xs:integer? {

  if (matches($arg,$pattern))
  then string-length(tokenize($arg, $pattern)[1]) + 1
  else ()
 } ;
declare function functx:get-matches
  ( $string as xs:string? ,
    $regex as xs:string )  as xs:string* {

   functx:get-matches-and-non-matches($string,$regex)/
     string(self::match)
 } ;
 
declare function local:change-attributes($node as node(), $new-name as xs:string, $new-content as item(), $action as xs:string, $target-element-names as xs:string+, $target-attribute-names as xs:string+) as node()+ {
 
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
                            local:change-attributes($child, $new-name, $new-content, $action, $target-element-names, $target-attribute-names) 
                }
            else $node
};

declare function local:translate-devanagari-nos($nos as xs:string) as xs:string {
    translate($nos, '०१२३४५६७८९–', '0123456789-')
};

declare function local:numerals-after-double-daṇḍas($element as element()) as element() {
    element {node-name($element)}
    {$element/@*,
    for $child in $element/node()
        return
            if ($child instance of element(tei:lg) and not($child/@xml:id))
            then 
            (
                let $last-line := $child/tei:l[count(.)]
                let $last-line-nos := functx:get-matches($last-line, '॥\s.*?\s॥')
                let $last-line-nos := string-join($last-line-nos)
                let $last-line-nos := replace($last-line-nos, ' ', '')
                let $last-line-nos := replace($last-line-nos, '॥', '')
                let $last-line-nos := local:translate-devanagari-nos($last-line-nos)
                let $id-value := ('ts_' || $last-line-nos)
                    return
                        if ($last-line-nos)
                        then local:change-attributes($child, 'xml:id', $id-value, 'attach-attribute-to-element', 'lg', '')
                        else $child
            )
            else 
                 if ($child instance of element())
                 then local:numerals-after-double-daṇḍas($child)
                 else 
                     if ($child instance of text())
                     then $child
                     else ()
      }
};

let $doc := doc('/db/test/in/tsp-abbr.xml')/*
    return local:numerals-after-double-daṇḍas($doc)