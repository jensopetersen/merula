xquery version "3.0";

let $base-text :=
    <tei>
    <text n="x" xml:id="a">
            <div xml:id="b">
                <div xml:id="c">
                    <p xml:id="d">a<inline>a</inline>a</p>
                    <p xml:id="e">b<inline>b</inline>b</p>
                </div>
                <div xml:id="f">
                    <lg xml:id="g">
                        <l xml:id="h">c<inline>c</inline></l>
                        <l xml:id="i"><inline>d</inline>d</l>
                    </lg>
                    <lg xml:id="j">
                        <l xml:id="k">a
                            <inline>e</inline>
                        </l>
                        <l xml:id="l">f<inline>f</inline></l>
                    </lg>
                </div>
            </div>
        </text>
    </tei>

let $block-app := 
<text wit="y">
        <rdg><target>a</target><order>1</order><level>1</level><local-name>text</local-name></rdg>
        <rdg><target>b</target><order>2</order><level>2</level><local-name>div</local-name></rdg>
        <rdg><target>c</target><order>3</order><level>3</level><local-name>div</local-name></rdg>
        <rdg><target>e</target><order>4</order><level>4</level><local-name>p</local-name></rdg>
        <rdg><target>d</target><order>5</order><level>4</level><local-name>p</local-name></rdg>
        <rdg><target>m</target><order>6</order><level>4</level><contents><p xml:id="m">m<inline>m</inline>m</p></contents></rdg>
        <rdg><target>f</target><order>7</order><level>3</level><local-name>div</local-name></rdg>
        <rdg><target>j</target><order>8</order><level>4</level><local-name>lg</local-name></rdg>
        <rdg><target>k</target><order>9</order><level>5</level><local-name>l</local-name></rdg>
        <rdg><target>l</target><order>10</order><level>5</level><local-name>l</local-name></rdg>
    </text>

let $block-elements := ('text','div', 'p', 'lg', 'l')

let $base-text-elements :=
    for $element at $i in ($base-text//*)[local-name(.) = $block-elements]
    return 
        if ($element/text()) 
        then element {local-name($element) }{ $element/@*, attribute{'depth'}{count($element/ancestor-or-self::node())-1}, attribute{'order'}{$i}, $element/node()}
        else element {local-name($element) }{$element/@*, attribute{'depth'}{count($element/ancestor-or-self::node())-1}, attribute{'order'}{$i},  ''} 

let $app-in-base-text :=
    for $rdg in $block-app/*
    return $base-text-elements[@xml:id eq $rdg/target]
    (:they have to get the order attribute from the app:)
let $log := util:log("DEBUG", ("##$app-in-base-text1): ", $app-in-base-text))
let $app-in-base-text :=
    for $rdg in $app-in-base-text
        return element {local-name($rdg) }{$rdg/(@* except @order), attribute{'order'}{$block-app/rdg[target = $rdg/@xml:id/string()]/order},  ''} 
let $base-text-ids :=
    $base-text//@xml:id/string()

let $app-not-in-base-text :=
    for $rdg in $block-app/*[not(./target = $base-text-ids)]
    return element {local-name($rdg/contents/*) }{ $rdg/@*, attribute{'depth'}{$rdg/level},  attribute{'order'}{$rdg/order}, $rdg/contents/*}

let $reconstructed-text :=
        for $element in ($app-not-in-base-text, $app-in-base-text)
        order by number($element/@order)
        return $element

return $reconstructed-text