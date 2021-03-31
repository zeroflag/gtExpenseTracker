Class {
	#name : #Expense,
	#superclass : #Object,
	#instVars : [
		'date',
		'cost',
		'category'
	],
	#category : #ExpenseTracking
}

{ #category : #'instance creation' }
Expense class >> date: aDate cost: aMoney category: aString [ 
	^ self new setDate: aDate category: aString cost: aMoney
]

{ #category : #accessing }
Expense >> category [
	^ category
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
	category printOn: aStream.
	
]

{ #category : #initalize }
Expense >> setDate: aDate category: aString cost: aMoney [
	date := aDate.
	category := aString.
	cost := aMoney.
	^ self
]
