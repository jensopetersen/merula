xquery version "3.0";

(:Finds overlaps:)
(:First remove empties, identicals and containments:)

let $a8ns := 
<a8ns>
    <a8n n="a"><offset>10</offset><range>5</range></a8n>
    <a8n n="b"><offset>15</offset><range>5</range></a8n>
    <a8n n="c"><offset>5</offset><range>3</range></a8n>
    <a8n n="d"><offset>7</offset><range>2</range></a8n>
</a8ns>

let $a8ns-ordered := 
    <a8ns>{
    for $a8n in $a8ns/*
    order by $a8n/offset/number(), $a8n/range/number()
    return $a8n
    }</a8ns>

let $results := 
    for $a8n in $a8ns-ordered/*
    return
    
    if ($a8n/offset/number() + $a8n/range/number() <= $a8n/following-sibling::a8n[1]/offset/number())
    then <result type="good"><test>{$a8n}</test><following>{$a8n/following-sibling::a8n[1]}</following></result>
    else 
        if ($a8n/following-sibling::a8n)
        then <result type="bad"><test>{$a8n}</test><following>{$a8n/following-sibling::a8n[1]}</following></result>
        else <result type="good"><test>{$a8n}</test></result>
    
return 
    $results