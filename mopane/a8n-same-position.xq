xquery version "3.0";

(:Finds identical a8ns from test a8n:)

let $a8ns := 
<a8ns>
    <a8n n="a"><offset>10</offset><range>5</range></a8n>
    <a8n n="b"><offset>15</offset><range>5</range><order>1</order></a8n>
    <a8n n="c"><offset>5</offset><range>3</range></a8n>
    <a8n n="d"><offset>15</offset><range>5</range><order>2</order></a8n>
    <a8n n="e"><offset>11</offset><range>2</range></a8n>
    <a8n n="x"><offset>16</offset><range>3</range></a8n>
    <a8n n="f"><offset>15</offset><range>5</range><order>1</order></a8n>
    <a8n n="g"><offset>15</offset><range>4</range></a8n>
    <a8n n="h"><offset>16</offset><range>3</range></a8n>
</a8ns>

let $test-a8n := <a8n n="x"><offset>16</offset><range>3</range></a8n>

let $results := 
    for $a8n-target in $a8ns/*
    let $target-offset := $a8n-target/offset/number()
    let $target-range := $a8n-target/range/number()
    return
        if (deep-equal($test-a8n, $a8n-target))
        then ()
        else 
            if ($target-offset = $test-a8n/offset/number() and $target-range = $test-a8n/range/number())
            then
            $a8n-target
            else ()

return $results