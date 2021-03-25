Class {
	#name : #Expense,
	#superclass : #Object,
	#instVars : [
		'date',
		'tag',
		'cost'
	],
	#category : #ExpenseTracking
}

{ #category : #'instance creation' }
Expense class >> date: aDate cost: aMoney tag: aString [ 
	^ self new setDate: aDate tag: aString cost: aMoney
]

{ #category : #accessing }
Expense >> cost [
	^ cost
]

{ #category : #accessing }
Expense >> date [
	^ date
]

{ #category : #print }
Expense >> printOn: aStream [
	cost printOn: aStream.
	aStream nextPutAll: ' at '.
	date printOn: aStream.
	aStream nextPutAll: ' for '.
	tag printOn: aStream.
	
]

{ #category : #initalize }
Expense >> setDate: aDate tag: aString cost: aMoney [
	date := aDate.
	tag := aString.
	cost := aMoney.
	^ self
]

{ #category : #accessing }
Expense >> tag [
	^ tag
]
