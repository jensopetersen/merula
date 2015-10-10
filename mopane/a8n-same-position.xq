xquery version "3.0";

(:wraps up a8n with same offset and range in element:)

let $a8ns := 
<a8ns>
    <a8n n="a"><offset>10</offset><range>5</range></a8n>
    <a8n n="b"><offset>15</offset><range>5</range></a8n>
    <a8n n="c"><offset>5</offset><range>3</range></a8n>
    <a8n n="d"><offset>15</offset><range>5</range></a8n>
    <a8n n="e"><offset>11</offset><range>2</range></a8n>
    <a8n n="x"><offset>16</offset><range>3</range></a8n>
    <a8n n="f"><offset>15</offset><range>5</range></a8n>
    <a8n n="g"><offset>15</offset><range>4</range></a8n>
    <a8n n="h"><offset>16</offset><range>3</range></a8n>
</a8ns>

let $a8ns := 
    for $a8n in $a8ns/a8n
    return
        if (
        $a8n/following-sibling::a8n[offset/number() = $a8n/offset/number()][range/number() = $a8n/range/number()]
        and
        not($a8n/preceding-sibling::a8n[offset/number() = $a8n/offset/number()][range/number() = $a8n/range/number()])
        )
        then <contained-cluster>{$a8n, $a8n/following-sibling::a8n[offset/number() = $a8n/offset/number()][range/number() = $a8n/range/number()]}</contained-cluster>
        else 
            if (
            ($a8n/preceding-sibling::a8n[offset/number() = $a8n/offset/number()] and
            $a8n/preceding-sibling::a8n[range/number() = $a8n/range/number()]
            or
            ($a8n/following-sibling::a8n[offset/number() = $a8n/offset/number()] and $a8n/following-sibling::a8n[range/number() = $a8n/range/number()])
            ))
            then ()
            else $a8n

return 
    $a8ns