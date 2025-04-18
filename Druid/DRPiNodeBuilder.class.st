Class {
	#name : 'DRPiNodeBuilder',
	#superclass : 'Object',
	#instVars : [
		'trueNodes'
	],
	#category : 'Druid-Optimizations',
	#package : 'Druid',
	#tag : 'Optimizations'
}

{ #category : 'private - building' }
DRPiNodeBuilder >> createPiNode: aDRConditionalConstraintClass on: aValue withTheOtherOperand: otherOperands then: aBlock [ 
	
	otherOperands detect: [ :otherOp | otherOp ~= aValue ] ifFound: [ :otherOp |
		aBlock value: (DRPiNode
			constraint: (aDRConditionalConstraintClass withValue: otherOp result)
			on: aValue)
	]
]

{ #category : 'initialization' }
DRPiNodeBuilder >> initialize [ 
	
	trueNodes := OrderedCollection new.
]

{ #category : 'accesing' }
DRPiNodeBuilder >> nodesForFalseBranch [
	
	^ trueNodes collect: [ :pi | pi negated ]

]

{ #category : 'accesing' }
DRPiNodeBuilder >> nodesForTrueBranch [
	
	^ trueNodes
]

{ #category : 'visiting' }
DRPiNodeBuilder >> visitEqualsThan: aDREqualsThanComparison inBranch: aDRBranchIfCondition [ 
	
	aDRBranchIfCondition operands
		select: [ :operand | operand isInstruction or: operand isRegister ]
		thenDo: [ :operand |
			self createPiNode: DREqualsConstraint
			on: operand
			withTheOtherOperand: aDRBranchIfCondition operands
			then: [ :pi|
				trueNodes add: pi.
			].
		].
]
