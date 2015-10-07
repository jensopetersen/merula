Standoff Implementation of TEI in eXist-db
===================

Build app by running `ant`. Install `.xar` in eXist-db (version 2.2 upwards) through the Dashboard.

Run `inline2standoff.xq` in eXide with `let $output-format := 'doc'`. This takes the TEI text `sample_MTDP10363.xml` and generates its base text version, plus all of its inline annotations, and stores this in `/db/apps/merula/data`.

Call `http://localhost:8080/exist/apps/merula/plays/plays/sha-ham.html`. `standoff2inline.xql` then inserts the annotations into the base text, first the editorial annotations, then the feature annotations, thereby re-generating the TEI of the original document, and displays it as html.

Add an editorial annotation by running `add-annotation.xq` in eXide and the existing feature annotations are kept in sync.

See [Implementing Standoff Annotation](https://github.com/jensopetersen/merula/blob/master/implementing-standoff-annotation.md) for a discussion of the issues involved and the approaches adopted here.