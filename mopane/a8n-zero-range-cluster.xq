xquery version "3.0";

(:wraps up zero range clusters in element:)

let $a8ns := 
<a8ns>
    <a8n n="a"><offset>10</offset><range>5</range></a8n>
    <a8n n="b"><offset>11</offset><range>0</range></a8n>
    <a8n n="c"><offset>15</offset><range>5</range></a8n>
    <a8n n="d"><offset>5</offset><range>0</range></a8n>
    <a8n n="e"><offset>11</offset><range>0</range></a8n>
    <a8n n="f"><offset>7</offset><range>2</range></a8n>
    <a8n n="g"><offset>11</offset><range>0</range></a8n>
</a8ns>

let $a8ns := 
    for $a8n in $a8ns/*
    return
        if ($a8n/range/number() = 0 and $a8n/following-sibling::a8n[offset/number() = $a8n/offset/number()] and not($a8n/preceding-sibling::a8n[offset/number() = $a8n/offset/number()]))
        then <zero-range-cluster>{$a8n, $a8n/following-sibling::a8n[offset/number() = $a8n/offset/number()]}</zero-range-cluster>
        else 
            if ($a8n/preceding-sibling::a8n[offset/number() = $a8n/offset/number()] or $a8n/following-sibling::a8n[offset/number() = $a8n/offset/number()])
            then ()
            else $a8n

return 
    $a8ns