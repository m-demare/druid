Class {
	#name : 'DRMeasuredOptimization',
	#superclass : 'DROptimisation',
	#instVars : [
		'optimization'
	],
	#category : 'Druid-Optimizations',
	#package : 'Druid',
	#tag : 'Optimizations'
}

{ #category : 'accessing' }
DRMeasuredOptimization >> applyTo: cfg [

	| start blocks |
	
	1 haltIf: ShouldHalt ~= nil.
	cfg applyOptimisation: DRCleanControlFlow.

	blocks := cfg blocks size.
	
	start := Smalltalk highResClock.
		
	optimization applyTo: cfg.

	ElapsedTime := ElapsedTime + Smalltalk highResClock - start.

	cfg applyOptimisation: (DRCopyPropagation
			 then: DRDeadCodeElimination
			 then: DRCleanControlFlow).

	SplitBlocks := SplitBlocks + cfg splitBlocks.
	KilledBranches := KilledBranches + cfg killedBranches.
	KilledBlocks := KilledBlocks + blocks - cfg blocks size.

]

{ #category : 'accessing' }
DRMeasuredOptimization >> initialize [

	ElapsedTime := 0.
	KilledBranches := 0.
	KilledBlocks := 0.
	SplitBlocks := 0.
]

{ #category : 'accessing' }
DRMeasuredOptimization >> optimization: anOpt [
	optimization := anOpt.
]
