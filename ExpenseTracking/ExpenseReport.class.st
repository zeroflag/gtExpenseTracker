Class {
	#name : #ExpenseReport,
	#superclass : #Object,
	#instVars : [
		'header',
		'expenses',
		'budget'
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
				category: (header at: index) value)
  		].
 	 ].  
	].
	^ self new setHeader: header expenses: expenses
]

{ #category : #converting }
ExpenseReport >> asTable [
	| table queue tagToColumn tags |
	tags := self categories.
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
				at: (tagToColumn at: queue first category) 
				put: queue first cost.
			queue removeFirst. ].
		table add: (OrderedCollection with: date withAll: row).
	].
	^ table
]

{ #category : #accessing }
ExpenseReport >> budget: aNumber [
	budget := aNumber
]

{ #category : #accessing }
ExpenseReport >> categories [
	| tags |
	tags := expenses collect: #category.
	tags removeDuplicates.
	^ tags
	
]

{ #category : #filtering }
ExpenseReport >> category: aString [
	^ self filter: [:each | each category = aString]
	
]

{ #category : #accessing }
ExpenseReport >> expenses [
	^ expenses
]

{ #category : #filtering }
ExpenseReport >> filter: aBloc [	
	^ self class new 			
		setHeader: header 
		expenses: (expenses select: aBloc)
]

{ #category : #accessing }
ExpenseReport >> firstMonth [
	^ expenses first date monthIndex	
]

{ #category : #grouping }
ExpenseReport >> groupByCategory [
    ^ (expenses groupedBy: #category) values collect: [:each |
		self class new setHeader: header expenses: each ].
]

{ #category : #grouping }
ExpenseReport >> groupByDate [
    ^ (expenses groupedBy: #date) values collect: [:each |
		self class new	setHeader: header expenses: each ].
]

{ #category : #inspect }
ExpenseReport >> gtViewAddExpenseOn: aView [
	<gtView>
	| tagDropDown costInput yearInput monthInput dayInput button tagList dropdownLook |
	^ aView explicit 
		title: '+';
		priority: 7;
		stencil: [	
			costInput := BrEditor new
				hExact: 60;
				look: BrGlamorousRegularEditorLook;
				text:'0'.
			costInput selecter all; select.
			
			yearInput := BrEditor new
				hExact: 60;
				look: BrGlamorousRegularEditorLook;
				text: Date today year asString.
			
			monthInput := BrEditor new
				hExact: 60;
				look: BrGlamorousRegularEditorLook;
				text: Date today month monthIndex asString.
				
			dayInput := BrEditor new
				hExact: 60;
				look: BrGlamorousRegularEditorLook;
				text: Date today dayOfMonth asString.
		
			tagList := BrSimpleList new itemStencil: [
        		BrLabel new
            		hMatchParent;
            		look: BrGlamorousLabelLook new;
            		padding: (BlInsets all: 5) ];
    				itemDataBinder: [ :eachElement :eachItem :eachIndex | eachElement text: eachItem ];
    				items: header;
    				addEventHandler: (GtPhlowListToSelectHandler new);
    				lookDo: [ :aLook | 
    					aLook listElement constraintsDo: [ :c | c maxHeight: 500 ] ];
    				layout: BlLinearLayout vertical;
    				padding: (BlInsets all: 5);
    				vFitContent;
    				hFitContent;
    			yourself.
	
			dropdownLook := BrGlamorousWithDropdownLook handle: [ 
						BrButton new look:  BrGlamorousButtonWithLabelAndIconLook - BrGlamorousButtonExteriorLook;
							label: 'Category'; yourself.
						] content: tagList.
	
			tagDropDown := BrButton new
				hExact: 250;
				label: 'Category';
				look: BrGlamorousButtonWithLabelLook + dropdownLook.

			button := BrButton new
				look: BrGlamorousButtonWithIconLook;
				icon: BrGlamorousVectorIcons accept;
				label: 'Save';
				disabled: costInput text isEmpty;
				action: [ ].
				
			BrHorizontalPane new
				vFitContentLimited;
				padding: (BlInsets all: 5);
				addChildren: {  
					yearInput. 
					monthInput. 
					dayInput. 
					costInput.
					tagDropDown.
					button.
				}.
		].
]

{ #category : #inspect }
ExpenseReport >> gtViewBarChartOn: aView [
	<gtView>
	^ aView explicit
		title: 'BarChart';
		priority: 4;
		stencil: [
		    | data reports |
		    reports := self groupByCategory.
			data := GtPlotterDataGroup new values:reports.
			data := data labelled: [:each | each categories first, ' (', each sum asString, ')' ].
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
		priority: 1;
		items: [self expenses];
		column: 'Date' text: #date;
		column: 'Category' text: #category;
		column: 'Cost' text: #cost.

]

{ #category : #inspect }
ExpenseReport >> gtViewMonthsOn: aView [
	<gtView>
	^ self firstMonth = self lastMonth
		ifTrue: [ aView empty ]
		ifFalse: [ 
			aView columnedList
				priority: 6;
				title: 'Month';
				column: 'Month' text: #firstMonth;
				column: 'Sum' text: #sum;
				items: [ (1 to: self lastMonth) collect: [:i | self month: i] ]].
]

{ #category : #inspect }
ExpenseReport >> gtViewTableOn: aView [
	<gtView>
	^ aView table
		priority: 5;
		title: 'Table';
		items:  self asTable;
		forCollectionOfCollection
		
	
]

{ #category : #inspect }
ExpenseReport >> gtViewTimelineOn: aView [
	<gtView>
	| data sum |
	^ aView explicit
		title: 'Timeline';
		priority: 3;
		stencil: [
			data := OrderedCollection new.
			sum := 0.
			self groupByDate do: [:each | 
				data add: each expenses first date -> (each sum + sum).
				sum := sum + each sum. ].
			ExpensePlot new
				data: data;
				x: [:each | each key asSeconds];
				y: #value;
				budget: budget;
				plot
			].
]

{ #category : #inspect }
ExpenseReport >> gtViewTreeOn: aView [
	<gtView>
	^ aView columnedTree
		priority: 2;
		title: 'Tree';
		items: [ self groupByCategory ];
		column: 'Category' item: [:each | 
			(each isKindOf: ExpenseReport)
				ifTrue: [ each categories first ]
				ifFalse: ['' asRopedText] ];
		column: 'Date' item: [:each | 
			(each isKindOf: ExpenseReport)
				ifTrue: ['' asRopedText]
				ifFalse: [each date]];						
		column: 'Cost' item: [:each | 
			(each isKindOf: ExpenseReport)
				ifTrue: ['' asRopedText]
				ifFalse: [each cost]];	
		column: 'Sum' item: [:each |
			(each isKindOf: ExpenseReport)
				ifTrue: [ each sum ]
				ifFalse: ['' asRopedText]];
		column: 'Count' item: [:each |
			(each isKindOf: ExpenseReport)
				ifTrue: [ each size ]
				ifFalse: ['' asRopedText]];
		column: 'Average' item: [:each |
			(each isKindOf: ExpenseReport)
				ifTrue: [ (each sum / each size) rounded ]
				ifFalse: ['' asRopedText]];							
		expandAll;
		children: [ :each |
			(each isKindOf: ExpenseReport)
				ifTrue: [each expenses]
				ifFalse: [#()] ].
				
]

{ #category : #accessing }
ExpenseReport >> initialize [
	super initialize.
]

{ #category : #accessing }
ExpenseReport >> lastMonth [
	^ expenses last date monthIndex
]

{ #category : #filtering }
ExpenseReport >> month: aNumber [
	^ self year: (Date today year) month: aNumber.
]

{ #category : #accessing }
ExpenseReport >> printOn: aStream [
	| start stop |
	start := expenses first date month name.
	stop := expenses last date month name.
	start = stop 
		ifTrue: [ aStream nextPutAll: start ]
		ifFalse: [ aStream nextPutAll: start, '-', stop ].
	aStream 
		nextPutAll: ': ';
		nextPutAll: self sum asString. 
	
]

{ #category : #initalize }
ExpenseReport >> setHeader: aCollection1 expenses: aCollection2 [
    header := aCollection1.
	expenses := aCollection2.
]

{ #category : #accessing }
ExpenseReport >> size [
	^ expenses size
]

{ #category : #accessing }
ExpenseReport >> sum [
	^ expenses sum: #cost
]

{ #category : #accessing }
ExpenseReport >> timeSpan [
	^ expenses first date to: expenses last date
]

{ #category : #filtering }
ExpenseReport >> year: aNumber1 month: aNumber2 [
	| report |
	report := self filter: [:each | each date year = aNumber1 and: [each date month index = aNumber2]].
	report budget: 300000.
	^ report

]
