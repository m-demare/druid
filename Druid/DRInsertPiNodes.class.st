Class {
	#name : 'DRInsertPiNodes',
	#superclass : 'DROptimisation',
	#instVars : [
		'instructionFactory'
	],
	#category : 'Druid-Optimizations',
	#package : 'Druid',
	#tag : 'Optimizations'
}

{ #category : 'instance creation' }
DRInsertPiNodes class >> with: aDRInstructionFactory [

	^ self new with: aDRInstructionFactory; yourself.
]

{ #category : 'accessing' }
DRInsertPiNodes >> applyTo: cfg [

	cfg blocks do: [ :b |
		b endInstruction isConditionalBranch ifTrue: [
			self insertPiNodesFor: b endInstruction.
		]
	]
]

{ #category : 'accessing' }
DRInsertPiNodes >> insertPiNode: aDRPiNode in: aDRBasicBlock [ 

	aDRPiNode result: instructionFactory allocateTemporaryRegister.
	aDRBasicBlock addInstructionFirst: aDRPiNode.
	

	aDRPiNode operand users
		select: [ :user | user ~= aDRPiNode ]
		thenDo: [ :user | (user basicBlock isDominatedBy: aDRBasicBlock)
									ifTrue: [user replaceDependency: aDRPiNode operand by: aDRPiNode result ] ]
]

{ #category : 'accessing' }
DRInsertPiNodes >> insertPiNodesFor: aDRBranchIfCondition [
	| piNodeBuilder |
	piNodeBuilder := DRPiNodeBuilder new.
	aDRBranchIfCondition condition
		acceptVisitor: piNodeBuilder
		withBranch: aDRBranchIfCondition.

	piNodeBuilder nodesForTrueBranch do: [ :pi | self insertPiNode: pi in: aDRBranchIfCondition trueBranch ].
	piNodeBuilder nodesForFalseBranch do: [ :pi | self insertPiNode: pi in: aDRBranchIfCondition falseBranch ].
	
]

{ #category : 'instance creation' }
DRInsertPiNodes >> with: aDRInstructionFactory [

	instructionFactory := aDRInstructionFactory.
]
