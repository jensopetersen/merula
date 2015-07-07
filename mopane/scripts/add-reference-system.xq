xquery version "3.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $in-collection := '/db/test/in';
declare variable $out-collection := 'xmldb:exist:///db/test/out';

declare function local:change-attributes($node as node(), $new-name as xs:string, $new-content as item(), $action as xs:string, $target-element-names as xs:string+, $target-attribute-names as xs:string+) as node()+ {
    if ($node instance of element()) 
    then
        element {node-name($node)} 
        {
            if ($action = 'attach-attribute-to-element' and name($node) = $target-element-names)
            then ($node/@*, attribute {$new-name} {$new-content})
            else 
            $node/@*
            ,
            for $child in $node/node()
            return $child        
        }
    else $node
};

declare function local:add-references($element as element(), $targets as xs:string+) as element() {
    element {node-name($element)}
    {$element/@*,
    for $child in $element/node()
        return
            if ($child instance of element() and $child/parent::element()/@xml:id)
            then
                if (not($child/@xml:id))
                then
                    let $local-name := local-name($child)
                    let $preceding-siblings := $child/preceding-sibling::element()
                    let $preceding-siblings := count($preceding-siblings[local-name(.) eq $local-name])
                    let $following-siblings := $child/following-sibling::element()
                    let $following-siblings := count($following-siblings[local-name(.) eq $local-name])
                    let $seq-no := 
                        if ($preceding-siblings = 0 and $following-siblings = 0)
                        then ''
                        else $preceding-siblings + 1
                    let $id-value := concat($child/../@xml:id, '-', $local-name, $seq-no)
                    return
                        local:change-attributes($child, 'xml:id', $id-value, 'attach-attribute-to-element', $targets, '')
                else local:add-references($child, $targets)
            else
                 if ($child instance of element())
                 then local:add-references($child, $targets)
                 else $child
      }
};

declare function local:add-references-recursively($now as element(), $targets as xs:string+) as element() {
  let $next := local:add-references($now, $targets)
  return
    if (deep-equal($now, $next))
    then $now
    else local:add-references-recursively($next, $targets)
};

let $targets := ('body', 'trailer', 'fw', 'div', 'hi', 'docAuthor', 'quote', 'docTitle', 'head', 'note', 'titlePage', 'text', 'cell', 'front', 'l', 'table', 'row', 'ref', 'seg', 'pb', 'lg', 'q', 'p', 'ab', 'lb', 'foreign', 'titlePart')
let $in-doc-title := 'CHANT-0883.app.xml'
let $out-doc-title := 'CHANT-0883.app.id.xml'

let $doc := doc(concat($in-collection, "/", $in-doc-title))/*
let $text := $doc//tei:text

let $doc := element{node-name($doc)}{($doc/@*, $doc/tei:teiHeader, local:add-references-recursively($text, $targets))}
return xmldb:store($out-collection, $out-doc-title, $doc)