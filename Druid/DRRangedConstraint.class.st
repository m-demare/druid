Class {
	#name : 'DRRangedConstraint',
	#superclass : 'DRSimpleConstraint',
	#category : 'Druid-IR-Paths',
	#package : 'Druid',
	#tag : 'IR-Paths'
}

{ #category : 'testing' }
DRRangedConstraint >> hasAllValuesWithMask: aMask [

	^ false "always?"
]

{ #category : 'testing' }
DRRangedConstraint >> hasAllValuesWithoutMask: aMask [

	^ false "always?"
]

{ #category : 'reversing' }
DRRangedConstraint >> reversed [
	
	self subclassResponsibility
]
