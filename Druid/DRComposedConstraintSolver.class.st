Class {
	#name : 'DRComposedConstraintSolver',
	#superclass : 'DRConstraintSolver',
	#instVars : [
		'solvers'
	],
	#category : 'Druid-IR-Paths',
	#package : 'Druid',
	#tag : 'IR-Paths'
}

{ #category : 'solving' }
DRComposedConstraintSolver >> isSatisfiable: aDRPiNode [ 
	^ solvers allSatisfy: [ :s | s isSatisfiable: aDRPiNode ]
]

{ #category : 'solving' }
DRComposedConstraintSolver >> solvers: aCollection [
	solvers := aCollection
]
