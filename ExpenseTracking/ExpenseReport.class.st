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
ExpenseReport class >> fromFile: path [
	^ path asFileReference readStreamDo: [:stream | self fromString: stream contents ]
]

{ #category : #'instance creation' }
ExpenseReport class >> fromServer [
	^ self fromUrl: 'http://192.168.0.10:8090/expense_2023.csv'.
]

{ #category : #'instance creation' }
ExpenseReport class >> fromString: aString [ 
	| csv header lines expenses |
	csv := CSVParser parse: aString.
	header := csv lines first values allButFirst collect: [:each | each value withoutQuoting].
	lines := csv lines allButFirst: 1.
	
	expenses := OrderedCollection new.
	lines do: [:line |		  	
	  | date cell dateCol |
	  dateCol := line values first value trim.
	  dateCol ifNotEmpty: [
	  	date := Date fromString: dateCol.
  		line values allButFirst doWithIndex: [:each :index |
  			cell := each value trim.
  			cell ifNotEmpty: [ 
  				expenses add: (Expense
					date: date
					cost: each value asNumber
					category: (self translateCategory:(header at: index)))
  			].
 	 	].
 	 ].  
	].
	^ self new setHeader: header expenses: expenses
]

{ #category : #'instance creation' }
ExpenseReport class >> fromUrl: aString [
	^ self fromString: (ZnClient new get: aString).
]

{ #category : #private }
ExpenseReport class >> translateCategory: aString [
	^ aString.
	
 
]

{ #category : #inspect }
ExpenseReport >> allMonths: year [
	^ (1 to: self lastMonth) collect: [ :i | self year: year month: i ]
]

{ #category : #converting }
ExpenseReport >> asTable [
	| table queue tagToColumn tags index cost |
	tags := self categories.
	table := OrderedCollection with: (OrderedCollection with: '' withAll: tags).
	tagToColumn := Dictionary newFromKeys: tags andValues: (1 to: tags size).
	
	queue := OrderedCollection withAll: expenses.
	self timeSpan every: 1 day do: [:datetime |
		| row date |
		date := datetime asDate.
		row := Array new: tags size.
		[queue notEmpty and: [queue first date = date]] whileTrue: [ 
			index := tagToColumn at: queue first category.
			cost := ((row at: index) ifNil: [ 0 ]) +  queue first cost.
			row at: index put: cost.
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

{ #category : #inspect }
ExpenseReport >> firstMonth [
	^ expenses first date monthIndex	
]

{ #category : #grouping }
ExpenseReport >> groupByCategory [
	| groups |
	groups := (expenses groupedBy: #category) values.
    ^ (groups collect: [:each | self class new setHeader: header expenses: each ]) 
    	sorted: [:a :b | a sum > b sum]
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
		ifFalse: [ aView columnedList
				priority: 6;
				title: 'Month';
				column: 'Month' text: #firstMonth;
				column: 'Sum' text: #sum;
				column: 'Average/Day'
					text:
						[ :each | (each sum / (Month month: each firstMonth) daysInMonth) rounded ];
				items: [ self allMonths: expenses first date year ] ] "XXX"
]

{ #category : #accessing }
ExpenseReport >> gtViewSummaryOn: aView [
	<gtView>
	^ aView columnedList
		title: 'Summary';
		priority: 6;
		items: [self summary];
		column: 'Month' text: #key;
		column: 'Cost' text: #value.
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

{ #category : #accessing }
ExpenseReport >> month: aNumber [
	^ self year: Date today year month: aNumber

]

{ #category : #accessing }
ExpenseReport >> monthlyAverage: categories [
	^ ((categories collect: [:each | (self category: each) sum ]) sum / (self lastMonth - self firstMonth +1)) rounded
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

{ #category : #accessing }
ExpenseReport >> saveAs: path [
	path asFileReference
		createFile; 
		writeStreamDo: [:stream |
			self asTable do: [:row |
				row do: [:col |
					(col isKindOf: Date) 
						ifTrue: [ stream nextPutAll: col mmddyyyy. ]
						ifFalse: [
							col ifNotNil: [ stream nextPutAll: col asString ].	
						].
						stream nextPut: $,.
				].
				stream crlf.
			]
		].
]

{ #category : #initalize }
ExpenseReport >> setHeader: aCollection1 expenses: aCollection2 [
    header := (aCollection1 collect: [:each | self class translateCategory: each]).
    header removeDuplicates.
	expenses := aCollection2.
]

{ #category : #accessing }
ExpenseReport >> size [
	^ expenses size
]

{ #category : #accessing }
ExpenseReport >> sum [
	^ expenses ifEmpty: [ 0 ] ifNotEmpty: [ expenses sum: #cost ]
]

{ #category : #accessing }
ExpenseReport >> summary [
	^ {
	    #totalFood ->       	(self monthlyAverage: #('food delivery' 'groceries' 'snacks')).
	    #foodDelivery ->    	(self monthlyAverage: #('food delivery')).
	    #totalHousing ->        (self monthlyAverage: #('common charges' 'water' 'electricity' 'insurance')).
	    #maintenance ->     	(self monthlyAverage: #('maintenance')).
	    #publicTransport -> 	(self monthlyAverage: #('public transport')).
	    #sport ->           	(self monthlyAverage: #('sport')).
        #totalMedical ->        (self monthlyAverage: #('medical' 'mental health')).
	    #totalEntertainment ->  (self monthlyAverage: #('entertainment' 'travel')).
	    #all -> (((self firstMonth to: self lastMonth) collect: [:i |  ((self month: i) ) sum ]) average rounded).
	}
]

{ #category : #accessing }
ExpenseReport >> timeSpan [
	^ expenses first date to: expenses last date
]

{ #category : #accessing }
ExpenseReport >> totalEntertainment [
	^ (self category: 'entertainment') sum 
	+ (self category: 'travel') sum
]

{ #category : #accessing }
ExpenseReport >> totalFood [
	^ (self category: 'groceries') sum 
	+ (self category: 'food delivery') sum
	+ (self category: 'snacks') sum
]

{ #category : #accessing }
ExpenseReport >> totalHousingExpense [
	^ (self category: 'common charges') sum 
	+ (self category: 'water') sum 
	+ (self category: 'electricity') sum
	+ (self category: 'insurance') sum
]

{ #category : #accessing }
ExpenseReport >> totalMedical [
	^ (self category: 'medical') sum 
	+ (self category: 'mental health') sum
]

{ #category : #filtering }
ExpenseReport >> year: aNumber1 month: aNumber2 [
	| report |
	report := self filter: [:each | each date year = aNumber1 and: [each date month index = aNumber2]].
	report budget: 400000.
	^ report

]
