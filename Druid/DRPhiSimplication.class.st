Class {
	#name : 'DRPhiSimplication',
	#superclass : 'DROptimisation',
	#category : 'Druid-Optimizations',
	#package : 'Druid',
	#tag : 'Optimizations'
}

{ #category : 'operations' }
DRPhiSimplication >> applyTo: aDRControlFlowGraph [

	aDRControlFlowGraph phiFunctions do: [ :i |
		| operands operandsWithoutMyself |
		"If all operands are the same (excluding myself),
		I can be replaced by a copy instruction"
		operands := i operands asSet.
		operandsWithoutMyself := operands copyWithout: i.
		operandsWithoutMyself size = 1 ifTrue: [
			i replaceBy: (DRCopy operands: { operandsWithoutMyself anyOne } result: i result) ] ]
]

{ #category : 'testing' }
DRPhiSimplication >> canBeAppliedIn: aDRControlFlowGraph [

	^ aDRControlFlowGraph phiFunctions notEmpty
]
