Class {
	#name : 'DRPiABCDDeadBranchEliminationTest',
	#superclass : 'DRPiNodesTest',
	#category : 'Druid-Tests-Optimizations',
	#package : 'Druid-Tests',
	#tag : 'Optimizations'
}

{ #category : 'tests' }
DRPiABCDDeadBranchEliminationTest >> testABCDGraph [
	| cfg b_if2 b_if2_after_check1 b_check_failed blocks |
	
	"This is the running example in the ABCD paper, reproduced it just to have something to validate our results agains"
	
	"             /->------------------------------------------------------------------------------------->-\
	             / V--<-------------------<-\                                   /->----------------------->--\
	 |b_i| -> |b_while| -> |b_if1| -> |b_for| -> |b_if2| -> |b_if2_after_check1| -> |b_if2_after_check2| -> |b_end|
                                           \-<------------------------------------------------------<-/
	"
	
	"Check Figure 3 in ABCD: Eliminating Array Bounds Checks on Demand for it to make *a bit* more sense"

	cfg := (DRIRParser for: '[[b0]]
b0:
	_ := Jump(b_i)
b_i:
	limit0 := LoadFramePointer()
	st0 := Copy(-1)
	_ := Jump(b_while)

b_while:
	limit1 := Ø(limit0, limit3)
	st1 := Ø(st0, st3)
	_ := If(LessThan, st1, limit1; b_if1, b_end)
b_if1:
	st3 := Add(st1, 1)
	limit3 := Sub(limit1, 1)
	j0 := Copy(st3)
	_ := Jump(b_for)
	
b_for:[b_if1, b_if2_after_check2]
	j1 := Ø(j0, j4)
	_ := If(LessThan, j1, limit3; b_if2, b_while)

b_if2:
	_ := If(LessThan, j1, limit0; b_if2_after_check1, b_check_failed)

b_if2_after_check1:
	t0 := Add(j1, 1)
	_ := If(LessThan, t0, limit0; b_if2_after_check2, b_check_failed)
b_if2_after_check2:
	j4 := Add(j1, 1)
	_ := Jump(b_for)

b_end:
	_ := Store(8, 2, 888)
b_check_failed:
	_ := Store(8, 2, 777)
	') parse.

	blocks := cfg blocks.
	b_if2 := blocks at: 5.
	b_if2_after_check1 := blocks at: 6.
	b_check_failed := blocks at: blocks size - 1.
	
	self optimize: cfg with: { DRPiABCDDeadBranchElimination }.


	self assert: b_if2 successors size equals: 1.
	self assert: b_if2 successors unique ~= b_check_failed.
	
	self assert: b_if2_after_check1 successors size equals: 1.
	self assert: b_if2 successors unique ~= b_check_failed.
	
	self assert: (cfg blocks includes: b_check_failed) not.

]

{ #category : 'tests' }
DRPiABCDDeadBranchEliminationTest >> testABCDLowerBoundCheck [
	"
	                 /->-|b_end0|
	 |b_i| -> |b_if1| -> |b_if2| -> |b_end1|
										\->-|b_check_failed|(unreachable)
	"

	| cfg b_check_failed b_end1 b_if2 blocks |
	cfg := DRControlFlowGraph new.
	cfg := (DRIRParser for: '[[b0]]
b0:
	_ := Jump(b_if1)
b_if1:
	x := LoadFramePointer()
	_ := If(GreaterOrEquals, x, 0; b_if2, b_end0)
b_if2:
	y := Add(x, 1)
	_ := If(GreaterOrEquals, y, 0; b_end1, b_check_failed)
b_end0:
	_ := Store(8, 2, 888)
b_end1:
	_ := Store(8, y, 777)
b_check_failed:
	_ := Store(8, 2, 666)
	') parse.

	blocks := cfg blocks.
	b_if2 := blocks at: 2.
	b_end1 := blocks at: blocks size - 2.
	b_check_failed := blocks at: blocks size - 1.

	self optimize: cfg with: { DRPiABCDDeadBranchElimination }.

	self deny: (cfg blocks includes: b_check_failed).
	self assert: (cfg blocks includes: b_end1).

	self assert: b_if2 endInstruction isJump.
	self assert: b_if2 endInstruction isConditionalBranch not.
	self assert: b_if2 endInstruction target equals: b_end1
]

{ #category : 'tests' }
DRPiABCDDeadBranchEliminationTest >> testABCDWithAdditionOverSameVariable [
	"
	                 /->-|b_end0| (unreachable)
	 |b_i| -> |b_if1| -> |b_end1|
	"

	| cfg b_end0 b_end1 b_if1 blocks |
	cfg := DRControlFlowGraph new.
	cfg := (DRIRParser for: '[[b0]]
b0:
	_ := Jump(b_if1)
b_if1:
	x := LoadFramePointer()
	y := Add(x, 1)
	_ := If(LessThan, y, x; b_end0, b_end1)
b_end0:
	_ := Store(8, 2, 888)
b_end1:
	_ := Store(8, y, 777)
	') parse.

	blocks := cfg blocks.
	b_if1 := blocks at: 1.
	b_end0 := blocks at: blocks size - 2.
	b_end1 := blocks at: blocks size - 1.

	self optimize: cfg with: { DRPiABCDDeadBranchElimination }.

	self deny: (cfg blocks includes: b_end0).
	self assert: (cfg blocks includes: b_end1).

	self assert: b_if1 endInstruction isJump.
	self assert: b_if1 endInstruction isConditionalBranch not.
	self assert: b_if1 endInstruction target equals: b_end1
]

{ #category : 'tests' }
DRPiABCDDeadBranchEliminationTest >> testABCDWithSubstractionOverSameVariable [

	"
	                 /->-|b_end0|
	 |b_i| -> |b_if1| -> |b_end1| (unreachable)
	"

	| cfg b_end0 b_end1 b_i x y b_if1 |
	cfg := DRControlFlowGraph new.
	
	b_end0 := cfg newBasicBlockWith: [ :block | block storeSInt64: 2 at: 777 ].
	b_end1 := cfg newBasicBlockWith: [ :block | block storeSInt64: 2 at: 888 ].
	
	b_i := cfg newBasicBlockWith: [ :block |
		x := block loadSInt64: 111.
		y := block subtract: 1 from: x.
	].

	b_if1 := cfg newBasicBlockWith: [ :block | |cmp|
		cmp := block less: y than: x.
		block jumpIf: cmp to: b_end0 ifFalseTo: b_end1
	].

	cfg initialBasicBlock jumpTo: b_i.
	b_i jumpTo: b_if1.


	self optimize: cfg with: { DRPiABCDDeadBranchElimination }.

	
	self assert: (cfg blocks includes: b_end0).
	self deny: (cfg blocks includes: b_end1).

	self assert: b_if1 endInstruction isJump.
	self assert: b_if1 endInstruction isConditionalBranch not.
	self assert: b_if1 endInstruction target equals: b_end0.

]
