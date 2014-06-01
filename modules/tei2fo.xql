xquery version "3.0";

import module namespace config="http://exist-db.org/apps/shakes/config" at "config.xqm";

declare namespace fo="http://www.w3.org/1999/XSL/Format";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function fo:tei2fo($nodes as node()*) {
    for $node in $nodes
    return
        typeswitch ($node)
            case element(tei:TEI) return
                fo:tei2fo($node/tei:text)
            case element(tei:text) return
                fo:tei2fo($node//tei:body)
            case element(tei:div) return
                    <fo:block page-break-after="always" id="{generate-id($node)}">
                        {fo:tei2fo($node/node())}
                    </fo:block>
            case element(tei:head) return
                let $level := count($node/ancestor-or-self::tei:div)
                return
                    if ($level = 1) then
                        <fo:block font-size="28pt" font-family="Arial, Helvetica, sans-serif" 
                            space-after="16mm" margin-top="28mm">{ fo:tei2fo($node/node()) }</fo:block>
                    else
                        <fo:block font-size="16pt" font-weight="bold" space-after="10mm" margin-top="16mm"
                            font-family="Arial, Helvetica, sans-serif">
                            <fo:marker marker-class-name="titel">
                                {$node/text()}
                            </fo:marker>
                            { fo:tei2fo($node/node()) }
                        </fo:block>
            case element(tei:sp) return
                fo:speech($node)
            case element(tei:speaker) return
                <fo:block font-style="italic" space-after=".25em">
                {fo:tei2fo($node/node())}
                </fo:block>
            case element(tei:l) return
                <fo:block space-after=".25em">{fo:tei2fo($node/node())}</fo:block>
            case element(tei:ab) return
                <fo:block space-after=".25em">{fo:tei2fo($node/node())}</fo:block>
            case element(tei:stage) return
                <fo:block space-after="8mm" font-style="italic">{fo:tei2fo($node/node())}</fo:block>
            case element() return
                fo:tei2fo($node/node())
            default return
                $node
};

declare function fo:speech($speech as element(tei:sp)) {
    <fo:block space-after="1em">
        <fo:block space-after=".25em">
            <fo:inline space-end="1em" font-style="italic">{$speech/tei:speaker/text()}</fo:inline>
            <fo:inline>{$speech/(tei:l|tei:ab)[1]/text()}</fo:inline>
        </fo:block>
        {
            for $line in $speech/(tei:l|tei:ab)[position() > 1]
            return
                <fo:block space-after=".25em" margin-left=".75em">{fo:tei2fo($line)}</fo:block>
        }
    </fo:block>
};

declare function fo:titlepage($header as element(tei:teiHeader))   {
    <fo:page-sequence master-reference="Shakespeare">
        <fo:flow flow-name="xsl-region-body" font-family="Times, Times New Roman, serif">
            <fo:block font-size="44pt" text-align="center">
            {                     
                $header/tei:fileDesc/tei:titleStmt/tei:title/text() 
            }
            </fo:block> 
            <fo:block text-align="center" font-size="20pt" font-style="italic" space-before="2em" space-after="2em">
            by
            </fo:block>
            <fo:block text-align="center" font-size="30pt" font-style="italic" space-before="2em" space-after="2em">
            {                  
                $header/tei:fileDesc/tei:titleStmt/tei:author/text() 
            }
            </fo:block>
            <fo:block text-align="center" space-before="2em" space-after="2em">
            <!--fo:external-graphic content-height="300pt" src="http://data.stonesutras.org:8600/exist/apps/shakes/resources/images/shakespeare-french.jpg"/-->    
            </fo:block>
        </fo:flow>                    
    </fo:page-sequence>
};

declare function fo:table-of-contents($work as element(tei:TEI)) {
    <fo:page-sequence master-reference="Shakespeare">
        <fo:flow flow-name="xsl-region-body" font-family="Times, Times New Roman, serif">
        <fo:block font-size="30pt" space-after="1em" font-family="Arial, Helvetica, sans-serif">Table of Contents</fo:block>
        {
            for $act at $act-count in $work/tei:text/tei:body/tei:div
            return
                <fo:block space-after="3mm">
                    <fo:block text-align-last="justify">
                        {$act/tei:head/text()}
                        <fo:leader leader-pattern="dots"/>
                        <fo:page-number-citation ref-id="{generate-id($act)}"/>
                    </fo:block>
                    {
                        for $scene at $scene-count in $act/tei:div
                        return
                            <fo:block text-align-last="justify" margin-left="4mm">
                                {$scene/tei:head/text()}
                                <fo:leader leader-pattern="dots"/>
                                <fo:page-number-citation ref-id="{generate-id($scene)}"/>
                            </fo:block>
                    }
                </fo:block>
        }
        </fo:flow>
    </fo:page-sequence>
};

declare function fo:cast($nodes as node()*) {
    for $node in $nodes
    return
        typeswitch ($node)
            case element(tei:castList) return
                <fo:block space-after="4mm">
                { fo:cast($node/node()) }
                </fo:block>
            case element(tei:castGroup) return
                <fo:block space-after="8mm" space-before="8mm">
                    <fo:block font-weight="bold">{$node/tei:head/text()}</fo:block>
                    { fo:cast($node/tei:castItem) }
                </fo:block>
            case element(tei:castItem) return
                <fo:block space-after=".25em">{fo:cast($node/node())}</fo:block>
            case element(tei:role) return
                fo:tei2fo($node/node())
            case element(tei:roleDesc) return
                <fo:inline> (<fo:inline font-style="italic">{$node/text()}</fo:inline>)</fo:inline>
            case element() return
                fo:cast($node/node())
            default return
                $node
};

declare function fo:cast-list($work as element(tei:TEI)) {
    let $cast := $work/tei:text/tei:front/tei:div[@type = "castList"]
    return
        <fo:page-sequence master-reference="Shakespeare">
            <fo:static-content flow-name="kopf">
                <fo:block margin-bottom="0.7mm" text-align="left">
                    <fo:retrieve-marker retrieve-class-name="titel"/>
                </fo:block>
            </fo:static-content>
            <fo:flow flow-name="xsl-region-body" font-family="Times, Times New Roman, serif">
                <fo:marker marker-class-name="titel">{$cast/tei:head/text()}</fo:marker>
                <fo:block font-size="30pt" space-after="1em" font-family="Arial, Helvetica, sans-serif">{$cast/tei:head/text()}</fo:block>
                { fo:cast($cast/tei:castList) }
            </fo:flow>
        </fo:page-sequence>
};

declare function fo:main($id as xs:string) {
    let $play := collection($config:data)/tei:TEI[@xml:id = $id]
    return
        <fo:root xmlns:fo="http://www.w3.org/1999/XSL/Format">
            <fo:layout-master-set>
                <fo:simple-page-master master-name="Shakespeare" margin-top="10mm"
                        margin-bottom="10mm" margin-left="12mm"
                        margin-right="12mm">
                    <fo:region-body margin-bottom="10mm" margin-top="10mm"/>
                    <fo:region-before region-name="kopf" margin-bottom="10mm" extent="10mm"/>
                    <fo:region-after region-name="fussnoten" extent="10mm"/>
                </fo:simple-page-master>
            </fo:layout-master-set>
            { fo:titlepage($play/tei:teiHeader) }
            { fo:table-of-contents($play) }
            { fo:cast-list($play)}
            <fo:page-sequence master-reference="Shakespeare">
                <fo:static-content flow-name="kopf">
                    <fo:block margin-bottom="0.7mm" text-align="left">
                        <fo:retrieve-marker retrieve-class-name="titel"/>
                    </fo:block>
                </fo:static-content>
                <fo:static-content flow-name="fussnoten">
                    <fo:block margin-top="0.7mm" text-align="right">                         
                        <fo:page-number/>
                    </fo:block>
                </fo:static-content>
                <fo:flow flow-name="xsl-region-body" font-family="Times, Times New Roman, serif">
                    { fo:tei2fo($play/tei:text/tei:body/tei:div) }
                </fo:flow>                         
            </fo:page-sequence>
        </fo:root>
};

(:fo:main():)
let $id := request:get-parameter("id", ())
let $pdf := xslfo:render(fo:main($id), "application/pdf", ())
return
    response:stream-binary($pdf, "media-type=application/pdf", $id || ".pdf")
