Class {
	#name : 'DRMethodCompilerCompiler',
	#superclass : 'DRAbstractCompilerCompiler',
	#instVars : [
		'primitiveCompilerName'
	],
	#category : 'Druid-CompilerCompiler',
	#package : 'Druid',
	#tag : 'CompilerCompiler'
}

{ #category : 'compiling' }
DRMethodCompilerCompiler class >> compileMethod: aCompiledMethod [

	| compilerCompiler cfg method |
	compilerCompiler := self new.
	compilerCompiler interpreter: aCompiledMethod methodClass basicNew.
	compilerCompiler configureForCompilerClass: nil.

	cfg := compilerCompiler generateDruidIRFor: aCompiledMethod.
	compilerCompiler optimize: cfg.

	method := DRBytecodeGenerator
		          generateMethodFromCFG: cfg
		          withSelector: aCompiledMethod selector
		          numArgs: compilerCompiler irGenerator numberOfArguments.
	method methodClass: aCompiledMethod methodClass.

	^ method
]

{ #category : 'ir-generation' }
DRMethodCompilerCompiler >> argName: index forMethod: method [

	^ method argumentNames at: index
]

{ #category : 'accessing' }
DRMethodCompilerCompiler >> configureForCompilerClass: aCompilerClass [

	super configureForCompilerClass: aCompilerClass.
	self compilerClass: aCompilerClass.

	codeGenerator := DRCogitCodeGenerator new.
	registerAllocator := DRCogitLinearScanRegisterAllocator new.
	customisation := DRNonePrimitiveCustomisation new.
	irGenerator := self newIRGenerator.

	optimisations := OrderedCollection new.

	optimisations add: DRInline new.
	optimisations add: DRInline new.
	
	2 timesRepeat: [ 
		optimisations add: DRDeadBlockElimination new.
		optimisations add: DRSCCP new.
		optimisations add: DRCopyPropagation new.
		optimisations add: DRDeadCodeElimination new.
		optimisations add: DRCleanControlFlow new. ]
]

{ #category : 'accessing' }
DRMethodCompilerCompiler >> configureForCompilerClassWithoutInline: aCompilerClass [

	super configureForCompilerClass: aCompilerClass.
	self compilerClass: aCompilerClass.

	codeGenerator := DRCogitCodeGenerator new.
	registerAllocator := DRCogitLinearScanRegisterAllocator new.
	customisation := DRNonePrimitiveCustomisation new.
	irGenerator := self newIRGenerator.

	optimisations := OrderedCollection new.

	2 timesRepeat: [ 
		optimisations add: DRDeadBlockElimination new.
		optimisations add: DRSCCP new.
		optimisations add: DRCopyPropagation new.
		optimisations add: DRDeadCodeElimination new.
		optimisations add: DRCleanControlFlow new. ]
]

{ #category : 'generation-IR' }
DRMethodCompilerCompiler >> interpretMethods: compiledMethods receiver: aDRReceiver numArgs: numArgs [

	irGenerator receiver: aDRReceiver.
	irGenerator numberOfArguments: numArgs.
	
	compiledMethods do: [ :method |
		| aDRMethod |
		aDRMethod := DRMethod methodNode: method ast.
			
		irGenerator
			interpretCode: aDRMethod
			receiver: aDRReceiver ]
]

{ #category : 'instance creation' }
DRMethodCompilerCompiler >> newIRGenerator [

	^ DRMethodIRGenerator new compiler: self
]

{ #category : 'generation-IR' }
DRMethodCompilerCompiler >> numberOfArgumentsForMethod: aMethod [ 

	^ aMethod numArgs
]
