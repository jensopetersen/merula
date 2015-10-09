xquery version "3.0";

(:Finds contained a8ns:)

let $a8ns := 
<a8ns>
    <a8n n="a"><offset>10</offset><range>5</range></a8n>
    <a8n n="b"><offset>15</offset><range>5</range></a8n>
    <a8n n="c"><offset>5</offset><range>3</range></a8n>
    <a8n n="d"><offset>15</offset><range>5</range></a8n>
    <a8n n="e"><offset>11</offset><range>2</range></a8n>
    <a8n n="f"><offset>15</offset><range>5</range></a8n>
    <a8n n="g"><offset>15</offset><range>4</range></a8n>
    <a8n n="h"><offset>16</offset><range>3</range></a8n>
</a8ns>


let $results := 
    for $a8n-base in $a8ns/*
    let $base-offset := $a8n-base/offset/number()
    let $base-range := $a8n-base/range/number()
    for $a8n-target in $a8ns/*
    let $target-offset := $a8n-target/offset/number()
    let $target-range := $a8n-target/range/number()
    return
        if ($a8n-base is $a8n-target)
        then ()
        else 
            if ($target-offset >= $base-offset and $target-offset <= $base-offset + $base-range and $target-offset + $target-range <= $base-offset + $base-range)
            then
            <result>{$a8n-base, $a8n-target}</result>
            else ()
    
let $results := 
    for $a8n-base in $a8ns/*
    return
    <result>{
        <test>{$a8n-base}</test>, 
        for $result in $results
        return
            if (deep-equal($a8n-base, $result/*[1]))
            then <contained>{$result/*[2]}</contained>
            else ()
    }</result>

let $a8ns := 
    for $result in $results
    return
        if (count($result/contained) eq 0)
        then ()
        else $result
        
return $a8ns