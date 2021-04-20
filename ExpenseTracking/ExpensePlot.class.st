Class {
	#name : #ExpensePlot,
	#superclass : #Object,
	#instVars : [
		'data',
		'xBlock',
		'yBlock',
		'lineColor',
		'x0',
		'y0',
		'canvas',
		'axisColor',
		'totalWidth',
		'totalHeight',
		'width',
		'height',
		'budget',
		'budgetColor',
		'xmin',
		'xmax',
		'ymax',
		'yTick',
		'xTick',
		'xs',
		'ys',
		'font'
	],
	#category : #ExpenseTracking
}

{ #category : #example }
ExpensePlot class >> squares [
	<gtExample>
	^ self new
		data: { 0 -> 0. 1 -> 1. 2 ->4. 3->9. 4->16. 5->25 };
		x: #key;
		y: #value;
		budget: 25;
		xTick: 1;
		yTick: 5;
		plot
	

]

{ #category : #accessing }
ExpensePlot >> budget: aNumber [
	budget := aNumber
]

{ #category : #private }
ExpensePlot >> cashLeft [
	^ budget ifNil: [ 0 ] ifNotNil: [ budget - self spent ]
]

{ #category : #private }
ExpensePlot >> cashPerDayLeft [
	^ self daysLeft = 0
		ifTrue: [ 0 ]
		ifFalse: [ (self cashLeft / self daysLeft) rounded ]
]

{ #category : #private }
ExpensePlot >> connect: point1 to: point2 [
	canvas stroke
		path: (canvas path moveTo: point1; lineTo: point2; finish);
		paint: lineColor;
		width: 2;
		draw.

]

{ #category : #accessing }
ExpensePlot >> data: aCollection [
	data := aCollection
]

{ #category : #private }
ExpensePlot >> daysLeft [
	^ self lastDate month daysInMonth - self lastDate dayOfMonth
]

{ #category : #private }
ExpensePlot >> dot: aPoint [
	canvas fill
		path: (canvas shape circleAt: aPoint radius: 3);
		paint: lineColor;
		draw. 
]

{ #category : #private }
ExpensePlot >> drawAxis [
	| axis text metrics |
	axis := canvas path
		moveTo: x0@(y0 + height);
		lineTo: (x0+width)@(y0+height);
		moveTo: x0@y0;
		lineTo: x0@(y0+height);				
		close;
		finish.		
	canvas stroke
		path: axis;
		paint: axisColor;
		width: 2;
		draw.		
	0 to: ymax by: yTick do: [:i |
		| tick |
		tick := canvas path
			moveTo: (x0-3)@(self translateY: i);
			lineTo: (x0+3)@(self translateY: i);			
			close;
			finish.
		canvas stroke
			path: tick;
			paint: axisColor;
			width: 1;
			draw.						
		text := canvas text
			paint: axisColor;
  		  string: i asString;
  		  font: font.
  	  metrics := text measure textMetrics.
  	  text 
		    baseline: (x0 - metrics width)@(self translateY: i) - 3;
			draw.
	].
	
	xmin to: xmax by: xTick do: [:i |
		| tick |
		tick := canvas path
			moveTo: (self translateX: i)@(height + y0-3);
			lineTo: (self translateX: i)@(height + y0+3);		
			close;
			finish.
		canvas stroke
			path: tick;
			paint: axisColor;
			width: 1;
			draw
	].
]

{ #category : #private }
ExpensePlot >> drawBackground [
	canvas fill
		path: (0@0 extent: (width+2*x0)@(height + 2*y0));
		paint: (Color fromHexString: '#FEFEFF');
		draw.
	canvas fill
		path: (x0@y0 extent: width@height);
		paint: (Color fromHexString: '#FDFDFD');
		draw.	
]

{ #category : #private }
ExpensePlot >> drawBudget [
	budget ifNotNil: [
	    | y |
		y := self translateY: budget.
		canvas stroke
			path: (canvas path moveTo: x0@y; lineTo: (width+x0)@y; finish);
			strokeOptions: (canvas strokeOptions dashPattern: #(4 4));
			paint: (Color red alpha: 0.6);
		width: 2;
		draw.	
	].
]

{ #category : #private }
ExpensePlot >> drawLabels [
	| budgetLabel xLabel budgetMetrics xMetrics |
	budgetLabel := canvas text
		paint: (self cashLeft < 0 ifTrue: [Color red] ifFalse: [Color green muchDarker]);
		string: self summary;
		font: font.
	budgetMetrics := budgetLabel measure.
	budgetLabel
		baseline: (x0 + ((width - budgetMetrics textMetrics width) / 2.0)) @ (y0 - 5);
		draw.
	xLabel := canvas text
		paint: axisColor;
		string: 'Date';
		font: font.
	xMetrics := xLabel measure.
	xLabel
		baseline:
			(x0 + ((width - xMetrics textMetrics width) / 2.0))
				@ (height + y0 + xMetrics textMetrics height + 3);
		draw
]

{ #category : #private }
ExpensePlot >> drawPoints [
	| prior |
	1 to: data size do: [:i |
		| x y |
		x := self translateX: (xs at: i).
		y := self translateY: (ys at: i).
		prior ifNotNil: [ self connect: prior to: x@y ].
		self dot: x@y.
		prior := x@y.
	].
]

{ #category : #initialization }
ExpensePlot >> initialize [
	super initialize.
	totalWidth := 600 asFloat.
	totalHeight := 500 asFloat.
	x0 := 50.
	y0 := 50.
	lineColor := Color fromHexString: '#459394'.
	axisColor := Color fromHexString: '#606060'.
	budgetColor := Color red.
	yTick := 50000.
	xTick := 7 days asSeconds.

]

{ #category : #private }
ExpensePlot >> lastDate [
	^ Date fromSeconds: xs last
]

{ #category : #plot }
ExpensePlot >> plot [
	data ifEmpty: [ ^ (SkiaCanvas extent:0@0) asForm ].
	
	width := totalWidth - x0.
	height := totalHeight - y0.
	
	xs := data collect: xBlock.
	ys := data collect: yBlock.
	xmin := xs min.
	xmax := xs max.
	ymax := ys max.
	budget ifNotNil: [ymax := ymax max: budget].			
			
	canvas := SkiaCanvas extent: (width + (2*x0))@(height+(2*y0)).
	font := canvas font size: 12; weightNormal; build.						
	self drawBackground.
	self drawAxis.	
	self drawLabels.
	self drawBudget.
	self drawPoints.
	
	^ canvas 
		flush;
		asForm

]

{ #category : #private }
ExpensePlot >> spent [
	^ ys ifEmpty: [ 0 ] ifNotEmpty: [ ys last ]
]

{ #category : #private }
ExpensePlot >> summary [
	^ budget
		ifNil: [ 'Spent {1}' format: {self spent} ]
		ifNotNil:[ self summaryWithBudget ]
]

{ #category : #private }
ExpensePlot >> summaryWithBudget [
	^ 'Spent {1} out of {2}. {3}' format:{
		self spent.
		budget.
		(self cashLeft < 0
			ifTrue: [ 'Overspent {1}.' format: {self cashLeft abs} ]
			ifFalse: [ '{1} left, {2}/day.' format: {
				self cashLeft.
				self cashPerDayLeft
			} ])}
]

{ #category : #private }
ExpensePlot >> translateX: x [ 
	^ [ (x - xmin) * width / (xmax - xmin) + x0 ] on: ZeroDivide do: [ x0 ]
]

{ #category : #private }
ExpensePlot >> translateY: y [
	^ y0 + height - (y * height / ymax)
]

{ #category : #accessing }
ExpensePlot >> x: aBlock [
	xBlock := aBlock
]

{ #category : #accessing }
ExpensePlot >> xTick: aNumber [
	xTick := aNumber
]

{ #category : #accessing }
ExpensePlot >> y: aBlock [
	yBlock := aBlock
]

{ #category : #accessing }
ExpensePlot >> yTick: aNumber [
	yTick := aNumber.
]
