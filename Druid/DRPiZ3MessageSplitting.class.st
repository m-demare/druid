Class {
	#name : 'DRPiZ3MessageSplitting',
	#superclass : 'DRPiMessageSplitting',
	#instVars : [
		'withUB'
	],
	#category : 'Druid-Optimizations',
	#package : 'Druid',
	#tag : 'Optimizations'
}

{ #category : 'initialization' }
DRPiZ3MessageSplitting class >> withUndefinedBehaviour: ub [

	^ self new withUndefinedBehaviour: ub
]

{ #category : 'accessing' }
DRPiZ3MessageSplitting >> solverFor: cfg [

	^ DRZ3ConstraintSolver for: cfg withUB: (withUB ifNil: false)
]

{ #category : 'accessing' }
DRPiZ3MessageSplitting >> withUndefinedBehaviour: ub [

	withUB := ub
]
