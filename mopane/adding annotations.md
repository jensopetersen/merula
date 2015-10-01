Each editorial annotation entails an offset-difference for subsequent editorial annotations, that is, the number of characters that the annotation adds to or reduces the target-text length, a number that applies to the text after its own offset and range. The first editorial annotation below e.g. moves reduces the length of the target-text by 1 character in relation to the base text, whereas the second adds to it by 3 characters. If the second feature annotation was made before the second editorial annotation, but after the first editorial annotation, its offset would have to be adjusted when the second editorial annotation was made, in order for it to still apply to the characters "hi", that is, its offset would have to be augmented by 3. We can do this by adding another offset and calculating the total offset by adding them.

With the base-text

	ab1cdefghij

and the following editorial annotaiton,

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

we get this target-text:

	abcdefghij

The following feature annotations relate to the target-text,

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

and result in the following markup:

	a<name>bc</name>defg<name>hi</name>j

If we add another editorial annotation,
	
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

the target-text becomes

	abcd123efghij

and the second feature annotation is out of sync.

If an editorial annotation is added to a base text and if the target-text has feature annotations, we have to find out which feature annotations are influenced, that is, which of them have to have their offset adjusted.

There are four situations: 

1. a feature annotation lies before the offset that the new editorial annotation applies to, 
2. a feature annotation lies after the offset plus range that the new editorial annotation applies to, 
3. a feature annotation overlaps completely with the offset plus range that the new editorial annotation applies to, and
4. a feature annotation overlaps incompletely with the offset plus range that the new editorial annotation applies to, i.e. part of the text it applies to lies within and part of it without.

In case 1., nothing has to be done, since the new annotation applies to the left of it. 

In case 3. nothing has to be done as regards the feature annotation's offset (its body may have to be adjusted). The offset and range are the same. The base text e.g. reads "Bob" and an annotation changes this to "Tom" - here a <name> annotation may still be valid - but what if "Tom" is changed to "one"?

Case 4. would require human intervention. The base text plus existing editorial annotations reads "Timothy", and this is targeted by a feature annotation applying <name>, but the new editorial annotation changes this to "Tim". The range is different and/or the offset is different. 

(Human intervention will be required in the last two cases. A problem is that the feature annotation may belong to someone else: can one alter another's annotations?)

Case 2. is the one addressed here, since this can be handled programmatically.

The question to be solved is therefore: which feature annotations lie after the the text range that the new editorial annotation applies to and how much do their offset have to be adjusted?

In order to solve this question, we need to know the difference in the length of the target text that is is the result of applying the new editorial annotation.

The following has to be done.

1. The base text is truncated to include the offset plus range of the the new editorial annotation.
2. All existing editorial annotations in relation to the truncated base text are assembled and built up.
3. The existing editorial annotations are applied to the truncated base text. 
4. The length of the resulting text is computed.
5. The existing editorial annotations plus the new editorial annotation are built up and applied to the truncated base text. (Probably at this stage the new editorial annotation will not need to be built up, i.e. it has not been peeled off.)
6. The length of the resulting text is computed.
7. The difference between the two text lengths is computed. This is the offset difference, the number of characters that the offsets to the right of the new editorial annotation are to be adjusted with.
8. The position in the target text affected by the new editorial annotation is the second text length. Feature annotations with an offset larger than this then have inserted the offset difference as offset.

This results in

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

which again gives the correct markup
		
	a<name>bc</name>d123efg<name>hi</name>j

In order to be able to reconstruct the sequence of annotations and handle them manually, each annotation needs to be timestamped and each additional offset has to note the ID of the editorial annotation that occasioned it. 