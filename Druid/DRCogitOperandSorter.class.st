Class {
	#name : 'DRCogitOperandSorter',
	#superclass : 'Object',
	#category : 'Druid-Cogit',
	#package : 'Druid',
	#tag : 'Cogit'
}

{ #category : 'applying' }
DRCogitOperandSorter >> applyTo: aDRControlFlowGraph [

	aDRControlFlowGraph instructionsDo: [ :e |
		e isStaged ifFalse: [
			e acceptVisitor: self.
			"If after sorting the second operand is a constant float, we need to extract it in a copy."
			(e operands size > 1 and: [
				 e operand2 isConstant and: [ e operand2 type isFloatType ] ])
				ifTrue: [ self extractCopyFor: e operand2 fromInstruction: e ] ] ]
]

{ #category : 'visiting' }
DRCogitOperandSorter >> extractCopyFor: operand fromInstruction: anInstruction [

	| copy |
	copy := anInstruction instructionFactory copy: operand.
	anInstruction addBefore: copy.
	anInstruction replaceOperand: operand by: copy
]

{ #category : 'visiting' }
DRCogitOperandSorter >> extractFirstOperandInCopyIfNecessaryFrom: anInstruction [

	| copy |
	"If the first operand is a constant, extract it in a copy.
	This is useful for instructions that do nto accept constants as second operand."
	(anInstruction operand1 isInstruction and: [
		 anInstruction operand1 isStaged not ]) ifTrue: [ ^ self ].

	copy := anInstruction instructionFactory copy: anInstruction operand1.
	anInstruction addBefore: copy.
	anInstruction replaceOperand: anInstruction operand1 by: copy
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitAddition: aDRAdd [ 

	self visitCommutativeInstruction: aDRAdd
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitAnnnotateBytecode: aDRAnnotateBytecode [ 

	"Nothing"
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitBitAnd: aDRBitAnd [ 
	
	^ self visitCommutativeInstruction: aDRBitAnd
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitBitOr: aDRBitOr [ 
	
	^ self visitCommutativeInstruction: aDRBitOr
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitBitXor: aDRBitXor [ 
	
	^ self visitCommutativeInstruction: aDRBitXor
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitBranchIfCondition: aDRBranchIfCondition [

	"JIT expressions do not need extras copies"
	aDRBranchIfCondition isJITCompileTimeExpression ifTrue: [ ^ self ].

	"Mask test conditions accept constants in cogit"
	(aDRBranchIfCondition condition isTestMask or: [
		 aDRBranchIfCondition condition isNoTestMask ]) ifTrue: [ ^ self ].


	"Cogit only accept constants as first operands (second in DruidIR).
	Equals comparison being commutative, we can reverse the operands to avoid an extra copy"
	(aDRBranchIfCondition operand1 willBeConstant) ifTrue: [
		aDRBranchIfCondition reverse ].

	self extractFirstOperandInCopyIfNecessaryFrom: aDRBranchIfCondition
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitBytecodeJump: aDRBytecodeJump [ 
	
	"Nothing"
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitCall: aDRCall [
	"Nothing"

	
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitClosureActivation: aDRClosureActivation [
	"Nothing"

	
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitClosureCreation: aDRClosureCreation [ 
	
	"Nothing"
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitCogitSendMarshall: aDRCogitSendMarshall [ 

	"Nothing"
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitCommutativeInstruction: anInstruction [

	anInstruction operand1 willBeConstant ifTrue: [ 
		anInstruction reverseOperands ].
	self extractFirstOperandInCopyIfNecessaryFrom: anInstruction
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitContinueNextBytecode: aDRContinueNextBytecode [ 
	
	"Nothing"
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitCopy: aDRCopy [ 
	
	"There is no load of float constants in the Cogit IR.
	This means we need to transform the instruction to the following sequence
	
	Rd1 := 3.14.
	=>
	self MoveCq: (objectMemory rawFloatBitsOf: 3.14) R: R1.
	self MoveR: R1 Rd: Rd1.
	"
	
	| copyFloatBits convert |
	(aDRCopy type isFloatType and: [ aDRCopy operand1 isConstant ])
		ifFalse: [ ^ self ].
	
	copyFloatBits := aDRCopy instructionFactory copy: (DRInterpreterReference integerExpression: '(objectMemory rawFloatBitsOf: ', aDRCopy operand1 value asString, ')').
	convert := aDRCopy instructionFactory floatFromBits: copyFloatBits.
	aDRCopy addBefore: copyFloatBits.
	aDRCopy replaceBy: convert
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitDeoptimize: aDRDeoptimize [ 
	
	"Nothing"
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitDivision: aDRDivision [ 
	
	"Division only exist between two registers in cogit. Extract the second operand too"
	self extractFirstOperandInCopyIfNecessaryFrom: aDRDivision.
	aDRDivision reverseOperands.
	self extractFirstOperandInCopyIfNecessaryFrom: aDRDivision.
	aDRDivision reverseOperands.
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitFloatToIntConversion: aDRFloatToInt [ 
	
	"Int to float conversion is on registers only"
	self extractFirstOperandInCopyIfNecessaryFrom: aDRFloatToInt
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitFlushStack: aDRFlushStack [
	"Nothing"

	
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitGetConditionCode: aDRGetConditionCode [

	(aDRGetConditionCode condition isCommutative and: [ 
		 aDRGetConditionCode operand1 isInstruction ]) ifTrue: [ 
		aDRGetConditionCode reverseOperands ].
	self extractFirstOperandInCopyIfNecessaryFrom: aDRGetConditionCode
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitGetFloatBits: aDRGetFloatBits [ 

	"Get float bits are only from registers..."
	self extractFirstOperandInCopyIfNecessaryFrom: aDRGetFloatBits
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitGetFloatFromBits: aDRGetFloatFromBits [ 

	"Get float bits are only from registers..."
	self extractFirstOperandInCopyIfNecessaryFrom: aDRGetFloatFromBits
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitIntToFloatConversion: aDRIntToFloat [ 
	
	"Int to float conversion is on registers only"
	self extractFirstOperandInCopyIfNecessaryFrom: aDRIntToFloat
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitJITMessageSend: aDRMessageSend [ 

	"Nothing"
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitJump: aDRJump [ 
	
	"Nothing"
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitLeftRotate: aDRRotate [
	"Left rotation is not commutative!
	=> extract its first operand into a copy instruction"

	self extractFirstOperandInCopyIfNecessaryFrom: aDRRotate
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitLeftShift: aDRLeftShift [ 
	
	"Shift is not commutative!
	=> extract its first operand into a copy instruction"
	self extractFirstOperandInCopyIfNecessaryFrom: aDRLeftShift
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitLoad: aDRLoad [ 
	
	"Nothing"
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitLoadArgument: aDRLoadArgument [ 
	
	"Do nothing for load argument"
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitLoadFramePointer: aDRLoadFramePointer [ 
	
	"Nothing"
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitLoadReceiver: aDRLoadReceiver [ 
	
	"Nothing"
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitLoadStackPointer: aDRLoadStackPointer [ 
	
	"Nothing"
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitLoadStackValue: aDRLoadStackValue [ 
	
	"Nothing"
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitMessageSend: aDRMessageSend [
	"Nothing"

	
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitMod: aDRMod [ 
	
	"Mod and division are the same instruction in cogit"
	self visitDivision: aDRMod
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitMultiply: aDRMultiply [ 
	
	"Multiply only exist between two registers in cogit. Extract the second operand too"
	self extractFirstOperandInCopyIfNecessaryFrom: aDRMultiply.
	aDRMultiply reverseOperands.
	self extractFirstOperandInCopyIfNecessaryFrom: aDRMultiply.
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitNegate: aDRNegate [ 
	
	"Nothing"
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitNoop: aDRNoop [ 
	
	"Nothing"
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitPhiFunction: aDRPhiFunction [ 
	
	"Nothing"
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitPop: aDRPop [ 
	
	"Nothing"
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitPush: aDRPush [ 
	
	"Nothing"
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitReturn: aDRReturn [ 
	
	"Nothing"
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitSignedRightShift: aDRRightShift [ 
	
	"Shift is not commutative!
	=> extract its first operand into a copy instruction"
	self extractFirstOperandInCopyIfNecessaryFrom: aDRRightShift
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitStore: aDRStore [

	aDRStore isJITCompileTimeExpression ifTrue: [ ^ self ].
	
	"Stores at runtime are only from registers..."
	self extractFirstOperandInCopyIfNecessaryFrom: aDRStore
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitStoreTempVar: aDRStoreTemporaryVariable [ 
	
	"Nothing"
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitSubstract: aDRSubtract [ 
	
	"Subtraction is not commutative!
	=> extract its first operand into a copy instruction"
	
	self extractFirstOperandInCopyIfNecessaryFrom: aDRSubtract
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitTemporaryVariable: aDRLoadTemporaryVariable [ 

	"Nothing?"
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitUnsignedCoercion: aDRUnsignedCoercion [ 
	
	"Nothing"
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitUnsignedRightShift: aDRRightShift [ 
	
	"Shift is not commutative!
	=> extract its first operand into a copy instruction"
	self extractFirstOperandInCopyIfNecessaryFrom: aDRRightShift
]

{ #category : 'visiting' }
DRCogitOperandSorter >> visitUnspillStackSlot: aDRUnspillStackSlot [ 
	
	"Nothing"
]
