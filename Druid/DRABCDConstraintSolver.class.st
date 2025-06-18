Class {
	#name : 'DRABCDConstraintSolver',
	#superclass : 'DRConstraintSolver',
	#instVars : [
		'nodes',
		'edges',
		'cfg',
		'memo',
		'isCheckingUpperBounds',
		'reversibleEdges'
	],
	#category : 'Druid-IR-Paths',
	#package : 'Druid',
	#tag : 'IR-Paths'
}

{ #category : 'instance creation' }
DRABCDConstraintSolver class >> for: aDRControlFlowGraph [

	^ self new initializeFor: aDRControlFlowGraph
]

{ #category : 'building - graph' }
DRABCDConstraintSolver >> addEdgeFrom: src to: dst weight: w [

	^ edges add: { src. dst. w }
]

{ #category : 'building - graph' }
DRABCDConstraintSolver >> addEdgeFrom: src to: dst weight: w reversible: isReversible [

	| edge |
	edge := self addEdgeFrom: src to: dst weight: w.

	isReversible ifTrue: [ reversibleEdges add: edge ].
	
	^ edge
]

{ #category : 'building - graph' }
DRABCDConstraintSolver >> addEdgesBetweenConstants [

	((nodes select: #isNumberValue) asOrderedCollection sortedAs: #value)
		overlappingPairsDo: [ :c1 :c2 |
			self addEdgeFrom: c1 to: c2 weight: c2 value - c1 value ]
]

{ #category : 'building - graph' }
DRABCDConstraintSolver >> buildGraph [

	cfg instructions reject: #isMandatoryInstruction thenDo: [ :i |
		nodes add: i.
		self processValue: i ].

	self addEdgesBetweenConstants
]

{ #category : 'building - graph' }
DRABCDConstraintSolver >> graph [

	^ AIGraphWeightedFixtureStructure new
		nodes: nodes;
		edges: edges;
		yourself.
]

{ #category : 'initialization' }
DRABCDConstraintSolver >> initializeFor: aDRControlFlowGraph [

	cfg := aDRControlFlowGraph.

	nodes := Set new.
	edges := Set new.
	
	memo := Dictionary new.
	
	isCheckingUpperBounds := true.
	reversibleEdges := OrderedCollection new.
	
	self buildGraph.

]

{ #category : 'testing' }
DRABCDConstraintSolver >> isSatisfiable: aDRPiNode [
	"TODO - for unsupported constraints, return true
			- do we need different ABCD subclasses for upper/lower bounds checks?"

	| shortestPath minABCDDistanceToBeSatisfiable source dst |
	minABCDDistanceToBeSatisfiable := (aDRPiNode constraint
		                                  minABCDDistanceToBeSatisfiableIsUpperCheck: isCheckingUpperBounds)
		                                  ifNil: [ ^ true ].1halt.
	isCheckingUpperBounds
		ifTrue: [
			source := self piNodesOriginalVariable:
				          aDRPiNode constraint constantValue asDRValue.
			dst := aDRPiNode operand ]
		ifFalse: [
			source := self piNodesOriginalVariable: aDRPiNode operand.
			dst := aDRPiNode constraint constantValue asDRValue ].

	shortestPath := AIShortestPathWithMaxAndMinNodes new.
	shortestPath nodes: nodes.
	shortestPath
		edges: edges
		from: #first
		to: #second
		weight: #third.

	shortestPath
		start: source;
		isMaxNodePredicate: [ :n | n isPhiFunction ];
		memoDictionary: memo.
	shortestPath run.

	"Distance < 0 means the other side is a tautology => this side is unsatisfiable
	>= 0 means this side isn't tautology => this side is satisfiable"
	^ (shortestPath
		   distanceTo: dst
		   isLessThan: minABCDDistanceToBeSatisfiable) = -1
]

{ #category : 'building - graph' }
DRABCDConstraintSolver >> piNodesOriginalVariable: aDRValue [

	^ aDRValue simpleConstantFold asDRValue
]

{ #category : 'building - graph' }
DRABCDConstraintSolver >> processAdd: aDRValue [

	| ops |
	ops := aDRValue operands.
	ops first isNumberValue ifTrue: [ ops := ops reversed ].
	ops second isNumberValue ifFalse: [ ^ nil ].

	self
		addEdgeFrom: ops first
		to: aDRValue
		weight: ops second value
		reversible: true.
]

{ #category : 'building - graph' }
DRABCDConstraintSolver >> processCopy: aDRValue [
	"Remember a PiNode is a Copy too"

	aDRValue operands do: [ :op |
		nodes add: op.
		self
			addEdgeFrom: op
			to: aDRValue
			weight: 0
			reversible: aDRValue isPiNode not ].

	aDRValue isPiNode ifTrue: [ self processPiNode: aDRValue ]
]

{ #category : 'building - graph' }
DRABCDConstraintSolver >> processPiNode: aDRPiNode [

	| constraint distance |
	constraint := aDRPiNode constraint.
	nodes add: constraint constantValue asDRValue.

	distance := constraint distanceForBuildingABCDGraph.
	distance ifNil: [ ^nil ].

	edges add: {
			constraint constantValue asDRValue. "According to the paper, the edge source should be the pi-node associated to the constraint,
															but I don't think there's a difference here, and this is easier"
			aDRPiNode.
			distance }.

]

{ #category : 'building - graph' }
DRABCDConstraintSolver >> processSub: aDRValue [

	| ops |
	ops := aDRValue operands.
	ops second isNumberValue ifFalse: [ ^ nil ].

	self
		addEdgeFrom: ops first
		to: aDRValue
		weight: ops second value negated
		reversible: true
]

{ #category : 'building - graph' }
DRABCDConstraintSolver >> processValue: aDRValue [

	aDRValue isAdd ifTrue: [ ^ self processAdd: aDRValue ].

	aDRValue isSubtract ifTrue: [ ^ self processSub: aDRValue ].

	(aDRValue isCopy or: aDRValue isPhiFunction) ifTrue: [
		^ self processCopy: aDRValue ]
]

{ #category : 'building - graph' }
DRABCDConstraintSolver >> reverseEdgesForLowerBoundsCheck [

	isCheckingUpperBounds := isCheckingUpperBounds not.

	reversibleEdges do: [ :edge | edge swap: 1 with: 2 ].
	
	memo removeAll
]
