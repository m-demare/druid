Class {
	#name : 'DRMod',
	#superclass : 'DRArithmeticInstruction',
	#category : 'Druid-IR',
	#package : 'Druid',
	#tag : 'IR'
}

{ #category : 'printing' }
DRMod >> acceptVisitor: aVisitor [

	^ aVisitor visitMod: self
]

{ #category : 'printing' }
DRMod >> isModulo [
	
	^ true
]

{ #category : 'printing' }
DRMod >> opcode [
	
	^ 'MOD'
]
