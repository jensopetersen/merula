#TEI standoff annotation

##Annotation and Text

###Kinds of annotation

There are two kinds of annotation:

* Annotations that affect the text stream; these consist of editorial annotations, typified by `<app>` and `<choice>`. By means of these annotations, TEI encodes several text versions at the same time, making the text fork each time the text stream passes through them.
* The remaining annotations that do not affect the text either
	* "decorate" text spans, as inline feature markup, 	* empty elements such as milestone elements, or
	* attributes attached to elements.

The present implementation does not address structural markup, only inline markup (and attributes, also on text block structural markup). Empty elements that are siblings of structural markup are also not handled. The beginnings of a standoff approach to structural markup can be found in block-app.xq and block-app-notes.xml.

###Text layers

A TEI project using the projected standoff editor starts with the transcription of a text. This transcription is, in the framework of the standoff editor, fixed and immutable. Since the idea behind the standoff editor is to encode all inline markup in standoff annotations, the transcription consists of text in block-level markup with @xml:ids.

The transcription is stored as canonicalized and Unicode-normalized XML. The stability of the transcription is guaranteed by hash annotations that first target each text node and then target the hashes of the block-level hash annotations in document order. This ensures that no changes can occur unnoticed. Once a transcription has been established, the text can only change through text-critical annotations. If the transcription aims to represent a definite edition and mistakes of transcription are found, these are corrected by text-critical annotations in which the TEI text is referred to as a witness.

The transcription is called "the base text" and a text established through text-critical annotations is called a "target text." The standoff editor can operate with more than one target text.

A target text is virtual, constructed on the fly by applying the text-critical annotations to the base text. Like the base text, it consists of text in block-level TEI elements only, with @xml:ids as the only attributes. For reasons of indexing and search, it may be necessary to store target texts, but the editor should not require this to be done.

Text-critical annotations always target the base text, whereas feature annotations always target a target text (the terminology here needs more thought here …). It may well be that only one target text is operated with, but as different target texts are possible, each feature annotation must refer to a specification of how the target text is constructed. 

The different target texts that a document make possible are specified in the document's header in the form of an XQuery function that transforms base-text plus text-critical annotations into the target text in question.

This means that the first choice the annotator has to make is whether

* to view the base text (side by side with existing text-critical annotations) in order to a new make text-critical annotation, or
* to view a target text (alongside existing feature annotations) in order to make a new feature annotation.

If additional text-critical annotations affect the already existing feature annotations, they should be kept in sync. To a large extent, this can be done automatically, but human intervention is required to solve certain hard cases.

###Annotation targets

There are the following targets of annotation:

* element annotations which either
	* target a span of text (in the base text or a target text) by means of an offset, a range and the element's node distance from the nearest preceding text node or its position in its parent's child node sequence
	* target an element located in this way, through its annotation, with contents consisting of text or mixed contents (a way of handling mixed contents in annotations is being worked out)
* attribute annotations

###Annotation formats

####Feature annotations

An annotation consists of a target, a body and administrative data. The administrative data will be left out in this discussion.

A feature annotation targeting a text range looks like this:

	<a8n-annotation 
		xml:id="uuid-ad0f7637-b016-47cb-99c4-1b4c7657abd9" 
		target-text="#lem">
		<a8n-target>
			<a8n-id>uuid-4f71d797-0d51-35cb-86b0-e283afdf889a</a8n-id>
			<a8n-offset>178</a8n-offset>
			<a8n-range>5</a8n-range>
			<a8n-order>1</a8n-order>
		</a8n-target>
		<a8n-body>
			<name xmlns="http://www.tei-c.org/ns/1.0"/>
		</a8n-body>
		<a8n-admin/>
	</a8n-annotation>


The attribute @target-text "#lem" identifies the layer annotated; a definition of "lem" is found in the header of the document, in the form of an XQuery function which produces the target text by applying the text-critical annotations to the base text.

The target specifies that the annotation targets the text element with the xml:id stated, from the offset to the range, and that it occurs first (in case there are multiple annotations targeting the same span).

The body here specifies what is to be added to the target text span: it is to be wrapped inside the TEI element specified (empty elements "wrap" around a span of zero).

The annotation thus tells that the TEI <name> element is to be wrapped around characters 178-182 of the text of the element identified by the @xml:id "uuid-4f71d797-0d51-35cb-86b0-e283afdf889a" (and that its first preceding sibling is a text node).

It is assumed that references to text elements are universally unique.

####Text-critical annotations

A text-critical annotation targeting the base text looks like this:

	<a8n-annotation
		xml:id="uuid-ab22e71e-0956-4498-a028-9fd0aaedc473">
		<a8n-target>
			<a8n-id>uuid-4f71d797-0d51-35cb-86b0-e283afdf889a</a8n-id>
			<a8n-offset>216</a8n-offset>
			<a8n-range>4</a8n-range>
			<a8n-order>1</a8n-order>
		</a8n-target>
		<a8n-body>
			<app xmlns="http://www.tei-c.org/ns/1.0">
				<lem>Governor</lem>
				<rdg wit="#TS1 #TS2">Gov.</rdg>
			</app>
		</a8n-body>
	</a8n-annotation>

The annotation is, however, not stored in this form. Si nce it should be possible to have administrative data relating to each act of annotation, it is decomposed by creating annotations out of the contents of the top-level element of its body, `<app>`, thusly:

	<a8n-annotation
		xml:id="uuid-ab22e71e-0956-4498-a028-9fd0aaedc473">
		<a8n-target>
			<a8n-id>uuid-4f71d797-0d51-35cb-86b0-e283afdf889a</a8n-id>
			<a8n-offset>216</a8n-offset>
			<a8n-range>4</a8n-range>
			<a8n-order>1</a8n-order>
		</a8n-target>
		<a8n-body>
			<app xmlns="http://www.tei-c.org/ns/1.0"/>
		</a8n-body>
	</a8n-annotation>

In addition to this, we get one annotation for the `<lem>`, one for the `<rdg>` and one for the `@wit` attribute on `<rdg>`. Let us look at the two last ones.

	<a8n-annotation motivatedBy="editing" xml:id="uuid-dcc85279-3159-4db7-8a48-8b53535755ea">
		<a8n-target>
			<a8n-id>uuid-ab22e71e-0956-4498-a028-9fd0aaedc473</a8n-id>
			<a8n-order>2</a8n-order>
		</a8n-target>
		<a8n-body>
			<rdg xmlns="http://www.tei-c.org/ns/1.0"/>
		</a8n-body>
	</a8n-annotation>

This annotation tell that it targets another annotation, since it has no offset and range. The target id thus points to another annotation, the one with the xml:id in question, which is the `<app>` annotation. Whereas annotations with offset and range wrap around text spans, annotations that target other annotations (that are not attribute annotations - see below) are inserted as children into the target's body element, so we know from this that the `<rdg>` is to be inserted as the second element inside the `<app>` element (the `<lem>`element being the first). 

The attribute on `<rdg>` gets annotated in the following way:

	<a8n-annotation motivatedBy="editing" xml:id="uuid-4107ccb4-2f32-4492-88ac-ee80cfe37aee">
		<a8n-target>
			<a8n-id>uuid-ab22e71e-0956-4498-a028-9fd0aaedc473</a8n-id>
		</a8n-target>
		<a8n-body>
			<a8n-attribute>
				<a8n-name>wit</a8n-name>
				<a8n-value>#TS1 #TS2</a8n-value>
			</a8n-attribute>
		</a8n-body>
	</a8n-annotation>

This tells that an attribute with the stated name and value is to be attached to the element (oe yoin thbod the anotation) referred to by its target id.

Annotations are automatically "peeled off" for storage and further annotation and "built up" to be inserted into base and target text for presentation and further annotation.

#Unedited below this!

###Schema-derived information

Ideally speaking, it should be possible to derive information about which elements and attributes can be inserted at which point from a transform of a customised TEI schema, but a customised schema for the SARIT project does not exist yet, and the problems involved with making such a transform are considerable, especially seen in relation to the limited use of TEI tags in SARIT (probably as few as 10% of the options given in the official "minimal" TEI tag set are used.) 

###Milestones

* Discussion about issues related to standoff markup, writeup of Google Doc

* Proof-of-concept of script for converting TEI inline markup to base text, authoritative text and standoff annotations

* Discussion about issues related to standoff markup, revision of Google Doc

* Proof-of-concept of the use of web components for creating and editing standoff annotations

1. For the proof-of-concept, render base text and selected semantic annotations to HTML. Use web components technology to implement the HTML tags representing basic semantic annotations like persName or placeName. Clicking on a tag opens the corresponding, component-specific UI for modifications.
2. Allow users to add further semantic annotations to a span of text.
3. Implement server-side services to store and retrieve annotations.

* Proof-of-concept of script for converting base text and standoff annotations to TEI document with inline markup

* Editor milestone 1
1. Distinguish between text-critical and semantic annotation layer in user interface. Let user switch between the layers. Decide on general workflow model to be used.
2. Implement the most important annotation types as web components. Design general look and feel of components as well as basic user interaction.
3. Keep track of modified/added annotations and save them to db when user commits changes.
4. Test and improve rendering performance: annotated TEI to HTML.

* Editor milestone 2
1. Handle nested annotations in the user interface: if multiple annotations are defined on a given span of text, user needs to be able to select an annotation for editing.
2. Implement client-side validation: while there may be conflicts between the annotations on different layers, we may want to avoid certain combinations.
3. Add remaining annotation types as components.
4. Streamline the editing workflow, improve usability, test all editor components

* Editor milestone 3
1. Multi user support: properly handle locking of documents
2. Versioning (optional): allow user to see history of edits and display older versions
3. Collaborative editing (optional): allow concurrent edits instead of placing an exclusive lock on a document while it is being edited by a user. Concurrent edits will be shown in real time.

* Possible additional milestones

	* authentication of base text
	* integration of NLP tools
	* user generation of concordance

	* block-level critical apparatus
	* variant search capability


Repositories

[Mopane](https://github.com/jensopetersen/mopane)

Concepts

Layers and Perspectives

A TEI text
#
[ANNOTATION:


BY 'Jens Østergaard Petersen'
ON '2013-08-07T17:42:18'
NOTE: 'Handling the variations on the normal text structure should present no problems, but we stick to the common model here.']
normally consists of a <teiHeader> element and a <text> element. The TEI header is not here assumed to be edited using the standoff editor; it can either be composed in an XML editor or (if it is sufficiently standardised) it can be composed using a separate forms-based approach.

The **base text** stored in the <text> element is what the editing process begins with, the base for any subsequent annotations. Beginning with a good text is obviously to be preferred since this minimizes the need for text-altering edits and there the base text ideally consists of a carefully proofread transcription that renders the text stream of a specific exemplar of the
#
[ANNOTATION:


BY 'Jens Østergaard Petersen'
ON '2015-06-27T20:01:01'
NOTE: 'In the case of fragmentary texts, the base text may have to be pieced together from a number of manuscripts.']
work in question.  The base text is marked up with
#
[ANNOTATION:


BY 'Jens Østergaard Petersen'
ON '2013-07-24T19:45:49'
NOTE: 'The use of block-level elements in the base text and the authoritative text is in part based on the practical concern that we prefer to calculate character offsets for shorter spans rather than long spans, and here the spans that paragraphs and suchlike are made up of are handy. It is surely possible to have pure text as base and construct both block-level and inline markup, but then the "scaffolding" of the text would have to be constructed on the fly, whereas if only inline markup is involved, only the "decorations" of the text have to be rendered on the fly. One might say that the block-level markup also reflects the (structural) understanding of the text and that this is based on an interpretation as well and therefore is semantic, but we have to divided rigidly between these two levels here.']
block-level markup
#
[ANNOTATION:


BY 'Jens Østergaard Petersen'
ON '2013-07-30T18:41:20'
NOTE: 'Actually, TEI markup divides into block-level, inline and block-level and inline, that is, some markup (e.g. <figure>) may be used both at block-level and inline.']

#
[ANNOTATION:


BY 'Jens Østergaard Petersen'
ON '2015-06-27T20:19:10'
NOTE: 'Actually, this requirement is unnecessarily strong. Since the string value of the block-level element is used to reference the annotations, it is only necessary to rule out annotations that add to the string value (<note> etc.) or seeks to modify the string value (<app> etc.). Of course, keeping such markup in the base text goes against the idea of using standoff markup, but we might want to moderate this requirement and e.g. allow empty elements containing milestones, such a <pb n="3" facs="3.png"/> used for recording page breaks and linking facsimiles. Page and line breaks are important in the proofreading situation, but can of course be abstracted when proofreading is finished (as in JITM).']
, but containing no
#
[ANNOTATION:


BY 'Jens Østergaard Petersen'
ON '2013-10-22T15:29:17'
NOTE: 'Perhaps at a later date, we will also include block-level markup, but this has its own complications. If one marks up a string as e.g. a name, this has no influence on the presence or absence of any markup on adjacent strings. If one marks up a text, say, as a number of divisions, this markup has to be exhaustive, i.e. one either has to mark up nothing or mark up everything. Since we use a layered approach, it will be possible at a later date to insert the construction of the text with block-level elements.']
inline markup. The base text is required to be [canonical XML](http://www.w3.org/TR/xml-c14n) in order to secure a standard physical representation. The base text is also required to be
#
[ANNOTATION:


BY 'Jens Østergaard Petersen'
ON '2015-06-27T20:21:46'
NOTE: 'Strangely, this is not a requiremenet of canonical XML. It does not matter which normalization form is chosen, but the form used should be recorded in the TEI header.']
Unicode-normalized. The (canonical, normalized) base text will be authenticated by hashes, using standoff markup, and in order to guarantee its stability.
#
[ANNOTATION:


BY 'Jens Østergaard Petersen'
ON '2015-06-27T20:31:33'
NOTE: 'How to deal with diplomatic markup is a problem to be solved. The ideal would be to have two base texts, one with basic structural TEI markup and one with diplomatic markup. The would make it unnecessary to mix up markup regarding the physical appearance of the document with its semantic structure. Since, however, the SARIT project (at present, at least), does not emphasise diplomatic transcription and since it only wants to use empty milestone elements, this appears to be unwarranted.']
The base text will not be modified in the annotation process, only referenced, and serves as the ultimate target for all **annotations**.

There are two kinds of annotation to be handled by the standoff editor: annotations that concern the constitution of the text itself (the graphemes that make up the text), and annotations that concern its interpretation and its physical manifestation in particular documents.

The first kind we call " **text-critical annotation**"; it is typified by the use of the <app> and <choice> elements. Every change here implies a change in the graphemes to be represented in the different versions of the text that are simultaneously encoded in one TEI document. The second kind is all other kinds of markup; since they concern features of the text and a document containing the text, we call it " **feature annotation**".

Feature annotation can concern the physical makeup of the document digitised; this will be called " **document annotation**". Ideally speaking, such diplomatic markup should have its own layer or base text (as in e.g. the [Faust Edition](http://jtei.revues.org/697)), but since such markup is not a major concern for the present project, markup of this kind, such as that noting the various breaks and font face changes in the text as rendered in a specific document (typified by <pb/> and
#
[ANNOTATION:


BY 'Jens Østergaard Petersen'
ON '2014-01-14T00:57:45'
NOTE: 'There is a kind of markup which concerns the formatting of the graphemes, such as <hi>, which does not attempt any interpretation, but simply records the formatting of the graphs. Often, it is preliminary markup, preparatory for "proper" semantic markup, but ideally speaking it should be part of the document (or diplomatic) annotation, since it concerns the basic physical features of the text stream itself, even though it does not alter the text stream itself itself.']
<hi>), will be mixed up with the other feature markup.

The larger part of feature annotation will concern the interpretation of the text and will be termed " **semantic annotation**". It is typified by the use of the <title> and <emph>.

Text-critical annotation can override the base text, creating additional target texts. [Parallel segmentation](http://www.tei-c.org/release/doc/tei-p5-doc/en/html/TC.html#TCAPPS) is used. With parallel segmentation, for every difference between the base text and editions registered, the readings of all editions are noted. In this way, each edition consulted can be a target text.

Parallel segmentation may be used in different ways. One way is to register the genesis of a text, from one edition to another. This approach is most common with modern writings, for which relevant sources are available. Another use is simply to register all variation among different editions, with no attempt to rule which readings are authoritative, the idea being that it is methodologically difficult (or even illegitimate) to try to define one witness to a text as more authoritative than another. A third approach, more common with older (and "classical") texts, is to try to establish, by use of the variation evidenced in witnesses and by conjectural emendation, an authoritative version of a work.

In the first approach one can use <lem> to register the readings in the edition one uses as point of departure - the <lem> readings are thus from one and the same witness to the text. In the the second approach <lem> is not used - every witness is on an equal footing. In the third approach, one can use <lem> to register which witnesses an editor determines belong to the authoritative text - <lem> is thus used to authorise readings from different witnesses or emendations.

In the SARIT project, the third approach is used, and the application to be developed should primarily target this approach, but the application should prepare to accommodate the other two, very common, approaches at a later time. This means that it should be possible, in a later version of the application, to annotate text according to a selected witness. Each TEI document should contain information in its header about which approach is used and which target texts serve as basis for feature annotation.

According to the third approach, by use of an <app> an editor may demote a string of text found in the base text to a reading (<rdg>) and elevate a string of text
#
[ANNOTATION:


BY 'Jens Østergaard Petersen'
ON '2013-10-10T21:19:14'
NOTE: 'The lemma may also be a conjecture, that is, a reading not evidenced in any text, but conjectured to be original. Text-critical markup may also merely provide information about alternate readings from other editions without overriding the base text by use of <lem>. There are questions concerning the relation between conjectural emendations in relation to <app> which need to be cleared up with TEI.']
evidenced in another edition to a lemma (<lem>), with the intention that the lemma should substitute for the reading found in the base text. The use of <lem> is not required as such by parallel segmentation, but in order to generate a single basis for subsequent annotation, it is required in the SARIT implementation. This is probably not a problem, since classical texts are concerned for which the "traditional" idea of reconstituting an original edition is not inappropriate, but for more general and "modern" texts, a setup which allows the annotation of all witnesses, for instance in a genetic edition, will be required. There is the problem that, even though the third approach is used, it may the case that an editor does not feel comfortable, given a number of different readings, to elevate one of them to the status of the authoritative reading. In this case, a fallback witness will take the place of the lemma.

 The SARIT project will need to decide on this issue.

In the display of the text, the base text is merged with corrections made in the text-critical annotation. This virtual text we call the "**
#
[ANNOTATION:


BY 'Jens Østergaard Petersen'
ON '2013-10-10T21:22:13'
NOTE: '"Canonical text" is not used since it signals that a text is universally regarded as authoritative and that it contains an authoritative reference system. If more than one layer of the text can be annotated, we will need to change the name to e.g. "target text."']
****authoritative text**." It is the text that all semantic annotations target.

In this way, there is a " **text layer** ," consisting of the base text, the text-critical annotation, and the authoritative text that results from the application of text-critical annotation to the base text, and a " **feature layer** ," consisting of all other annotations, that is, document annotation and semantic annotation.

The
#
[ANNOTATION:


BY 'Jens Østergaard Petersen'
ON '2013-10-10T21:22:52'
NOTE: 'Text-critical annotations are of course also a perspective, but not regarded as such here.']
annotations made in the feature layer are grouped in what we call " **perspectives**." All annotations concerning names (of people, organisations and places) and dates may thus belong to one perspective and all linguistic annotations to another perspective. The precise number and makeup of the perspectives will have to be worked out by the SARIT project, but it should preferably be customisable.

We can expect it to be possible to merge the annotations belonging to one perspective with the authoritative text, producing an inline TEI authoritative text with feature markup, though overlaps cannot be ruled out and will have to be managed by an editor, but no guarantee should be made that it is possible to merge the annotations belonging to more than one perspective with the authoritative text: instead, separate merges of different perspectives will be offered. This of course also holds for the display: if the user wishes to view several perspectives at the same time, the text blocks would be multiplied, each with its own perspective.

To merge the base text with first text-critical markup, then feature markup, will be more difficult, since more overlaps are to be expected - indeed, the possibility of making such overlaps is one of the reason why standoff markup is used in the first place. If it is made a requirement that inline markup can be round-tripped through standoff markup, the advantages of making an standoff editor are reduce to the ease with with individual annotations can be edited.

The merge of the authoritative text and the semantic annotations into a TEI document belonging to one perspective, we call a " **perspective text** ," and when this perspective text is converted into HTML, we call the result a " **perspective display**."

It should be possible to generate the authoritative text for exchange or for use in NLP applications.

It should be possible to display and generate a version of the base text that embodies any edition (using the @wit attribute in <rdg> and <lem>), not necessarily the authoritative (<lem>) text, for exchange or for use in NLP applications.

Base Text and Annotation

The base text may only contain
#
[ANNOTATION:


BY 'Jens Østergaard Petersen'
ON '2013-07-22T20:40:09'
NOTE: 'What would be the complications if empty elements were allowed? Empty elements reflecting the physical page (pb, lb, cb) are very valuable when proofreading, for generating references and displaying facsimiles, and they should ideally not be deleted. Of course, they could be abstracted into a separate annotation layer, but if they could be maintained inside the base text, this would be ideal.']
block-level elements, including the TEI elements div, head, p, lg, l, seg. The block-level elements may carry attributes. Each block-level element is
#
[ANNOTATION:


BY 'Jens Østergaard Petersen'
ON '2013-10-10T21:59:21'
NOTE: 'If texts have ids already, we should conserve them, but have to make sure that they are unique among all SARIT texts.']
assigned a unique id, which is required to reference the block from the standoff markup. Though it would be handy to use UUIDs for this purpose, a [reference system](http://www.tei-c.org/release/doc/tei-p5-doc/en/html/CO.html#CORS) will probably be used, to be devised by SARIT.

 The annotations are stored
#
[ANNOTATION:


BY 'Jens Østergaard Petersen'
ON '2013-07-30T18:49:17'
NOTE: 'They could be stored inside a top-level TEI element in the same TEI document that contains the base text, though there is a present no top-level element for this purpose. Probably, we will want to store each annotation as a Atom feed, as separate documents altogether. One might suggest that it should be possible to roll all annotations into one element (like <standOff>, suggested by Banski as a top-level TEI element).']
outside the base text, using reference ids and character offsets.
#
[ANNOTATION:


BY 'Jens Østergaard Petersen'
ON '2013-07-30T18:28:14'
NOTE: 'Here we utilise the basic approach of OAC. How far the TEI Editor should be inter-operative with OAC <http://www.openannotation.org/spec/core/core.html> should be discussed.']
They are stored with one top level element carrying information about the target in the authoritative text and one top level element carrying information about the body of the annotation.

 The target of an annotation can be
#
[ANNOTATION:


BY 'Jens Østergaard Petersen'
ON '2013-10-10T22:06:37'
NOTE: 'It may also be a point (between two characters), a point (following a space) and an element node.']
a character range. In

<l xml:id="MB.div.2-div.3-sp.16-l.1">All hail, Macbeth! hail to thee, thane of Glamis!</l>

one could pick out the string "Macbeth" by the xml:id of the block-level element and the character range of its text node, and wrap it up in the TEI <name> element.

    <annotation type="element" target="text" perspective="naming"

        xml:id="uuid-e3bd821b-dc44-41db-8029-92328b4c62822">

        <target type="range">

            <start>

                <id>MB.div.2-div.3-sp.16-l.1</id>

                <position>11</position>

            </start>

            <end>

                <id>MB.div.2-div.3-sp.16-l.1</id>

                <position>17</position>

            </end>

        </target>

        <body>

            <tei:name>Macbeth</tei:name>

        </body>

    </annotation>

#
[ANNOTATION:


BY 'Jens Østergaard Petersen'
ON '2013-07-30T18:53:15'
NOTE: 'Obviously, a more stringent typology will have to be defined.']
The annotation has the type "element" since it adds an element (not an attribute) to its target. Its target is "text" (not "element" - an attribute annotation would have target "element"), and the perspective is here termed "naming." The annotation has its own xml:id, since subsequent annotations may e.g. supply it with attributes.

The target element has type "range" or "element", like the annotation of a child element would have) and it runs from the start to the end of the text range.

The body element tells what is to substitute for the character range, here the element "tei:name" and its contents, "Macbeth". Since the name element merely wraps up the string in a tag, it does not add any contents (like e.g. a <note> element would) and since tei:name allows text contents, it does not require a further element annotation (like <app> would do, since <app> does not allow text contents, but requires an element such as <rdg>).

 When the perspective text is generated by merging the authoritative text (here, identical to the base text since there are no text-critical annotations) and this semantic annotation, the result is

 <l xml:id="MB.div.2-div.3-sp.16-l.1">

All hail, <name>Macbeth</name>! hail to thee, thane of Glamis!

</l>

In the perspective display, names may e.g. be rendered with a certain colour using CSS,

 <div class="line" xml:id="MB.div.2-div.3-sp.16-l.1">

All hail, <span class="name">Macbeth</span>! hail to thee, thane of Glamis!

</div>

If we now want to state that the name "Macbeth" is of type "person", we could make an annotation to the above annotation, but - for reasons of simplicity - we merely edit it, adding an attribute to the existing element.

    <annotation type="element" target="text" perspective="naming"

        xml:id="uuid-e3bd821b-dc44-41db-8029-92328b4c62822">

        <target type="range">

            <start>

                <id>MB.div.2-div.3-sp.16-l.1</id>

                <position>11</position>

            </start>

            <end>

                <id>MB.div.2-div.3-sp.16-l.1</id>

                <position>17</position>

            </end>

        </target>

        <body>

            <tei:name type="person">Macbeth</tei:name>

        </body>

    </annotation>

This would result in the following perspective text,

 <l xml:id="MB.div.2-div.3-sp.16-l.1">

All hail, <name type="person">Macbeth</name>! hail to thee, thane of Glamis!

</l>

Both an element and its attributes, including their contents, will be input in one and the same popup, and they will be stored as that as well: there is no need to carry the standoff approach to extremes.

 Let us look at another, more complicated, example. Let us assume that the base text reads:

 <l xml:id="HAM.div.2-div.3-sp.16-l.1">

Get thee a nunnery: why wouldst thou be a breeder of sinners?

</l>

This is the Q2 edition; the Folio edition reads "to a nunnery," and we believe this to be the correct reading, which could be expressed in TEI in the following manner:

 <l xml:id="HAM.div.2-div.3-sp.16-l.1">

Get thee

<app>

<lem wit="#F">

to

</lem>

<rdg type="omissio" wit="#Q2"/>

                        </app>

a nunnery: why wouldst thou be a breeder of sinners?

</l>

In the display text, this would result in the following:

<div class="line" xml:id="HAM.div.2-div.3-sp.16-l.1">

Get thee to a nunnery: why wouldst thou be a breeder of sinners?

</div>

Here the annotation concerns a whole word and this means (in this language and this script) that an extra space has to be supplied. In order to signal this processing need, the annotation is of type "token".

<annotation type="element" target="text" perspective="edition"

        xml:id="uuid-e3bd821b-dc44-41db-8029-92328b4c62822" type="token">

        <target>

            <start>

                <id>HAM.div.2-div.3-sp.16-l.1</id>

                <position>9</position>

            </start>

            <end>

                <id>HAM.div.2-div.3-sp.16-l.1</id>

                <position>9</position>

            </end>

        </target>

        <body>

            <tei:app/>

        </body>

</annotation>

The result of this annotation in the authoritative text would be

 <l xml:id="HAM.div.2-div.3-sp.16-l.1">Get thee <app></app> a nunnery: why wouldst thou be a breeder of sinners?</l>

The element <app> does not allow text, so it requires one to immediately wrap up the selection (here a point) in another element, typically <rdg> or <lem> (but also e.g. <note>).

<annotation type="element" target="annotation" perspective="edition"

    xml:id="uuid-e3bd821b-dc44-41db-8029-92328b4c62822">

    <target type="text-node">

        <id>uuid-e3bd821b-dc44-41db-8029-92328b4c62822</id>

    </target>

    <body>

        <tei:rdg type="ommisio"/ wit="#Q2"/>

    </body>

</annotation>

The target is the whole contents of the body of the tei:app annotation. We have added two attributes, and this gives:

 <l xml:id="HAM.div.2-div.3-sp.16-l.1">

Get thee

<app>

<rdg type="omissio" wit="#Q2"/>

</app>

a nunnery: why wouldst thou be a breeder of sinners?</l>

We now add the lemma with its wit attribute:

<annotation type="element" target="annotation" perspective="edition"

    xml:id="uuid-e3bd821b-dc44-41db-8029-92328b4c62822">

    <target type="text-node">

        <id>uuid-e3bd821b-dc44-41db-8029-92328b4c62822</id>

    </target>

    <body>

        <tei:lem wit="#F">to</tei:lem>

    </body>

</annotation>

The result will then be:

 <l xml:id="HAM.div.2-div.3-sp.16-l.1">

Get thee

<app>

<lem wit="#F">

to

</lem>

<rdg type="omissio" wit="#Q2"/>

                        </app>

a nunnery: why wouldst thou be a breeder of sinners?

</l>



Rendering of Text and Annotations

All block-level TEI elements will be rendered as block-level (~ flow content in HTML5 palance) HTML elements, whereas all feature annotations will be rendered as inline  (~ phrase content) HTML elements and popups.

 When the functions generating the merge of the base text and the text-critical annotations and the authoritative text and semantic annotations encounter overlaps, these can be of several kinds:

- ¢ÂÂ¢ÂÂthere are two annotations targeting the same range or point
- ¢ÂÂ¢ÂÂthere is one annotation which could lie within another annotation



Links

- ¢ÂÂ¢ÂÂImplementations

- ¢ÂÂ¢ÂÂ [Digital Thoureau](http://www.digitalthoreau.org/)
  - ¢ÂÂ¢ÂÂ [XML Toolkit](https://docs.google.com/document/d/1V6LumIYOdw4dkEAOVJtCLmHspgAQENDSv5N3l7OV9nU/edit)
  - ¢ÂÂ¢ÂÂ [Higher Laws](http://digitalthoreau.org/walden/higherlaws/text/11_higherLaws_interpretive.xml)

- ¢ÂÂ¢ÂÂRonny's Giddy Geeky Blog
  - ¢ÂÂ¢ÂÂ [Venturing into versions: strategies for querying a TEI apparatus with eXist](http://rvdb.wordpress.com/2011/04/20/venturing-into-versions-strategies-for-querying-a-tei-apparatus/)

- ¢ÂÂ¢ÂÂHRIT
  - ¢ÂÂ¢ÂÂ [standoff](https://code.google.com/p/hrit/source/checkout?repo=standoff)
  - ¢ÂÂ¢ÂÂ [restlet](http://hrit-maven.etl.luc.edu/webapp/browserepo.html)

- ¢ÂÂ¢ÂÂHugh Cayless
  - ¢ÂÂ¢ÂÂ [tei-string-range](https://github.com/hcayless/tei-string-range)

- ¢ÂÂ¢ÂÂPhil Berrie
  - ¢ÂÂ¢ÂÂ [JITM](http://hass.unsw.adfa.edu.au/ASEC/current_projects/jitm/jitm-publications.html)

- ¢ÂÂ¢ÂÂDiscussions
  - ¢ÂÂ¢ÂÂBaÂski
    - ¢ÂÂ ¢ÂÂ  [Why TEI stand-off annotation doesn't quite work - and why you might want to use it nevertheless](http://www.balisage.net/Proceedings/vol5/html/Banski01/BalisageVol5-Banski01.html)

  - ¢ÂÂ¢ÂÂHugh Cayless
    - ¢ÂÂ ¢ÂÂ  [On Implementing string-range() for TEI](http://www.balisage.net/Proceedings/vol5/html/Cayless01/BalisageVol5-Cayless01.html)

  - ¢ÂÂ¢ÂÂTEI resources
    - ¢ÂÂ ¢ÂÂ  [Stand-off markup](http://wiki.tei-c.org/index.php/Stand-off_markup)

  - ¢ÂÂ¢ÂÂxstandoff.net
    - ¢ÂÂ ¢ÂÂ  [SGF - An integrated model for multiple annotations and its application in a linguistic domain](http://www.balisage.net/Proceedings/vol1/html/Stuehrenberg01/BalisageVol1-Stuehrenberg01.html)
    - ¢ÂÂ ¢ÂÂ  [A toolkit for multi-dimensional markup](http://www.balisage.net/Proceedings/vol3/html/Stuhrenberg01/BalisageVol3-Stuhrenberg01.html)





Questions

The editor code needs to make sure that the resulting, serialized TEI remains well-formed and valid. To some extent, the serialization process could probably deal with conflicting markup, e.g. by splitting an inline element which span across other tag boundaries. We have to make explicit which conflicts can be handled though.

It is thus not allowed for an annotation to include only parts of another annotation on the same perspective. For example, if an author annotates a span of text as a term and then wants to include this span inside an app annotation,
#
[ANNOTATION:


BY 'Jens Østergaard Petersen'
ON '2013-07-22T16:59:48'
NOTE: 'This concerns serialisation. Part of the advantage of standoff markup is that overlaps are possible. We should not rule out overlaps, just because they make serialisation problematic. At some point the question must come up, whether the restrictions of inlining are worth the pain, but probably strict rules should be enforced for text-critical markup.']
it has to be made sure that the entire term is part of the app's lemma?

It should also not be possible for a text critical annotation to run across block-level elements except when
#
[ANNOTATION:


BY 'Jens Østergaard Petersen'
ON '2013-07-22T17:01:14'
NOTE: 'It should be possible to annotate a span of text straddling two blocks - in this case, the first common ancestor of the two blocks that contain the text should be used for identification (well, this should be the general rule, actually).']
 entire block-level elements are included?

It should be possible for an annotation to address an element as such, not its contents. One would say that an attribute targets its element "as such".

How to deal with elements which represent choices (app and choice)? Users may want to annotate a term inside an alternative reading. From a user interface perspective this would be possible by allowing the user to select the alternative reading for display, then mark it up. However, how would the annotation reference the reading (which does not exist in the base text)?
#
[ANNOTATION:


BY 'Jens Østergaard Petersen'
ON '2013-07-22T17:59:45'
NOTE: 'Yes, an annotation to an annotation always refers directly to the annotation it annotates and only indirectly to the text. If we (for a moment) look outside the (narrow) confines of TEI, this will also allow the users to discuss the markup.']
For sure we would need to tell the annotation that it refers to another annotation, not the base text?

Technology

#
[ANNOTATION:


BY 'Joern Turner'
ON '2013-07-23T18:20:46'
NOTE: 'Though this approach is surely possible to a certain extend it also makes us quite dependent on the choosen editor - most of the framework i've seen seem to be to fat and inflexible to base a complete set of extension upon them.'
NOTE: ''
NOTE: 'I see an alternative approach in using the native DOM of the browser directly, 'activating' a certain range and creating the appropriate toolbox and controls just in time.'
NOTE: ''
NOTE: 'With web components we can even create extension elements for TEI elements and represent them directly in the browser as e.g. tei-note']
If we restrict the base text to basic block-level elements, we can probably use a standard HTML editor, whose HTML output we can control (e.g. wysihtml5).

Since selection of Devanagari script in an ordinary browser display is impossible, due to cursor offsets, selection will have to done in e.g. texteditable (where selection presents no problems).

What is edited will always be strings only, that is, text nodes inside elements and string values of attributes. The editor does not have to handle markup. If a note is to be inserted, a window will open up and the contents of the note can be entered. The contents of any attribute will be stored separately, but of course the form for entering notes will also allow the entry of the corresponding attributes. Still, this is strictly forms-based, since attributes are "dead ends" and do not allow elaboration.

The editor only has to know the character range of the selection in relation to the first common ancestor.

When choosing technologies, we must keep authentication in mind (AD, OpenID).

We should ideally choose a technology which allows the user to make selections that straddles blocks and that allows empty elements.

#
[ANNOTATION:


BY 'Joern Turner'
ON '2013-07-30T19:19:30'
NOTE: ':) Sorry this is a bit of a general requirement. Esp. for us not knowing that language. What's special about this language - where does it differ etc.?']
It must be able to handle Devanagari.
#
[ANNOTATION:


BY 'Jens Østergaard Petersen'
ON '2013-07-30T19:19:30'
NOTE: 'I don't know Sanskrit either. The editor has to be able to work reliably with the code points used (U+0900–U+097F, U+A8E0–U+A8FF, U+1CD0–U+1CFF), that's all. Luckily, it is a left-to-right writing system!']

For the markup of the annotation perspectives we may want to look at web components and in particular at the "Custom Elements" specification:

[https://dvcs.w3.org/hg/webcomponents/raw-file/tip/spec/custom/index.html](https://dvcs.w3.org/hg/webcomponents/raw-file/tip/spec/custom/index.html)

Google recently released a javascript library which adds support for custom elements to standard browsers:

[http://www.polymer-project.org/platform/custom-elements.html](http://www.polymer-project.org/platform/custom-elements.html)

Todo

- ¢ÂÂ¢ÂÂCollect a list of annotation types we would like to support, along with usage examples
- ¢ÂÂ¢ÂÂDefine the block-level elements to be supported
- ¢ÂÂ¢ÂÂCreate a set of base texts we can use for testing
- ¢ÂÂ¢ÂÂClarify representation of TEI document in HTML5. How does the mapping look like?
- ¢ÂÂ¢ÂÂClarify editing needs with regard to data typing and editing logic (element-specific editors/components?)
- ¢ÂÂ¢ÂÂjt+: clear definition of perspectives and their relationships. Definition of central terms (partly done in this document above). Ideally graphical overview of the layers.



#
[ANNOTATION:


BY 'Joern Turner'
ON '2013-07-30T19:16:03'
NOTE: 'I think we'll see if this is a strict requirement. If the editor later on by design does not manipulates the base text it's probably 'work for the arts'.']
In order to guarantee the stability and reliability of the base text
#
[ANNOTATION:


BY 'Jens Østergaard Petersen'
ON '2013-07-30T19:16:03'
NOTE: 'Could be. This is inspired by the Just In Time Markup, where merges could not happen if the base text digest was not identical with the value of the base text digest stored in the annotation.']
after the last proofreading, each text node is digested and its md5 value inserted in an attribute. All elements with no text node (that is, all other elements) contain digests of the digests of their child elements, culminating in the TEI text element which contains a digest for the complete base text.



Edited above - no need to read further on!

SARIT has sent me three representative TEI files. I have coalesced the dtd covering their text nodes:

<!ELEMENT body (#PCDATA | pb | head | lg | trailer)\*>

<!ELEMENT app (#PCDATA | rdg)\*>

<!ELEMENT trailer (#PCDATA | app | p)\*>

<!ELEMENT text (#PCDATA | body)\*>

<!ELEMENT persName (#PCDATA)>

<!ATTLIST persName ref CDATA #IMPLIED>

<!ELEMENT div (#PCDATA | pb | head | lg | p | trailer)\*>

<!ATTLIST div type CDATA #IMPLIED>

<!ATTLIST div n CDATA #IMPLIED>

<!ELEMENT l (#PCDATA | seg | app | note)\*>

<!ELEMENT ref (#PCDATA | app)\*>

<!ATTLIST ref type CDATA #IMPLIED>

<!ATTLIST ref cRef CDATA #IMPLIED>

<!ELEMENT title (#PCDATA)>

<!ELEMENT seg (#PCDATA | app | q | persName)\*>

<!ATTLIST seg type CDATA #IMPLIED>

<!ELEMENT quote (#PCDATA | app | pb)\*>

<!ELEMENT pb (#PCDATA)>

<!ATTLIST pb n CDATA #IMPLIED>

<!ATTLIST lg xml:id CDATA #IMPLIED>

<!ELEMENT lg (#PCDATA | l)\*>

<!ATTLIST lg cRef CDATA #IMPLIED>

<!ELEMENT q (#PCDATA)>

<!ELEMENT p (#PCDATA | app | ref | pb | cit | q | note | title)\*>

<!ELEMENT rdg (#PCDATA | note | cit)\*>

<!ATTLIST rdg wit CDATA #IMPLIED>

<!ELEMENT cit (#PCDATA | quote | ref)\*>

<!ELEMENT head (#PCDATA | p)\*>

<!ELEMENT note (#PCDATA | q)\*>

<!ATTLIST note place CDATA #IMPLIED>

This is quite simple, but the inline markup has to be extracted from the files they have (I understand they are quite different - the files have been keyed by an Indian company and is quite basic). I have looked at < [xstandoff.net](http://xstandoff.net)> and the stylesheet they supply for this and it seems to work OK for smaller text segments. It requires two runs, one to establish a pure-text version and one to generate the standoff markup. There should be a workflow that performs this transformation and furthermore converts their standoff format to ours.

#
[ANNOTATION:


BY 'Jens Østergaard Petersen'
ON '2013-10-11T14:22:17'
NOTE: 'derived from mail to SARIT group']
The standoff approach and TEI

TEI utilises standoff markup already, mainly for annotations which are hard to implement using inline markup. What we are proposing to do is to mark up texts with standard TEI annotations using standoff markup alone, that is, only use standoff markup.

In the TEI world, the idea of implementing standoff markup crops up regularly. It is generally viewed as difficult to implement, even though significant advances and prototypes were already in place at the turn of the century < [http://web.archive.org/web/20130420041631/http://hass.unsw.adfa.edu.au/ASEC/PWB\_REPORT/index.html](http://www.google.com/url?q=http%3A%2F%2Fweb.archive.org%2Fweb%2F20130420041631%2Fhttp%3A%2F%2Fhass.unsw.adfa.edu.au%2FASEC%2FPWB_REPORT%2Findex.html&sa=D&sntz=1&usg=AFQjCNHveC-fduFSysa-GNwEsq1LMOZB-w)>.

Using standoff markup is in our view the only practical way to mark up scholarly texts with complicated TEI annotation in a collaborative setting and the only practical way of encoding differing perspectives on the same text. It is also the only practical way of ensuring the stability and reliability of the texts upon which markup is elaborated, an aspect which should be crucial for all text encoding projects, but which is not addressed at all by the TEI Guidelines and which cannot easily be ensured using inline markup.

Through in theory standoff markup may be applied to any TEI text, also a text which is marked up using inline markup, we propose basing markup on texts with a bare skeleton of TEI markup (very similar to that made by SWIFT Information Technologies). This can in theory either be basic structural markup or page-and line-oriented markup (to facilitate proofreading), but we will use the first, standard, approach.

We plan to make it possible to extract markup from inline-encoded TEI files, allowing reuse of traditional TEI files in the new setting. How to integrate standoff markup with the automatic tagging envisaged by the project is a problem that will need to be addressed later.

Basically, the standoff approach marks up by referring to spans of text, identifying these spans by their position inside elements with an xml:id. Spans can go from one element to another, allowing a structural re-constitution of the text or tracing a sentence across several lines.

Since markup if most often recursive, one annotation will serve as basis for another annotation, either establishing a child element or an attribute to the element defining the annotation. Annotation will thus be a step-by-step process, entering information in one node at a time. Users will receive schema-derived hints telling what it is possible to insert at a given place.

In order to make possible search in a text for information that is stored in standoff markup (which by definition is not in the text and therefore normally cannot be retrieved), the Lucene index for the text will have injected index items at node level derived from the standoff annotation. In this way, one can "find something which is not there", retrieving e.g. a phrase with a text variant which occurs only in a standoff file, even when searching the base text.

Benefits of using standoff markup

**The integrity of the base text can be guaranteed.**

The text one has paid for to have input and proofread (or which one has input and proofread oneself), the text upon which the academic value of the whole project in the final instance rests upon, is extremely difficult to control from accidental alterations with inline markup. Inserting markup continually involves breaking text strings and there is really no way of safeguarding against wanton deletions or insertions of characters, especially since text that has been marked up can be extremely hard to proofread. With standoff markup, the text one is annotating can be kept read-only and it is possible to guarantee, through the use of hashes, realised as standoff annotations, that one will be alerted should any change occur. The same applies to any layer of the text that is the result of modifications made by the critical apparatus.

If changes are to be made in the base text, this can be done in a controlled manner, adjusting the standoff markup for a single segment.

**The base text can serve as canonical reference**

Injecting project-specific markup in texts that are to serve as a reliable and neutral reference for other projects is not a good idea. With standoff markup a meticulously proofread base text can serve as canonical reference, since it is not saturated with project-specific interpretations. The critical apparatus and feature markup may of course themselves achieve canonical status, but this will be easier to achieve if the perspectives are kept separate.

**It is possible to encode overlapping perspectives on the text**

Commonly occurring overlapping perspectives include structural and basic semantic markup on the one hand and physical and text-critical markup one the other hand. To integrate these with inline markup in a single document quickly makes the document so complicated that the text, chopped up in illogical ways, becomes unworkable. If TEI's text-critical markup is to be used on a large scale, along with markup for names, terms and citations, using the standard approach may be extremely difficult. Since the project wishes to lemmatize all words, this consideration becomes even stronger.

Aside from such more basic markup, different perspectives may also include linguistic markup over phrase and sentence units as well as markup expressing literary interpretation. Using standoff markup one can encode these perspectives separately and either display them one by one or several perspectives at the same time. If one wishes to integrate them in an inline document, this is to some extent possible in an automatic way, but may require human intervention to resolve overlaps.

Since, with standoff markup, one is relieved of the restrictions inherent in XML, it will become an issue whether or not to take advantage of the possibilities of the standoff approach or whether to keep the standoff markup so tightly regimented that it can always be inlined. Attributes will e.g. be entered into elements in the annotation structures and therefore do not have obey the same rules about character contents and absence of internal markup, so it become tempting to treat them more "leniently" (as elements), though one thereby loses the possibility of presenting one's text as a standard TEI document.

**It is possible for several persons to mark up one text at the same time**

With standoff markup, there are no concurrency or lock problems. Not only is concurrent markup possible online, but also offline markup, since the base text is fixed and the same for all, and since perspectives can be mixed from several sources, either before or during display with distributed markup.

**It is easy to accommodate standoff markup to a hierarchical organization and to a teaching situation**

All annotations will be signed and trainee markup can be approved by editors before it is displayed to the public. This is extremely difficult to achieve using inline markup. Note also that markup may also, with some slight relaxations of the schema, contain internal notes exchanged between students and teachers or, generally, between different annotators. Markup may in this way function as project communication, in a blog-like format. - We are here approaching the wider area covered by e.g. Open Annotation Collaboration.

**It is easy to control access to the various perspectives associated with a text**

Online users may choose between different perspectives, not necessarily seeing all at the same time on a cluttered screen, but only those of interest. Certain perspectives may easily be blocked for users belonging to certain groups.

**It is easy to integrate non-TEI vocabularies**

Annotation using [Open Annotation Collaboration](http://www.openannotation.org/), the most active agent in the field of academic standoff markup, can easily be integrated with TEI standoff markup, as can markup using other vocabularies, as well as semantic markup utilising RDF.

**Copyright can be asserted in a differential way**

Copyright can be asserted separately for the base text and for different annotation perspectives, allowing all contributors to a edition to be credited, and possibly open-sourcing large parts of the edition.

**It is easier to process texts with standard NLP tools if the markup is separate**

Of course, NLP tools could create the different layers themselves, but often they cannot do this, so feeding them with data will be easier with this standoff approach.

TEI typologies

TEI elements are

- ¢ÂÂ¢ÂÂblock-level if they
  - ¢ÂÂ¢ÂÂcannot contain text nodes, only element nodes, or
  - ¢ÂÂ¢ÂÂtheir parent cannot contain text nodes, only element nodes

- ¢ÂÂ¢ÂÂinline if they
  -

#
[ANNOTATION:


BY 'Jens Âstergaard Petersen'
ON '2014-02-03T22:24:28'
NOTE: 'TEI has no simpleContent (in XML Schema parlance), i.e. there is nowhere in TEI where you can have text where you cannot have elements, except for the "meta-tags" <att> (attribute) which contains the name of an attribute appearing within running text and <gi> (element name) which contains the name (generic identifier) of an element.']
can contain text nodes/mixed contents

The contents of an element are the character data and child elements that are between its tags. The order and structure of the children allowed by a complex type are known as its content model. There are four types of content for complex types: simple, element-only, mixed, and empty.

Doing a string-join() on the tei:text element obviously does not give the text that a TEI document renders.

The TEI text stream divides into

- ¢ÂÂ¢ÂÂtext that belongs to the text stream
  - ¢ÂÂ¢ÂÂthis is of course the larger part of the string contents; it can be marked up by feature annotation which does not alter the tex stream, but "decorates" it

- ¢ÂÂ¢ÂÂtext that forks
  - ¢ÂÂ¢ÂÂTEI can represent several versions of the same text, so the text stream forks when encountering elements like <app> or <choice>

- ¢ÂÂ¢ÂÂtext that is placed in the text stream at a point different from where they belong
  - ¢ÂÂ¢ÂÂnotes e.g. may be original with the text rendered, but though they "belong" to the footer, they are represented inline, possibly with a marker stating where they belong

- ¢ÂÂ¢ÂÂtext which is part of the markup - would have been placed in an attribute if that was possible
  - ¢ÂÂ¢ÂÂthe caption to a figure may not be original with the text rendered

What belongs to a certain part of the text stream can only be decided in relation to a specific document, therefore each TEI document must have a representation in its header telling which criteria to apply to sort out the different parts

Query flow

base text (block-level TEI)

+

text-critical annotations

=

target text (block-level TEI)

+

feature annotations

=

goal document

TEI (block-level + inline TEI) version

HTML (div + span) version

Each time annotations are applied, the following code is involved.

app.xql

tei2:tei2html()

 tei2:tei2div()

  tei2:tei2html()

tei2:get-a8ns()

tei2:build-up-annotations()

 local:insert-elements()

tei2:collapse-annotations()

 tei2:collapse-annotation()

tei2:mesh-annotations()

tei2:header()

 tei2:tei2html()
Rendered
Standoff TEI Editor
Steps

Step 1

Step 2

Editor requirements

Selection

Annotation and Text

Kinds of annotation

Text layers

Annotation targets

Annotation formats

Schema-derived information

Milestones

Repositories

Concepts

Layers and Perspectives

Base Text and Annotation

Rendering of Text and Annotations

Links

Questions

Technology

Todo

The standoff approach and TEI

Benefits of using standoff markup

Steps

Step 1

The browser displays an XHTML div, outfitted with an @xml:id. It is of course a transform of a TEI paragraph, but since it contains text only, this is of no consequence.
My name is Jim.
This is simply displayed as

My name is Jim.

with no special styling.

The user makes a selection, selecting e.g. the string "Jim".

A window opens, presenting a dropdown with e.g. the options "name" and "emph" (for emphasis).

The user selects "name", submits, and the following document is created,

<annotation type="element" xml:id="uuid-3a8308b6-660a-422c-a45a-4c9413207208" status="string">

    <target type="range" layer="feature">

            <id>uuid-04835aeb-3b31-43e7-aca1-4d904ddc86e4</id>

            <start>12</start>

            <offset>3</offset>

    </target>

    <body>

        <name/>

    </body>

</annotation>
This leads to the virtual markup of the original string, e.g. colorizing "Jim" and displaying "name" in a clickable popup when hovering over "Jim".

The XQuery to effect this transform is contained in standoff2inline.xq, but constructs TEI, whereas XHTML will have to be constructed here (work for Jens).

The display of the paragraph is always virtual. "

My name is Jim.
" is the result of the TEI to XHTML transform, but on top of this lies a transform that mixes the bare text in the paragraph with the markup. This will be in the form of s with the xml:id of the annotation that selects a string range as their xml:id, allowing the tree of annotations to be retrieved, something like
My name is Jim.
Clicking a display of "name" in this popup opens the same window that was used to make the annotation.

The user can change the selection in the popup and save the changed annotation, with "emph" instead of "name" in the body.

The user can add an attribute. If "name" has been selected, the attributes "type" and "subtype" can be selected from a dropdown, and given the value "person" or "place" from a dropdown.

Submitting, the following annotation is created:


        <target type="element" layer="annotation"

            >uuid-3a8308b6-660a-422c-a45a-4c9413207208</target>

        <body>

            <attribute>

                <name>type</name>

                <value>person</value>

            </attribute>

        </body>

    </annotation>
That is, there are now two annotations, one telling that the string "Jim" should be wrapped in the element and one telling that this element has an attribute @type with the value "person". The second annotation refers to the first which then refers to the string range in the element with the @xml:id noted. Nothing is stored inside the paragraph; the display is built on-the-fly.

When hovering over "Jim", a popup should appear, telling that has been applied and that this has the attribute @type with the value "person". Clicking this should open the same window, allowing the user to make changes.
Step 2

Same as step 1, except

¢ÂÂ¢ÂÂa point is selected, either by selecting two characters and specifying that the point between them is intended or by inserting the cursor (e.g. in contenteditable)
¢ÂÂ¢ÂÂinstead of "name" and "emph", a dropdown with "note" (with attribute @type) and "lb" (line break) (with attribute @n)
¢ÂÂ¢ÂÂinstead of wrapping a string from the base text in an element, an element is inserted at a point and this element has text contents in the case of "note" but no contents in the case of "lb". 
¢ÂÂ¢ÂÂthe target is specified (by convention) as 80, which is meant to refer to the point after character 8.
Step 3

(to come …)

Editor requirements

Selection

All text is enclosed in TEI block-level elements, for instance

and
. Each block-level element has an @xml:id. The text is immutable, that is, it will not be changed, only annotated. All annotations have an @xml:id.

There are the following kinds of selection, presented in order of importance (and possibly implementation):

1.A span of text in a single block-level element is selected, in order to enclose it in an element, and the @xml:id and the start position and character offset of the selection in relation to the block-level element are captured
2.An element annotation is selected in order to edit its name
3.An element annotation is selected, in order to add a child element, a text node or an attribute to it; its @xml:id is captured to provide a basis for this
4.A span of text in an annotation text node is selected, in order to enclose it in an element, and the @xml:id of the annotation and the start position and character offset of the selection are captured 5.
#
[ANNOTATION:

BY 'Joern Turner'
ON '2014-02-05T16:10:25'
NOTE: 'zero-length annotation?!']
A point between two characters is selected in a block-level element or an annotation body, in order to position an empty element or an element with a text node
#
[ANNOTATION:

BY 'Jens Âstergaard Petersen'
ON '2014-02-05T16:10:25'
NOTE: 'the insertion of an element at a point, i.e. between two characters. This could either be an empty element such as to mark a line break or an element with a text node such as a .']

6.A block-level element is selected as such, in order to add attributes to it
7.A span of text starting in one block-level element and ending in another block-level element is selected, in order to enclose it in an element, and the @xml:id of the first common ancestor of the two block-level elements and the start position and character offset of the selection in relation to this ancestor are captured
Annotation and Text

Kinds of annotation

There are two kinds of annotation:

1.Annotations that affect the text stream; these consist of text-critical annotations, typified by and . By means of these annotations, TEI encodes several text versions at the same time, making the text fork each time the text stream passes through them.
2.The remaining annotations that do not affect the text stream, but "decorate" text spans; these consist of
a.inline feature markup
b.attributes
Text layers

A TEI project starts with the transcription of a text. This transcription is, in the framework of the standoff editor, fixed and immutable. Since the idea behind the standoff editor is to encode all inline markup in standoff annotations, the transcription consists of text in block-level markup with @xml:ids as the only "inline" annotation.

The transcription is stored as canonicalized XML. The stability of the transcription is guaranteed by (automatically applied) hash annotations that first target each text node and then target the hashes of the block-level hash annotations in document order. This ensures that no changes can occur unnoticed. Once a transcription has been established, the text can only change through text-critical annotations.

The transcription is called "the base text" and a text established through text-critical annotations is called "the target text."

A target text is virtual, constructed on the fly by applying the text-critical annotations to the base text. Like the base text, it consists of text in block-level TEI elements only, with @xml:ids as the only attributes.

Text-critical annotations always target the base text. Different target texts are possible, so each feature annotation must refer to a specification of how the target text is constructed - this specification must be in the TEI header, but exactly how this is to be done is unclear at the moment.

This means that the first choice the annotator has to make is whether

1.to view the base text in order to make text-critical annotations, or
2.to view a target text in order to make feature annotations, this implying
a.selecting a target text
There will be misalignments if feature annotations are made to a target text which is then subsequently modified. The proper editing sequence is thus

1.make a transcription
2.make text-critical annotations
3.make feature annotations
This sequence will be assumed during the project, but in practice such changes will perhaps be unavoidable, so some procedure has to be introduced later on to take care of this.

Annotation targets

There are the following targets of annotation:

1.Element annotations which either

a.target a span of text, localised by range
b.target another element, localised by document order
2.Attribute annotations

Annotation formats

An annotation consists of a target, a body and administrative data.

A feature annotation targeting a text range looks like this:

    <annotation type="element"

        xml:id="uuid-3a8308b6-660a-422c-a45a-4c9413207208" status="string">

        <target type="range" layer="feature" layer-ref="lem">

                <id>uuid-4f71d797-0d51-35cb-86b0-e283afdf889a</id>

                <start>48</start>

                <offset>3</offset>

        </target>

        <body>

            <name xmlns="http://www.tei-c.org/ns/1.0"/>

        </body>

        <admin-data>

            <creation>

                <user>guest</user>

                <time>2014-01-02T16:26:06.622+01:00</time>

                <note/>

            </creation>

            <review>

                <user/>

                <time/>

                <note/>

            </review>

            <imprimatur>

                <user/>

                <time/>

            </imprimatur>

        </admin-data>

    </annotation>
It is of @type "element" since it results in the markup of an
#
[ANNOTATION:

BY 'Jens Østergaard Petersen'
ON '2014-02-02T18:30:10'
NOTE: 'Its target is a string, hence @status "string". Is this necessary?']
element.

The target of the annotation is of @type "range", since it specifies a text range in the text node identified by the @xml:id of the block-level element. The @layer is "feature", so we are dealing with a target text. The @layer-ref "lem" identifies the layer annotated; a definition of "lem" is found in the header of the document, in the form of an XQuery function which produces the target text by applying the text-critical annotations to the base text.

The body here specifies what is to be added to the target text.

The annotation thus tells that the element is to be wrapped around characters 48-50 of the text node identified by the @xml:id "uuid-4f71d797-0d51-35cb-86b0-e283afdf889a".

The administrative data is just a sketch; it will have to be worked out later what exactly to record here. In the following, administrative data will be left out.

A text-critical annotation targeting the base text looks like this:

<annotation type="element"

xml:id="uuid-79ac3c8c-6e4a-4be8-8f5b-92cbd1883fd7" status="string">


pa000001

129

10


This only establishes the link to the text range, telling where the text-critical annotation is: the actual annotations that report on variations target this annotation, using its xml:id. The is thus introduced in this way:

<annotation type="element"

xml:id="uuid-5989f048-8adc-48da-9854-f45f1ae25003" status="string">

<target type="element" layer="annotation">

    <annotation-layer>

        <id>uuid-79ac3c8c-6e4a-4be8-8f5b-92cbd1883fd7</id>

        <order>1</order>

    </annotation-layer>

</target>

<body>

    <lem xmlns="http://www.tei-c.org/ns/1.0">Enterprise</lem>

</body>
And likewise for any and , etc.

All text-critical annotations are either element-only or mixed-contents. The outer ones are element-only, that is, text range does not apply, but order is important, so the order is specified.

(more to come …)

Schema-derived information

Ideally speaking, it should be possible to derive information about which elements and attributes can be inserted at which point from a transform of a customised TEI schema, but a customised schema for the SARIT project does not exist yet, and the problems involved with making such a transform are considerable, especially seen in relation to the limited use of TEI tags in SARIT (probably as few as 10% of the options given in the official "minimal" TEI tag set are used.) A
#
[ANNOTATION:

BY 'Joern Turner'
ON '2013-07-30T19:11:16'
NOTE: 'fully agree with is said in this paragraph but what exactly is the interims solutions? How do we generate the lists of options (elements, attributes, cardinalities)?']
n interim solution appears better which informs the annotator about which elements can fit into which elements and which attributes are carried on which elements, and their cardinality, position, datatype and any value lists.
#
[ANNOTATION:

BY 'Jens Østergaard Petersen'
ON '2013-07-30T19:11:16'
NOTE: 'I have a preliminary mock-up, but I have to work it over (and study some XML Schema).']

Milestones

Discussion about issues related to standoff markup, writeup of Google Doc

2013-07-30

Wolfgang, Joern, Jens

< https://docs.google.com/a/existsolutions.com/document/d/1-YVYkQGQAWrPw5l0OGVaiz4Itx3sJ6iZyH9ltkCcb8E/edit?usp=sharing>

Proof-of-concept of script for converting TEI inline markup to base text, authoritative text and standoff annotations

2013-10-08

Jens

< https://github.com/jensopetersen/mopane/blob/master/scripts/inline2standoff.xq>

Discussion about issues related to standoff markup, revision of Google Doc

2013-10-08

Christian Wittern, Wolfgang, Jens

< https://docs.google.com/a/existsolutions.com/document/d/1-YVYkQGQAWrPw5l0OGVaiz4Itx3sJ6iZyH9ltkCcb8E/edit?usp=sharing>

Future:

Proof-of-concept of the use of web components for creating and editing standoff annotations

2013-11-01

Wolfgang

Time estimate: 4 days (full work days)

1.For the proof-of-concept, render base text and selected semantic annotations to HTML. Use web components technology to implement the HTML tags representing basic semantic annotations like persName or placeName. Clicking on a tag opens the corresponding, component-specific UI for modifications.
2.Allow users to add further semantic annotations to a span of text.
3.Implement server-side services to store and retrieve annotations.
Proof-of-concept of script for converting base text and standoff annotations to TEI document with inline markup

2013-11-01

Jens

Editor milestone 1

2013-12-31

Jens, Joern, Wolfgang

Time estimate: 8 days

1.Distinguish between text-critical and semantic annotation layer in user interface. Let user switch between the layers. Decide on general workflow model to be used.
2.Implement the most important annotation types as web components. Design general look and feel of components as well as basic user interaction.
3.Keep track of modified/added annotations and save them to db when user commits changes.
4.Test and improve rendering performance: annotated TEI to HTML.
Editor milestone 2

2014-02-01

Jens, Joern, Wolfgang

Time estimate: 10 days

1.Handle nested annotations in the user interface: if multiple annotations are defined on a given span of text, user needs to be able to select an annotation for editing.
2.Implement client-side validation: while there may be conflicts between the annotations on different layers, we may want to avoid certain combinations.
3.Add remaining annotation types as components.
4.Streamline the editing workflow, improve usability, test all editor components
Editor milestone 3

1.Multi user support: properly handle locking of documents
2.Versioning (optional): allow user to see history of edits and display older versions
3.Collaborative editing (optional): allow concurrent edits instead of placing an exclusive lock on a document while it is being edited by a user. Concurrent edits will be shown in real time.
Possible milestones

¢ÂÂ¢ÂÂauthentication of base text
¢ÂÂ¢ÂÂintegration of NLP tools

¢ÂÂ¢ÂÂuser generation of concordance
¢ÂÂ¢ÂÂblock-level critical apparatus

¢ÂÂ¢ÂÂvariant search capability
¢ÂÂ¢ÂÂmine Deutsches Textarchiv, TCP/ECCO, WordHoard, Perseus, (TLS?!?), TXM ¢ÂÂ¦ for features to implement
Repositories

Mopane

Concepts

Layers and Perspectives

A TEI text
#
[ANNOTATION:

BY 'Jens Østergaard Petersen'
ON '2013-08-07T17:42:18'
NOTE: 'Handling the variations on the normal text structure should present no problems, but we stick to the common model here.']
normally consists of a element and a element. The TEI header is not here assumed to be edited using the standoff editor; it can either be composed in an XML editor or (if it is sufficiently standardised) it can be composed using a separate forms-based approach.

The base text stored in the element is what the editing process begins with, the base for any subsequent annotations. Beginning with a good text is obviously to be preferred since this minimizes the need for text-altering edits and there the base text ideally consists of a carefully proofread transcription that renders the text stream of a specific exemplar of the
#
[ANNOTATION:

BY 'Jens Østergaard Petersen'
ON '2015-06-27T20:01:01'
NOTE: 'In the case of fragmentary texts, the base text may have to be pieced together from a number of manuscripts.']
work in question. The base text is marked up with
#
[ANNOTATION:

BY 'Jens Østergaard Petersen'
ON '2013-07-24T19:45:49'
NOTE: 'The use of block-level elements in the base text and the authoritative text is in part based on the practical concern that we prefer to calculate character offsets for shorter spans rather than long spans, and here the spans that paragraphs and suchlike are made up of are handy. It is surely possible to have pure text as base and construct both block-level and inline markup, but then the "scaffolding" of the text would have to be constructed on the fly, whereas if only inline markup is involved, only the "decorations" of the text have to be rendered on the fly. One might say that the block-level markup also reflects the (structural) understanding of the text and that this is based on an interpretation as well and therefore is semantic, but we have to divided rigidly between these two levels here.']
block-level markup
#
[ANNOTATION:

BY 'Jens Østergaard Petersen'
ON '2013-07-30T18:41:20'
NOTE: 'Actually, TEI markup divides into block-level, inline and block-level and inline, that is, some markup (e.g.

) may be used both at block-level and inline.']
#
[ANNOTATION:

BY 'Jens Østergaard Petersen'
ON '2015-06-27T20:19:10'
NOTE: 'Actually, this requirement is unnecessarily strong. Since the string value of the block-level element is used to reference the annotations, it is only necessary to rule out annotations that add to the string value ( etc.) or seeks to modify the string value ( etc.). Of course, keeping such markup in the base text goes against the idea of using standoff markup, but we might want to moderate this requirement and e.g. allow empty elements containing milestones, such a used for recording page breaks and linking facsimiles. Page and line breaks are important in the proofreading situation, but can of course be abstracted when proofreading is finished (as in JITM).']
, but containing no
#
[ANNOTATION:

BY 'Jens Østergaard Petersen'
ON '2013-10-22T15:29:17'
NOTE: 'Perhaps at a later date, we will also include block-level markup, but this has its own complications. If one marks up a string as e.g. a name, this has no influence on the presence or absence of any markup on adjacent strings. If one marks up a text, say, as a number of divisions, this markup has to be exhaustive, i.e. one either has to mark up nothing or mark up everything. Since we use a layered approach, it will be possible at a later date to insert the construction of the text with block-level elements.']
inline markup. The base text is required to be canonical XML in order to secure a standard physical representation. The base text is also required to be
#
[ANNOTATION:

BY 'Jens Østergaard Petersen'
ON '2015-06-27T20:21:46'
NOTE: 'Strangely, this is not a requiremenet of canonical XML. It does not matter which normalization form is chosen, but the form used should be recorded in the TEI header.']
Unicode-normalized. The (canonical, normalized) base text will be authenticated by hashes, using standoff markup, and in order to guarantee its stability.
#
[ANNOTATION:

BY 'Jens Østergaard Petersen'
ON '2015-06-27T20:31:33'
NOTE: 'How to deal with diplomatic markup is a problem to be solved. The ideal would be to have two base texts, one with basic structural TEI markup and one with diplomatic markup. The would make it unnecessary to mix up markup regarding the physical appearance of the document with its semantic structure. Since, however, the SARIT project (at present, at least), does not emphasise diplomatic transcription and since it only wants to use empty milestone elements, this appears to be unwarranted.']
The base text will not be modified in the annotation process, only referenced, and serves as the ultimate target for all annotations.

There are two kinds of annotation to be handled by the standoff editor: annotations that concern the constitution of the text itself (the graphemes that make up the text), and annotations that concern its interpretation and its physical manifestation in particular documents.

The first kind we call " text-critical annotation"; it is typified by the use of the and elements. Every change here implies a change in the graphemes to be represented in the different versions of the text that are simultaneously encoded in one TEI document. The second kind is all other kinds of markup; since they concern features of the text and a document containing the text, we call it " feature annotation".

Feature annotation can concern the physical makeup of the document digitised; this will be called " document annotation". Ideally speaking, such diplomatic markup should have its own layer or base text (as in e.g. the Faust Edition), but since such markup is not a major concern for the present project, markup of this kind, such as that noting the various breaks and font face changes in the text as rendered in a specific document (typified by and
#
[ANNOTATION:

BY 'Jens Østergaard Petersen'
ON '2014-01-14T00:57:45'
NOTE: 'There is a kind of markup which concerns the formatting of the graphemes, such as , which does not attempt any interpretation, but simply records the formatting of the graphs. Often, it is preliminary markup, preparatory for "proper" semantic markup, but ideally speaking it should be part of the document (or diplomatic) annotation, since it concerns the basic physical features of the text stream itself, even though it does not alter the text stream itself itself.']
), will be mixed up with the other feature markup.

The larger part of feature annotation will concern the interpretation of the text and will be termed " semantic annotation". It is typified by the use of the