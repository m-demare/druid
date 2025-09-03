Class {
	#name : 'DRBenchmarksPiTest',
	#superclass : 'DRIRTest',
	#category : 'Druid-Tests-Optimizations',
	#package : 'Druid-Tests',
	#tag : 'Optimizations'
}

{ #category : 'accessing' }
DRBenchmarksPiTest class >> resources [

	^#()
]

{ #category : 'benchmarking' }
DRBenchmarksPiTest >> bench: opt withName: name on: allMethods repetitions: n [

	| total killedBranches killedBlocks opportunitiesFound |
	total := OrderedCollection new.
	name trace.
	':' traceCr.
	1 to: n do: [ :_ |
		| res |
		res := self benchRun: opt on: allMethods.
		total add: res first.
		killedBranches := res second.
		killedBlocks := res third.
		opportunitiesFound := res fourth ].

	('  total time ' , total sum asString , ', avg '
	 , total average asFloat asString , ' stdev ' , total stdev asString)
		traceCr.
	('Killed branches ' , killedBranches asString , ', killed blocks '
	 , killedBlocks asString) traceCr.
	opportunitiesFound traceCr
]

{ #category : 'benchmarking' }
DRBenchmarksPiTest >> benchRun: opt on: allMethods [

	| total failed failedOpt killedBlocks killedBranches opportunitiesFound splitBlocks |
	failed := 0.
	failedOpt := 0.
	total := 0.
	killedBlocks := 0.
	killedBranches := 0.
	splitBlocks := 0.
	opportunitiesFound := OrderedCollection new.

	allMethods do: [ :method |
		| start cfg |
				self setUp.
"		compilerCompiler := DRPrimitiveCompilerCompiler new."
		Smalltalk garbageCollect.
		[

		cfg := self generateDruidIRFor: method.
		cfg validate.
		cfg applyOptimisation: (DRCleanControlFlow then: DRBranchCollapse).

		[
		| blocks |
		blocks := cfg blocks size.
		start := Smalltalk highResClock.

		opt applyTo: cfg.

		total := Smalltalk highResClock - start + total.
		cfg applyOptimisation: (DRCopyPropagation
				 then: DRDeadCodeElimination
				 then: DRCleanControlFlow).
				
		"a := cfg blocks size.
		cfg applyOptimisation: DRDeadBranchElimination.
		a > cfg blocks size ifTrue: [ 1halt. ]."

		killedBranches := killedBranches + cfg killedBranches.
		splitBlocks := splitBlocks + cfg splitBlocks.
		killedBlocks := killedBlocks + (blocks - cfg blocks size).

		cfg killedBranches > 0 ifTrue: [ opportunitiesFound add: method ] ]
			onErrorDo: [ :e |
				failedOpt := failedOpt + 1.
				e debug.
				"1 halt" ] ] onErrorDo: [ failed := failed + 1 ] ].
	
	1 haltIf: failedOpt > 1.
	"1 haltIf: failed > 1."
		
	^ { total asFloat. killedBranches. killedBlocks. opportunitiesFound. splitBlocks }
]

{ #category : 'as yet unclassified' }
DRBenchmarksPiTest >> benchRun: opt on: allMethods bkp: asdf [
"DRProductionPrimitiveCompilationTest"
	| total failed failedOpt killedBlocks killedBranches opportunitiesFound interpreter environmentBuilder memory |
	failed := 0.
	failedOpt := 0.
	total := 0.
	killedBlocks := 0.
	killedBranches := 0.
	opportunitiesFound := OrderedCollection new.
	allMethods do: [ :method |
		| compiler start cfg |
		"		self setUp."
		Smalltalk garbageCollect.
		interpreter := environmentBuilder interpreter.
		memory := environmentBuilder objectMemory.
		[
		compiler := self
			            compileDruidPrimitiveGenerator: method
			            with: [ :_ | "" ].
		cfg := compiler irGenerator ir.
		cfg validate.
		cfg applyOptimisation: DRCleanControlFlow.
		[ |blocks|
		start := Smalltalk highResClock.
		blocks := cfg blocks size.
		opt applyTo: cfg.

		total := Smalltalk highResClock - start + total.
		cfg applyOptimisation: (DRCopyPropagation then: DRDeadCodeElimination then: DRCleanControlFlow).
		
		killedBranches := killedBranches + cfg killedBranches.
		killedBlocks := killedBlocks + (blocks - cfg blocks size).
		
		cfg killedBranches > 0 ifTrue: [ opportunitiesFound add: method ]
		
		] onErrorDo: [
			failedOpt := failedOpt + 1.
			1 halt ] ] onErrorDo: [ failed := failed + 1 ] ].
	1 haltIf: failedOpt > 1.
"	1 haltIf: failed > 1."
	^ {total asFloat. killedBranches. killedBlocks. opportunitiesFound }
]

{ #category : 'benchmarking' }
DRBenchmarksPiTest >> compare: opt1 with: opt2 on: allMethods [

	| failed failedOpt diff |
	failed := 0.
	failedOpt := 0.
	diff := OrderedCollection new.

	allMethods do: [ :method |
		| cfg |
		"		self setUp."
		compilerCompiler := DRPrimitiveCompilerCompiler new.
		Smalltalk garbageCollect.
		[
		cfg := self generateDruidIRFor: method.
		cfg validate.
		cfg applyOptimisation: (DRCleanControlFlow then: DRBranchCollapse).

		[
		| killedBranches |
		opt1 applyTo: cfg.

		cfg applyOptimisation: (DRCopyPropagation
				 then: DRDeadCodeElimination
				 then: DRCleanControlFlow).

		killedBranches := cfg killedBranches.

		cfg applyOptimisation: opt2.
		cfg killedBranches > killedBranches ifTrue: [ diff add: method. ] ] onErrorDo: [
			failedOpt := failedOpt + 1.
			1 halt ] ] onErrorDo: [ failed := failed + 1 ] ].

	1 haltIf: failedOpt > 1.
	"1 haltIf: failed > 1."

	^ diff
]

{ #category : 'benchmarking' }
DRBenchmarksPiTest >> interpreter [
	^ super interpreter
]

{ #category : 'benchmarking' }
DRBenchmarksPiTest >> setUp [

	super setUp.
	self timeLimit: 3 minute.
]

{ #category : 'benchmarking' }
DRBenchmarksPiTest >> test1 [

	| allMethods n optimisation |
	allMethods := DruidTestInterpreter methods
		              collect: #selector
		              thenSelect: [ :sel |
			              (sel prefixMatchesRegex: 'primitive') and:
				              ({ #primitiveConditionWithNoMaskInverted.
				               #primitiveConditionWithNoMask.
				               #primitiveConditionWithAnyMaskInverted.
				               #primitiveToDo. #primitiveLoopWithLoopInvariantInstructionInsideIf.
				               #primitivePiNodesBench } includes: sel) not ].
"			allMethods := allMethods first: 100."
"	n := 3."
	n:=1.

	'====================' traceCr.
	'Clocks compiling all TestInterp methods' traceCr.
	
	optimisation := DRInsertPiNodes
		                then: DRPiZ3DeadBranchElimination.
	self bench: optimisation withName: 'z3          ' on: allMethods repetitions: n.
	
	optimisation := DRDeadBranchElimination.
	self bench: optimisation withName: 'old constant' on: allMethods repetitions: n.

	optimisation := DRInsertPiNodes
		                then: DRPiConstantDeadBranchElimination.

	self bench: optimisation withName: 'new constant' on: allMethods repetitions: n.

	optimisation := DRInsertPiNodes
		                then: DRPiABCDDeadBranchElimination.
	self bench: optimisation withName: 'abcd        ' on: allMethods repetitions: n.
	
	optimisation := DRDeadBranchElimination then: DRInsertPiNodes
		             	then: DRPiABCDDeadBranchElimination
.
	self bench: optimisation withName: 'both        ' on: allMethods repetitions: n.

]

{ #category : 'benchmarking' }
DRBenchmarksPiTest >> test2 [

	| allMethods n optimisation selector |

	selector := #primitivePiNodesBench.
	allMethods := OrderedCollection new: 1 withAll: selector.

	n := 200.
	"n:=1."

	'====================' traceCr.
	'Clocks compiling hand-crafted method' traceCr.
	optimisation := DRDeadBranchElimination.
	self bench: optimisation withName: 'old constant' on: allMethods repetitions: n.

	optimisation := DRInsertPiNodes
		                then: DRPiConstantDeadBranchElimination.
	self bench: optimisation withName: 'new constant' on: allMethods repetitions: n.

	optimisation := DRInsertPiNodes
		                then: DRPiABCDDeadBranchElimination.
	self bench: optimisation withName: 'abcd        ' on: allMethods repetitions: n.
	
	optimisation := DRInsertPiNodes
		             	then: DRPiABCDDeadBranchElimination
							then: DRPiConstantDeadBranchElimination.
	self bench: optimisation withName: 'both        ' on: allMethods repetitions: n.
]

{ #category : 'benchmarking' }
DRBenchmarksPiTest >> testCompareOpportunitiesFound [

	| allMethods opt1 opt2 |
	allMethods := DruidTestInterpreter methods
		              collect: #selector
		              thenSelect: [ :sel |
			              (sel prefixMatchesRegex: 'primitive') and:
				              ({ #primitiveConditionWithNoMaskInverted.
				               #primitiveConditionWithNoMask.
				               #primitiveConditionWithAnyMaskInverted.
				               #primitiveToDo. #primitiveLoopWithLoopInvariantInstructionInsideIf.
				               #primitivePiNodesBench } includes: sel) not ].

	'====================' traceCr.
	opt1 := DRDeadBranchElimination.
	opt2 := DRInsertPiNodes then: DRPiConstantDeadBranchElimination.

	'--- 1 ---' traceCr.
	(self compare: opt1 with: opt2 on: allMethods) traceCr.

	'--- 2 ---' traceCr.
	(self compare: opt2 with: opt1 on: allMethods) traceCr.

	opt1 := DRDeadBranchElimination.
	opt2 := DRInsertPiNodes then: DRPiABCDDeadBranchElimination.
	
	'--- 3 ---' traceCr.
	(self compare: opt1 with: opt2 on: allMethods) traceCr.

	'--- 4 ---' traceCr.
	(self compare: opt2 with: opt1 on: allMethods) traceCr.

"Results:
--- 1 ---
an OrderedCollection()
--- 2 ---
an OrderedCollection()
--- 3 ---
an OrderedCollection(#primitiveWithOrBlock #primitiveOr)
--- 4 ---
an OrderedCollection(#primitiveAnd #primitiveFalseNot #primitiveAndIfTrue #primitiveFalseIfTrue)
"
]

{ #category : 'benchmarking' }
DRBenchmarksPiTest >> testToDebugWeirdMethod [

	| allMethods n optimisation selector |

	selector := #primitiveTrueNot.
	allMethods := OrderedCollection new: 1 withAll: selector.

	n := 1.

	'====================' traceCr.
	'Clocks compiling hand-crafted method' traceCr.
	optimisation := DRDeadBranchElimination.
	self bench: optimisation withName: 'old constant' on: allMethods repetitions: n.

	optimisation := DRInsertPiNodes
		                then: DRPiConstantDeadBranchElimination.

	self bench: optimisation withName: 'new constant' on: allMethods repetitions: n.

	optimisation := DRInsertPiNodes
		                then: DRPiABCDDeadBranchElimination.
	self bench: optimisation withName: 'abcd        ' on: allMethods repetitions: n.
]
