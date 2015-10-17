Standoff Implementation of TEI in eXist-db
===================

Build app by running `ant`. Install `.xar` in eXist-db (version 2.2 upwards) through the Dashboard.

Call `http://localhost:8080/exist/apps/merula/plays/sha-ham101.html`. `standoff2inline.xql` then inserts the annotations stored in `/db/apps/merula/data/annotations` into the base text (stored as `/db/apps/merula/data/sample_MTDP10363.xml`), first the editorial annotations, then the feature annotations, thereby re-generating a TEI document, and displays it as html.

Run `inline2standoff.xq` in eXide with `let $output-format := 'doc'`. This takes the original (inline) TEI text `sample_MTDP10363.xml` stored in `/db/apps/merula/mopane` and generates its base text version, plus all of its inline annotations, and stores this in `/db/apps/merula/data`. This overwrites the sample data.

Add an editorial annotation by running `add-annotation.xq` in eXide and the existing feature annotations that follow it are kept in sync.

See [Implementing Standoff Annotation](https://github.com/jensopetersen/merula/blob/master/implementing-standoff-annotation.md) for a discussion of the issues involved and the approaches adopted.