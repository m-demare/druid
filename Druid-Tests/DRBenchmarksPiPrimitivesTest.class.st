Class {
	#name : 'DRBenchmarksPiPrimitivesTest',
	#superclass : 'DRProductionPrimitiveCompilationTest',
	#category : 'Druid-Tests-Optimizations',
	#package : 'Druid-Tests',
	#tag : 'Optimizations'
}

{ #category : 'accessing' }
DRBenchmarksPiPrimitivesTest class >> resources [

	^#()
]

{ #category : 'benchmarking' }
DRBenchmarksPiPrimitivesTest >> bench: opt withName: name on: allMethods repetitions: n [

	| total killedBranches killedBlocks opportunitiesFound lastRes splitBlocks |
	total := OrderedCollection new.
	'' traceCr.
	name trace.
	':' traceCr.
	1 to: n do: [ :_ |
		| res |
		res := self benchRun: opt on: allMethods.
		total add: res first.
		killedBranches := (res second collect: [ :pair | pair first ]) sum.
		killedBlocks := (res second collect: [ :pair | pair second ]) sum.
		splitBlocks := (res second collect: [ :pair | pair third ]) sum.
		opportunitiesFound := res third.
		lastRes := res ].
	('  total time ' , total sum asString , ', avg '
	 , total average asFloat asString , ' stdev ' , total stdev asString)
		traceCr.
	('Killed branches ' , killedBranches asString , ', killed blocks '
	 , killedBlocks asString, ', split blocks ' , splitBlocks asString) traceCr.
	opportunitiesFound traceCr.

	^ lastRes
]

{ #category : 'benchmarking' }
DRBenchmarksPiPrimitivesTest >> benchRun: opt on: allMethods [

	| total failed opportunitiesFound killsPerMethod |
	failed := 0.
	total := 0.
	opportunitiesFound := OrderedCollection new.
	Optimization := opt.
	killsPerMethod := Dictionary new.

	allMethods do: [ :method |
		| compiler |
		"		self setUp."
		Smalltalk garbageCollect.
		interpreter := environmentBuilder interpreter.
		memory := environmentBuilder objectMemory.
		[
		DidTimeOut := false.
		compiler := self
			            compileDruidPrimitiveGenerator: method
			            with: [ :_ | "" ].

		self checkIfTimedOut: method.

		total := total + ElapsedTime.

		killsPerMethod at: method put: {
				KilledBranches.
				KilledBlocks.
				SplitBlocks }.

		0 < KilledBranches ifTrue: [ opportunitiesFound add: method ] ]
			onErrorDo: [ :ex |
				"1 halt."
				ex debug.
				failed := failed + 1 ] ].

	"	1 haltIf: failed > 1."

	Optimization := nil.
	ElapsedTime := nil.
	KilledBlocks := nil.
	KilledBranches := nil.
	SplitBlocks := nil.
	^ {
		  total asFloat.
		  killsPerMethod.
		  opportunitiesFound }
]

{ #category : 'benchmarking' }
DRBenchmarksPiPrimitivesTest >> checkIfTimedOut: method [

	DidTimeOut ifTrue: [
		('timed out optimizing ' , method asString) traceCr ]
]

{ #category : 'benchmarking' }
DRBenchmarksPiPrimitivesTest >> compare: opt1 with: opt2 on: allMethods [

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
DRBenchmarksPiPrimitivesTest >> interpreter [

	^ super interpreter
]

{ #category : 'benchmarking' }
DRBenchmarksPiPrimitivesTest >> methodList [

"	^ #(primitiveAdd)."
"	^ #(primitiveAt)."
"	^ #(primitiveAtPut)."
"	^ #(primitiveNewWithArg)"

		^ #( #primitiveAdd #primitiveSubtract #primitiveMultiply
	     #primitiveDivide #primitiveMod #primitiveLessThan
	     #primitiveLessOrEqual #primitiveGreaterThan
	     #primitiveGreaterOrEqual #primitiveEqual #primitiveNotEqual
	     #primitiveIdentical #primitiveNotIdentical
	     #primitiveDiv #primitiveQuo primitiveBitShift primitiveBitAnd
	     primitiveBitXor primitiveBitOr primitiveSmallFloatAdd
	     primitiveSmallFloatSubtract #primitiveSmallFloatMultiply
	     primitiveSmallFloatDivide primitiveSmallFloatEqual
	     primitiveSmallFloatNotEqual primitiveSmallFloatGreaterOrEqual
	     primitiveSmallFloatGreaterThan primitiveSmallFloatLessThan
	     primitiveSmallFloatLessOrEqual primitiveFloatAdd
	     primitiveFloatSubtract #primitiveFloatMultiply
	     primitiveFloatEqual primitiveFloatNotEqual
	     primitiveFloatGreaterThan primitiveFloatGreaterOrEqual
	     primitiveFloatLessThan primitiveFloatLessOrEqual
	     primitiveAsFloat primitiveAsCharacter #primitiveImmediateAsInteger
	     primitiveClass #primitiveSize #primitiveAt #primitiveStringAt
	     #primitiveAtPut #primitiveIdentityHash primitiveNew #primitiveNewWithArg
	     primitiveFullClosureValue primitiveFullClosureValueNoContextSwitch )
]

{ #category : 'benchmarking' }
DRBenchmarksPiPrimitivesTest >> setUp [

	super setUp.
	self timeLimit: 55 minute.
	interpreter := InterpreterPrimitives.
]

{ #category : 'benchmarking' }
DRBenchmarksPiPrimitivesTest >> testA [

	| allMethods n optimisation old new abcd z3 newabcd newz3 z3_no_ub |
	allMethods := self methodList.

	"n := 3."
	n := 1.

	'====================' traceCr.
	'Clocks compiling all InterpreterPrimitives methods' traceCr.
	optimisation := DRInsertPiNodes then: DRPiZ3DeadBranchElimination.
	z3 :=self bench: optimisation withName: 'z3          ' on: allMethods repetitions: n.

	optimisation := DRDeadBranchElimination.
	old := self bench: optimisation withName: 'old constant' on: allMethods repetitions: n.

	optimisation := DRInsertPiNodes then: DRPiConstantDeadBranchElimination.
	new := self bench: optimisation withName: 'new constant' on: allMethods repetitions: n.

	optimisation := DRInsertPiNodes then: DRPiABCDDeadBranchElimination.
	abcd :=self bench: optimisation withName: 'abcd        ' on: allMethods repetitions: n.

	optimisation := DRInsertPiNodes
		                then: DRPiABCDDeadBranchElimination
		                then: DRPiConstantDeadBranchElimination.
	newabcd := self bench: optimisation withName: 'new+abcd    ' on: allMethods repetitions: n.
	
	optimisation := DRInsertPiNodes
		                then: DRPiConstantDeadBranchElimination
		                then: DRPiZ3DeadBranchElimination.
	newz3 := self bench: optimisation withName: 'new+z3      ' on: allMethods repetitions: n.
	
	optimisation := DRInsertPiNodes new then: (DRPiZ3DeadBranchElimination withUndefinedBehaviour: false).
	z3_no_ub :=self bench: optimisation withName: 'z3 no ub    ' on: allMethods repetitions: n.
	
	'' traceCr.
	'new < old:' traceCr.
	new second keysAndValuesDo: [ :method :killed |
		(killed first < (old second at: method) first) ifTrue:
		[method traceCr]].
	'' traceCr.
	'old < new:' traceCr.
	old second keysAndValuesDo: [ :method :killed |
		(killed first < (new second at: method) first) ifTrue:
		[method traceCr]].

	'' traceCr.
	'z3 < old:' traceCr.
	z3 second keysAndValuesDo: [ :method :killed |
		(killed first < (old second at: method) first) ifTrue:
		[method traceCr]].
	'' traceCr.
	'old < z3:' traceCr.
	old second keysAndValuesDo: [ :method :killed |
		(killed first < (z3 second at: method) first) ifTrue:
		[method traceCr]].
	
	Smalltalk garbageCollect.
	1halt.
]

{ #category : 'benchmarking' }
DRBenchmarksPiPrimitivesTest >> testAWithSplitting [

	| allMethods n optimisation old new z3 newz3 |
	allMethods := self methodList.

	"n := 3."
	n := 1.

	'====================' traceCr.
	'Clocks compiling all InterpreterPrimitives methods' traceCr.
	optimisation := DRInsertPiNodes then: DRPiZ3MessageSplitting then: DRPiZ3DeadBranchElimination.
	z3 :=self bench: optimisation withName: 'z3 split, z3 dbe         ' on: allMethods repetitions: n.

	optimisation := DRDeadEdgeSplitting then: DRDeadBranchElimination.
	old := self bench: optimisation withName: 'old split, old dbe       ' on: allMethods repetitions: n.

	optimisation := DRInsertPiNodes then: DRPiConstantMessageSplitting then: DRPiConstantDeadBranchElimination.
	new := self bench: optimisation withName: 'new split, new dbe       ' on: allMethods repetitions: n.
	
	optimisation := DRInsertPiNodes then: DRPiConstantMessageSplitting then: DRPiZ3DeadBranchElimination.
	newz3 := self bench: optimisation withName: 'new split, z3 dbe        ' on: allMethods repetitions: n.
	
	'' traceCr.
	'new < old:' traceCr.
	new second keysAndValuesDo: [ :method :killed |
		(killed first < (old second at: method) first) ifTrue:
		[method traceCr]].
	'' traceCr.
	'old < new:' traceCr.
	old second keysAndValuesDo: [ :method :killed |
		(killed first < (new second at: method) first) ifTrue:
		[method traceCr]].

	'' traceCr.
	'z3 < old:' traceCr.
	z3 second keysAndValuesDo: [ :method :killed |
		(killed first < (old second at: method) first) ifTrue:
		[method traceCr]].
	'' traceCr.
	'old < z3:' traceCr.
	old second keysAndValuesDo: [ :method :killed |
		(killed first < (z3 second at: method) first) ifTrue:
		[method traceCr]].
	
	Smalltalk garbageCollect.
	1halt.
]

{ #category : 'benchmarking' }
DRBenchmarksPiPrimitivesTest >> testCompareOpportunitiesFound [

	| allMethods opt1 opt2 |
	allMethods := self interpreter methods
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
DRBenchmarksPiPrimitivesTest >> testToDebugWeirdMethod [

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
