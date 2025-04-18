Class {
	#name : 'DRPiNode',
	#superclass : 'DRCopy',
	#instVars : [
		'constraint'
	],
	#category : 'Druid-IR',
	#package : 'Druid',
	#tag : 'IR'
}

{ #category : 'initialization' }
DRPiNode class >> constraint: aDRConditionalConstraint on: aDRValue [
	^ self new
		operands: (OrderedCollection with: aDRValue);
		constraint: aDRConditionalConstraint;
		yourself
]

{ #category : 'testing' }
DRPiNode >> constraint [
	
	^ constraint 
]

{ #category : 'testing' }
DRPiNode >> constraint: aDRConditionalConstraint [
	
	constraint := aDRConditionalConstraint 
]

{ #category : 'testing' }
DRPiNode >> isPiNode [

	^ true
]

{ #category : 'arithmetic' }
DRPiNode >> negated [
	^ self class
		constraint: constraint negated
		on: self operand.
]

{ #category : 'printing' }
DRPiNode >> prettyPrint [

	^ (self isStaged
		   ifTrue: [ '[STAGED]' ]
		   ifFalse: [ '' ]),
		(result ifNil: [ 'nil' ] ifNotNil: [ result prettyPrint ]), ' := <- Pi(',
		operands first result prettyPrint, ', ',
		constraint prettyPrint, ')'
		
]
