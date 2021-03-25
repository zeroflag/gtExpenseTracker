Class {
	#name : #ExpenseReport,
	#superclass : #Object,
	#instVars : [
		'header',
		'expenses'
	],
	#category : #ExpenseTracking
}

{ #category : #'instance creation' }
ExpenseReport class >> fromCsv: aString [ 
	| csv header lines expenses |
	csv := CSVParser parseFile: aString.
	header := csv lines second values allButFirst collect: [:each | each value withoutQuoting].
	lines := csv lines allButFirst: 4.
	expenses := OrderedCollection new.
	lines do: [:line |		  	
	  | date cell |
  	date := Date fromString: line values first value.
  	line values allButFirst doWithIndex: [:each :index |
  		cell := each value trim.
  		cell ifNotEmpty: [ 
  			expenses add: (Expense
				date: date
				cost: each value asNumber
				tag: (header at: index) value)
  		].
 	 ].  
	].
	^ self new setHeader: header expenses: expenses
]

{ #category : #converting }
ExpenseReport >> asTable [
	| table queue tagToColumn tags |
	tags := self tags.
	header := OrderedCollection with: '' withAll: tags.
	table := OrderedCollection with: header.
	tagToColumn := Dictionary newFromKeys: tags andValues: (1 to: tags size).
	
	queue := OrderedCollection withAll: expenses.
	self timeSpan every: 1 day do: [:datetime |
		| row date |
		date := datetime asDate.
		row := Array new: tags size.
		[queue notEmpty and: [queue first date = date]] whileTrue: 
		[ row 
				at: (tagToColumn at: queue first tag) 
				put: queue first cost.
			queue removeFirst. ].
		table add: (OrderedCollection with: date withAll: row).
	].
	^ table
]

{ #category : #accessing }
ExpenseReport >> expenses [
	^ expenses
]

{ #category : #filtering }
ExpenseReport >> filter: aBloc [	
	^ ExpenseReport new 			
		setHeader: header 
		expenses: (expenses select: aBloc)
]

{ #category : #grouping }
ExpenseReport >> groupByDate [
    ^ (expenses groupedBy: #date) values collect: [:each |
		ExpenseReport new 			
			setHeader: header 
			expenses: each ].
]

{ #category : #grouping }
ExpenseReport >> groupByTag [
    ^ (expenses groupedBy: #tag) values collect: [:each |
		ExpenseReport new 			
			setHeader: header 
			expenses: each ].
]

{ #category : #inspect }
ExpenseReport >> gtViewAddExpenseOn: aView [
	<gtView>
	| container tagDropDown |
	^ aView explicit 
		title: 'New expense';
		priority: 100;
		actionButtonIcon: BrGlamorousVectorIcons accept 
		tooltip: 'Save' 
		action: [ :aToggle :aTab | ];	
		stencil: [	
			| costInput button |
			
			costInput := BrEditor new
				hMatchParent;
				vFitContentLimited;
				look: BrGlamorousRegularEditorLook;
				text:'0'.
			costInput selecter all; select.
			
"			
			tagDropDown := BrButton new
				label: 'Category';
				look: BrGlamorousButtonWithLabelLook 
					+ (BrGlamorousWithDropdownLook 
							handle: [ 
							

							
							 ];
							content: [ header ]);
				yourself."
			

			button := BrButton new
				look: BrGlamorousButtonWithIconLook;
				icon: BrGlamorousVectorIcons accept;
				label: 'Save';
				disabled: costInput text isEmpty;
				action: [ ].
				
			BrVerticalPane new
				hExact: 400;
				vFitContentLimited;
				padding: (BlInsets all: 10);
				addChildren: { costInput  . button }
		].
]

{ #category : #inspect }
ExpenseReport >> gtViewBarChartOn: aView [
	<gtView>
	^ aView explicit
		title: 'Bar chart';
		stencil: [
		    | data reports |
		    reports := self groupByTag.
			data := GtPlotterDataGroup new values:reports.
			data := data labelled: [:each | each tags first, ' (', each sum asString, ')' ].
			data := data colored: [:each | Color random alpha: 0.5 ].
			GtPlotterHorizontalBarChart new
				 barLabelWidth: 250;
 				barWidthScale: (GtPlotterLinearScale new domainFrom: 0 to: (reports max: #sum));
 				barWidthData: #sum;	 				
 				amountOfTicks: 6;
 				with: data ]
]

{ #category : #inspect }
ExpenseReport >> gtViewListOn: aView [
	<gtView>
	^ aView columnedList
		title: 'List';
		priority: 5;
		items: [self expenses];
		column: 'Date' text: #date;
		column: 'Tag' text: #tag;
		column: 'Cost' text: #cost.
]

{ #category : #inspect }
ExpenseReport >> gtViewTableOn: aView [
	<gtView>
	^ aView table
		title: 'Table';
		items:  self asTable;
		forCollectionOfCollection
		
	
]

{ #category : #inspect }
ExpenseReport >> gtViewTreeOn: aView [
	<gtView>
	^ aView columnedTree
		title: 'Tree';
		items: [ self groupByTag ];
		column: 'Tag' item: [:each | 
			(each isKindOf: ExpenseReport)
				ifTrue: [each tags first]
				ifFalse: ['' asRopedText]];
		column: 'Date' item: [:each | 
			(each isKindOf: ExpenseReport)
				ifTrue: ['' asRopedText]
				ifFalse: [each date]];						
		column: 'Cost' item: [:each | 
			(each isKindOf: ExpenseReport)
				ifTrue: ['' asRopedText]
				ifFalse: [each cost]];			
		expandAll;
		children: [ :each |
			(each isKindOf: ExpenseReport)
				ifTrue: [each expenses]
				ifFalse: [#()] ].
				
]

{ #category : #filtering }
ExpenseReport >> month: aNumber [
	^ self year: (Date today year) month: aNumber
]

{ #category : #initalize }
ExpenseReport >> setHeader: aCollection1 expenses: aCollection2 [
    header := aCollection1.
	expenses := aCollection2.
]

{ #category : #accessing }
ExpenseReport >> sum [
	^ expenses sum: #cost
]

{ #category : #filtering }
ExpenseReport >> tag: aString [
	^ self filter: [:each | each tag = aString]
	
]

{ #category : #accessing }
ExpenseReport >> tags [
	| tags |
	tags := expenses collect: #tag.
	tags removeDuplicates.
	^ tags
	
]

{ #category : #accessing }
ExpenseReport >> timeSpan [
	^ expenses first date to: expenses last date
]

{ #category : #filtering }
ExpenseReport >> year: aNumber1 month: aNumber2 [
	^ self filter: [:each | each date year = aNumber1 and: [each date month index = aNumber2]]

]
