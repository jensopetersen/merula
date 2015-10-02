Standoff Implementation of TEI
===================

Run `inline2standoff.xq` with `let $output-format := 'doc'`. This takes the TEI text `sample_MTDP10363.xml` and generates its base text version, plus all of its inline annotations, and stores this in `data`.

Call `http://localhost:8080/exist/apps/merula/plays/plays/sha-ham.html` and `standoff2inline.xql` inserts the annotations into the base text, first the editorial annotations, then the feature annotations, thereby re-generating the TEI, and displays it as html.

Add an editorial annotation by running add-annotation.xq and the feature annotations are kept in sync.