Class {
	#name : 'DRPiZ3DeadBranchElimination',
	#superclass : 'DRPiDeadBranchElimination',
	#instVars : [
		'withUB'
	],
	#category : 'Druid-Optimizations',
	#package : 'Druid',
	#tag : 'Optimizations'
}

{ #category : 'as yet unclassified' }
DRPiZ3DeadBranchElimination class >> withUndefinedBehaviour: ub [

	^ self new withUndefinedBehaviour: ub
]

{ #category : 'operations' }
DRPiZ3DeadBranchElimination >> applyTo: cfg [

	solver := DRZ3ConstraintSolver
		          for: cfg
		          withUB:
		          (withUB ifNil: [ false ]).
	super applyTo: cfg
]

{ #category : 'initialization' }
DRPiZ3DeadBranchElimination >> withUndefinedBehaviour: ub [

	withUB := ub
]
