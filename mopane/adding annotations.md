Each editorial annotation entails an offset-difference for subsequent editorial annotations, that is, the number of characters that the annotation adds to or reduces the target-text length, a number that applies to the text after its own offset and range. The first editorial annotation below e.g. moves reduces the length of the target-text by 1 character in relation to the base text, whereas the second adds to it by 3 characters. If the second feature annotation was made before the second editorial annotation, but after the first editorial annotation, its offset would have to be adjusted when the second editorial annotation was made, in order for it to still apply to the characters "hi", that is, its offset would have to be augmented by 3. We can do this by adding another offset and calculating the total offset by adding them.

base-text
ab1cdefghij

	<editorial-annotation n="1">
		<target>
			<id/>
			<offset>2</offset>
			<range>3</range>
		</target>
		<body>
			<app>
				<lem>bc</lem>
				<rdg>b1c</rdg>
			</app>
		</body>
		<offset-difference>-1</offset-difference>
	</editorial-annotation>

target-text
abcdefghij

	<feature-annotation n="1">
		<target>
			<id/>
			<offset>2</offset>
			<range>2</range>
		</target>
		<body>
			<name/>
		</body>
	</feature-annotation>
	
	<feature-annotation n="2">
		<target>
			<id/>
			<offset>8</offset>
			<range>2</range>
		</target>
		<body>
			<name/>
		</body>
	</annotation>
	
	a<name>bc</name>defg<name>hi</name>j
	
	<editorial-annotation n="2">
		<target>
			<id/>
			<offset>5</offset>
			<range>2</range>
		</target>
		<body>
			<app>
				<lem>d123e</lem>
				<rdg>de</rdg>
			</app>
		</body>
		<offset-difference>3</offset-difference>
	</editorial-annotation>

target-text
abcd123efghij

If an editorial annotation is added to a base text and if the target-text has feature annotations, we have to find out which feature annotations are influenced, that is, which of them have to have their offset adjusted.

There are four situations: 1) a feature annotation lies before the offset that the new editorial annotation applies to, 2) a feature annotation lies after the offset plus range that the new editorial annotation applies to, 3) a feature annotation overlaps completely with the offset plus range that the new editorial annotation applies to, and 4) a feature annotation overlaps incompletely with the offset plus range that the new editorial annotation applies to, i.e. part of the text it applies to lies within and part of it without.

In case 1), nothing has to be done, since the new annotation applies to the left of it. 

In case 3) nothing has to be done as regards the feature annotation's offset (its body may have to be adjusted). The offset and range are the same. The base text e.g. reads "Bob" and an annotation changes this to "Tom" - here a <name> annotation may still be valid - but what if "Tom" is changed to "one"?

Case 4) would require human intervention. The base text plus existing editorial annotations reads "Timothy", and this is targeted by a feature annotation applying <name>, but the new editorial annotation changes this to "Tim". The range is different and/or the offset is different. A feature annotation has targeted

Human intervention will be required in the last two cases. A problem is that the feature annotation may belong to someone else: can one alter another's annotations?

Case 2) is the one addressed here, since this can be handled programmatically.

The question to be solved is therefore: which feature annotations lie after the the text range that the new editorial annotation applies to and how much do their offset have to be adjusted?

In order to solve this question, we need to know the difference in the length of the target text that is is the result of applying the new editorial annotation.

The following has to be done.

1) All existing editorial annotations in relation to the base text are assembled.
2) The existing editorial annotations are built up and applied to the base text. We assume that these annotations do not overlap with the new annotation, i.e. that one annotation's offset plus range does not target another annotation's offset.
3) The length of the resulting text is computed.
4) The existing editorial annotations plus the new editorial annotation are built up and applied to the base text. Probably at this stage the new editorial annotation will not need to be built up, i.e. it has not been split.
5) The length of the resulting text is computed.
6) The difference between 3) and 5) is computed. This is the number of characters that the offsets to the right of the new editorial annotation are to be adjusted with.
7) The length of text before the onset of the range resulting from the new editorial annotation is computed by 
	a) truncating the base text after the offset plus range of the new editorial annotation,
	b) applying the new editorial annotation plus all existing editorial annotations that have offsets lower than it to the (truncated) base text,
	c) computing the length of the target text and subtracting the range of the new editorial annotation.
8) Feature annotations with an offset larger than 7) have inserted the difference as offset.
8) Feature annotations that have an offset equal to 7) but a range smaller or larger than the range of the new editorial annotation are marked with a warning.
8) Feature annotations that have an offset that is larger than than 7) but smaller than 7) plus the range of the new editorial annotation are marked with a warning.

	<feature-annotation n="1">
		<target>
			<id/>
			<offset>8</offset>
			<offset>3</offset>
			<range>2</range>
		</target>
		<body>
			<name/>
		</body>
	</annotation>
	
	a<name>bc</name>d123efg<name>hi</name>j

In order to be able to reconstruct the sequence of annotations and handle them manually, each annotation needs to be timestamped and each additional offset has to note the ID of the editorial annotation that occasioned it. 