Standoff Implementation of TEI
===================

Run inline2standoff.xq with let $output-format := 'file'. This takes the TEI text sample_MTDP10363.xml and generates the base text it builds on, plus all of its inline annotation, and stores this in data.

Call http://localhost:8080/exist/apps/merula/plays/plays/sha-ham.html and standoff2inline.xql inserts the annotations into the base text, thereby re-generating the TEI, and displays it as html.