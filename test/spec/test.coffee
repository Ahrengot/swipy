
require [
	"jquery", 
	"underscore", 
	"backbone",
	"model/ToDoModel"

	], ($, _, Backbone, ToDoModel) ->
	
	contentHolder = $("#content-holder")

	helpers = 
		getDummyModels: ->
			[
					title: "Follow up on Martin"
					order: 0
					schedule: new Date()
					completionDate: null
					repeatOption: "never"
					repeatDate: null
					tags: ["work", "client"]
					notes: ""
				,
					title: "Completed Dummy task #3"
					order: 2
					schedule: new Date()
					completionDate: new Date("July 12, 2013 11:51:45")
					repeatOption: "never"
					repeatDate: null
					tags: ["work", "client"]
					notes: ""
				,
					title: "Dummy task #2"
					order: 1
					schedule: new Date("October 13, 2013 11:13:00")
					completionDate: null
					repeatOption: "never"
					repeatDate: null
					tags: ["work", "client"]
					notes: ""
				,
					title: "Dummy task #4"
					order: 3
					schedule: new Date("September 18, 2013 16:30:02")
					completionDate: null
					repeatOption: "never"
					repeatDate: null
					notes: ""
			]
		renderTodoList: ->
			dfd = new $.Deferred()
			require ["text!templates/task.html", "view/list/DesktopTask"], (TaskTmpl, View) ->
				tmpl = _.template TaskTmpl

				model = new ToDoModel { title: "Tomorrow" }

				contentHolder.html $("<ol class='todo'></ol>").append( tmpl model.toJSON() )

				dfd.resolve()

			return dfd.promise()

	#
	# The Basics
	#
	describe "Basics", ->	
		it "App should be up and running", ->
			# Overwrite todos with dummy data
			swipy.todos.reset helpers.getDummyModels()
			
			expect( swipy ).to.exist

		it "Should have scheduled tasks for testing", ->
			expect( swipy.todos.getScheduled() ).to.have.length.above 0
		
		it "Should have active tasks for testing", ->
			expect( swipy.todos.getActive() ).to.have.length.above 0
		
		it "Should have completed tasks for testing", ->
			expect( swipy.todos.getCompleted() ).to.have.length.above 0

	#
	# To Do Model
	#
	describe "List Item model", ->
		model = new ToDoModel()

		it "Should create scheduleStr property when instantiated", ->
			expect( model.get("scheduleStr") ).to.equal "the past"
		
		it "Should update scheduleStr when schedule property is changed", ->
			date = model.get "schedule"

			# unset for change event to occur
			model.unset "schedule"
			
			date.setDate date.getDate()+1
			model.set( "schedule", date )

			expect( model.get("scheduleStr") ).to.equal "Tomorrow"

		it "Should create timeStr property when model is instantiated", ->
			expect( model.get("timeStr") ).to.exist

		it "Should update timeStr when schedule property is changed", ->
			timeBeforeChange = model.get "timeStr"
			
			date = model.get "schedule"
			# Unset because its an object and wont trigger a change if we just update the object itself.
			model.unset "schedule"

			date.setHours date.getHours() - 1
			model.set( "schedule", date )
			
			timeAfterChange = model.get "timeStr"
			
			expect( timeBeforeChange ).to.not.equal timeAfterChange

		it "Should update completedStr when completionDate is changed", ->
			model.set( "completionDate", new Date() )
			expect( model.get "completionStr" ).to.exist
			expect( model.get "completionTimeStr" ).to.exist

	#
	# To Do Collection
	#
	require ["collection/ToDoCollection"], (ToDoCollection) ->
		describe "To Do collection", ->
			todos = null

			beforeEach ->
				now = new Date()
				future = new Date()
				past = new Date()

				# Put now 1 second in the past
				now.setSeconds now.getSeconds() - 1
				future.setDate now.getDate() + 1
				past.setDate now.getDate() - 1

				scheduledTask = new ToDoModel { title: "scheduled task", schedule: future }
				todoTask = new ToDoModel { title: "todo task", schedule: now }
				completedTask = new ToDoModel { title: "completed task", completionDate: past }
				
				todos = new ToDoCollection [scheduledTask, todoTask, completedTask]

			it "getActive() should return all tasks to do right now", ->
				expect(todos.getActive().length).to.equal 1
			
			it "getScheduled() Should return all scheduled tasks", ->
				expect(todos.getScheduled().length).to.equal 1
			
			it "getCompleted() Should return all completed tasks", ->
				expect(todos.getCompleted().length).to.equal 1

	#
	# To Do View
	#
	require ["collection/ToDoCollection", "view/list/DesktopTask"], (ToDoCollection, View) ->
		helpers.renderTodoList().then ->
			list = contentHolder.find(".todo ol")

			do ->
				model = new ToDoModel helpers.getDummyModels()[0]
				view = new View { model }
				
				describe "To Do View: Selecting", ->

					list.append view.el
					view.$el.find( ".todo-content" ).click()
				
					it "Should toggle selected property on model when clicked", ->
						expect( model.get "selected" ).to.be.true
					
					it "Should toggle selected class on element when clicked", ->
						expect( view.$el.hasClass "selected" ).to.be.true
				

			do ->
				todos = views = null

				describe "To Do View: Hovering", ->
					beforeEach ->
						# Clear out list to remove any 'unsanitary' data
						list.empty()
						todos = new ToDoCollection helpers.getDummyModels()
						views = ( new View( model: model ) for model in todos.models )
						list.append view.el for view in views

					after ->
						contentHolder.empty()


					it "Should be unresponsive to 'hover-complete' event when not selected", ->
						Backbone.trigger "hover-complete"
						count = 0
						count++ for view in views when view.$el.hasClass "hover-complete"

						expect( count ).to.equal 0

					it "Should be unresponsive to 'hover-schedule' event when not selected", ->
						Backbone.trigger "hover-schedule"
						count = 0
						count++ for view in views when view.$el.hasClass "hover-schedule"

						expect( count ).to.equal 0
					

					it "Should get the 'hover-left' CSS class when 'hover-complete' event is triggered when selected", ->
						# Make 2 views selected
						views[0].model.set( "selected", true )
						views[1].model.set( "selected", true )

						Backbone.trigger "hover-complete"
						
						count = 0
						count++ for view in views when view.$el.hasClass "hover-left"

						expect( count ).to.equal 2

					it "Should remove the 'hover-left' CSS class when 'unhover-complete' event is triggered when selected", ->
						# Make 2 views selected
						views[0].model.set( "selected", true )
						views[1].model.set( "selected", true )

						views[0].$el.addClass "hover-complete"
						views[1].$el.addClass "hover-complete"

						Backbone.trigger "unhover-complete"
						count = 0
						count++ for view in views when view.$el.hasClass "hover-left"

						expect( count ).to.equal 0

					it "Should get the 'hover-right' CSS class when 'hover-schedule' event is triggered when selected", ->
						# Make 2 views selected
						views[0].model.set( "selected", true )
						views[1].model.set( "selected", true )

						Backbone.trigger "hover-schedule"
						
						count = 0
						count++ for view in views when view.$el.hasClass "hover-right"

						expect( count ).to.equal 2

					it "Should remove the 'hover-right' CSS class when 'unhover-schedule' event is triggered when selected", ->
						# Make 2 views selected
						views[0].model.set( "selected", true )
						views[1].model.set( "selected", true )

						views[0].$el.addClass "hover-right"
						views[1].$el.addClass "hover-right"

						Backbone.trigger "unhover-schedule"
						count = 0
						count++ for view in views when view.$el.hasClass "hover-right"

						expect( count ).to.equal 0

	#
	# Any list View
	#
	
	###
	require ["view/List", "model/ToDoModel"], (ListView, ToDo) ->
		contentHolder.empty()
		list = new ListView();
		list.$el.appendTo contentHolder
			
		describe "Base list view", ->
			children = list.$el.find "ol li"
			it "should add appropiate children rendering", ->
				expect( children ).to.have.length.above 0
			
			it "Should remove all nested children as part of the cleanUp routine", ->
				list.cleanUp()
				expect( children ).to.have.length.lessThan 1
	###

	#
	# Scheduled list View
	#
	require ["view/Schedule"], (ScheduleView) ->
		laterToday = new Date()
		tomorrow = new Date()
		nextMonth = new Date()
		now = new Date()

		laterToday.setSeconds now.getSeconds() + 1
		tomorrow.setDate now.getDate() + 1
		nextMonth.setMonth now.getMonth() + 1

		todos = [
			new ToDoModel( { title: "In a month", schedule: nextMonth } )
			new ToDoModel( { title: "Tomorrow", schedule: tomorrow } ), 
			new ToDoModel( { title: "In 1 hour", schedule: laterToday } ), 
		]

		view = new ScheduleView()

		describe "Schedule list view", ->
			it "Should order tasks by chronological order", ->
				result = view.groupTasks todos
				expect(result[0].deadline).to.equal "Later today"
				expect(result[1].deadline).to.equal "Tomorrow"

				# If 1 and 2 is correct we know that 3 is too.

	#
	# To do list View
	#
	require ["view/Todo"], (ToDoView) ->
		todos = [ new ToDoModel( title: "three" ), new ToDoModel( title: "two", order: 2 ), new ToDoModel( title: "one", order: 1 ) ]
		view = new ToDoView()

		describe "To Do list view", ->
			it "Should order tasks by models 'order' property", ->
				result = view.groupTasks todos
				expect(result[0].tasks[0].get "title").to.equal "one"
				expect(result[0].tasks[1].get "title").to.equal "two"
				expect(result[0].tasks[2].get "title").to.equal "three"

			it "Should make sure no two todos have the same order id", ->
				list = [ 
					new ToDoModel( { order: 0 } ),
					new ToDoModel( { order: 0 } ),
					new ToDoModel( { order: 2 } ),
					new ToDoModel( { order: 5 } )
				]

				newTasks = view.setTodoOrder list
				orders = _.invoke( newTasks, "get", "order" )

				expect(orders).to.have.length 4
				expect(orders).to.contain 0
				expect(orders).to.contain 1
				expect(orders).to.contain 2
				expect(orders).to.contain 3

			it "Should order todos by schdule date if no order is defined", ->
				first = new Date()
				second = new Date()
				third = new Date()

				second.setSeconds( second.getSeconds() + 1 )
				third.setSeconds( third.getSeconds() + 2 )

				list = [ 
					new ToDoModel( { title: "third", schedule: third } ),
					new ToDoModel( { title: "second", schedule: second } )
					new ToDoModel( { title: "first", schedule: first } )
				]

				result = view.setTodoOrder list
				firstModel = _.filter( result, (m) -> m.get( "title" ) is "first" )[0]
				secondModel = _.filter( result, (m) -> m.get( "title" ) is "second" )[0]
				thirdModel = _.filter( result, (m) -> m.get( "title" ) is "third" )[0]

				expect( result ).to.have.length 3
				expect( firstModel.get "order" ).to.equal 0
				expect( secondModel.get "order" ).to.equal 1
				expect( thirdModel.get "order" ).to.equal 2

			it "Should be able to mix in unordered and ordered items", ->
				first = new Date()
				second = new Date()

				second.setSeconds( second.getSeconds() + 1 )

				list = [ 
					new ToDoModel( { title: "third", schedule: second } ),
					new ToDoModel( { title: "first", schedule: first } ),
					new ToDoModel( { title: "second (has order)", order: 1 } ),
					new ToDoModel( { title: "fourth (has order)", order: 3 } )
				]

				result = view.setTodoOrder list
				firstModel = _.filter( result, (m) -> m.get( "title" ) is "first" )[0]
				secondModel = _.filter( result, (m) -> m.get( "title" ) is "second (has order)" )[0]
				thirdModel = _.filter( result, (m) -> m.get( "title" ) is "third" )[0]
				fourthModel = _.filter( result, (m) -> m.get( "title" ) is "fourth (has order)" )[0]

				expect( result ).to.have.length 4
				expect( firstModel.get "order" ).to.equal 0
				expect( secondModel.get "order" ).to.equal 1
				expect( thirdModel.get "order" ).to.equal 2
				expect( fourthModel.get "order" ).to.equal 3

			it "Should take models with order 3,4,5,6 and change them to 0,1,2,3", ->
				list = [ 
					new ToDoModel( { title: "first", order: 3 } ),
					new ToDoModel( { title: "second", order: 4 } ),
					new ToDoModel( { title: "third", order: 5 } ),
					new ToDoModel( { title: "fourth", order: 6 } )
				]

				result = view.setTodoOrder list
				first = _.filter( result, (m) -> m.get( "title" ) is "first" )[0]
				second = _.filter( result, (m) -> m.get( "title" ) is "second" )[0]
				third = _.filter( result, (m) -> m.get( "title" ) is "third" )[0]
				fourth = _.filter( result, (m) -> m.get( "title" ) is "fourth" )[0]

				expect( result ).to.have.length 4
				expect( first.get "order" ).to.equal 0
				expect( second.get "order" ).to.equal 1
				expect( third.get "order" ).to.equal 2
				expect( fourth.get "order" ).to.equal 3

			it "Should take models with order 0,1,11,5 and change them to 0,1,2,3", ->
				list = [ 
					new ToDoModel( { title: "first", order: 0 } ),
					new ToDoModel( { title: "second", order: 1 } ),
					new ToDoModel( { title: "third", order: 5 } ),
					new ToDoModel( { title: "fourth", order: 11 } )
				]

				result = view.setTodoOrder list
				first = _.filter( result, (m) -> m.get( "title" ) is "first" )[0]
				second = _.filter( result, (m) -> m.get( "title" ) is "second" )[0]
				third = _.filter( result, (m) -> m.get( "title" ) is "third" )[0]
				fourth = _.filter( result, (m) -> m.get( "title" ) is "fourth" )[0]

				expect( result ).to.have.length 4
				expect( first.get "order" ).to.equal 0
				expect( second.get "order" ).to.equal 1
				expect( third.get "order" ).to.equal 2
				expect( fourth.get "order" ).to.equal 3

			it "Should take models with order undefined,1,undefined,5 and change them to 0,1,2,3"

			it "Should take models with order 2,2,2,2 and change them to 0,1,2,3"
	
	#
	# Completed list View
	#
	require ["view/Completed"], (CompletedView) ->
		earlierToday = new Date()
		yesterday = new Date()
		prevMonth = new Date()
		now = new Date()

		earlierToday.setSeconds now.getSeconds() - 1
		yesterday.setDate now.getDate() - 1
		prevMonth.setMonth now.getMonth() - 1

		todos = [
			new ToDoModel( { title: "Last month", completionDate: prevMonth } )
			new ToDoModel( { title: "Yesterday", completionDate: yesterday } ), 
			new ToDoModel( { title: "An hour ago", completionDate: earlierToday } ), 
		]

		view = new CompletedView()

		describe "Completed list view", ->
			it "Should order tasks by reverse chronological order", ->
				result = view.groupTasks todos
				expect(result[0].deadline).to.equal "Earlier today"
				expect(result[1].deadline).to.equal "Yesterday"

				# If 1 and 2 is correct we know that 3 is too.

	require ["model/ScheduleModel", "momentjs"], (ScheduleModel, Moment) ->
		describe "Schedule model", ->
			model = null

			beforeEach ->
				model = new ScheduleModel()

			after ->
				$(".overlay.scheduler").remove()
			
			it "Should return a new date 3 hours in the future when scheduling for 'later today'", ->
				now = moment()
				newDate = model.getDateFromScheduleOption( "later today", now )
				
				expect( newDate ).to.exist

				parsedNewDate = moment newDate
				threeHoursInMs = 3 * 60 * 60 * 1000
				expect( parsedNewDate.diff now ).to.equal threeHoursInMs

			it "Should return a new date the same day at 18:00 when scheduling for 'this evening' (before 18.00)", ->
				today = moment()
				today.hour 17
				newDate = model.getDateFromScheduleOption( "this evening", today )
				
				expect( newDate ).to.exist

				parsedNewDate = moment newDate
				expect( parsedNewDate.hour() ).to.equal 18
				expect( parsedNewDate.day() ).to.equal today.day()

			it "Should set minutes and seconds to 0 when delaying a task to later today", ->

			it "Should return a new date the day after at 18:00 when scheduling for 'tomorrow evening' (after 18.00)", ->
				today = moment()
				today.hour 19
				newDate = model.getDateFromScheduleOption( "this evening", today )
				
				expect( newDate ).to.exist

				parsedNewDate = moment newDate
				expect( parsedNewDate.hour() ).to.equal 18
				expect( parsedNewDate.dayOfYear() ).to.equal today.dayOfYear() + 1

			it "Should return a new date the day after at 09:00 when scheduling for 'tomorrow'", ->
				today = moment()
				newDate = model.getDateFromScheduleOption( "tomorrow", today )
				
				expect( newDate ).to.exist

				parsedNewDate = moment newDate
				expect( parsedNewDate.dayOfYear() ).to.equal today.dayOfYear() + 1
				expect( parsedNewDate.hour() ).to.equal 9

			it "Should return a new date 2 days from now at 09:00 when scheduling for 'day after tomorrow'", ->
				today = moment()
				newDate = model.getDateFromScheduleOption "day after tomorrow"
				
				expect( newDate ).to.exist

				parsedNewDate = moment newDate
				expect( parsedNewDate.dayOfYear() ).to.equal today.dayOfYear() + 2
				expect( parsedNewDate.hour() ).to.equal 9

			it "Should return a new date this following saturday at 10:00 when scheduling for 'this weekend'", ->
				saturday = moment().endOf "week"
				saturday.day(6).hour(model.rules.weekend.morning)
				newDate = model.getDateFromScheduleOption( "this weekend", saturday )

				expect( newDate ).to.exist

				parsedNewDate = moment newDate
				expect( parsedNewDate.day() ).to.equal 6
				expect( Math.floor saturday.diff( parsedNewDate, "days", true ) ).to.equal -7
				expect( parsedNewDate.hour() ).to.equal 10

			it "Should return a new date this following monday at 9:00 when scheduling for 'next week'", ->
				monday = moment().startOf "week"
				monday.day(1).hour(model.rules.weekday.morning) # Defautl is sunday. Upgrade that to monday.
				newDate = model.getDateFromScheduleOption( "next week", monday )

				expect( newDate ).to.exist

				parsedNewDate = moment newDate
				expect( parsedNewDate.dayOfYear() ).not.to.equal monday.dayOfYear()
				expect( parsedNewDate.day() ).to.equal 1
				expect( Math.floor monday.diff( parsedNewDate, "days", true ) ).to.equal -7
				expect( parsedNewDate.hour() ).to.equal 9

			it "Should return null when scheduling for 'unspecified'", ->
				expect( model.getDateFromScheduleOption "unspecified" ).to.equal null
			
			describe "converting time", ->
				it "Should should not convert 'This evening' when it's before 18:00 hours", ->
					expect( model.getDynamicTime( "This Evening", moment("2013-01-01 17:59") ) ).to.equal "This Evening"

				it "Should convert 'This evening' to 'Tomorrow eve' when it's after 18:00 hours", ->
					expect( model.getDynamicTime( "This Evening", moment("2013-01-01 18:00") ) ).to.equal "Tomorrow Evening"

				it "Should convert 'Day After Tomorrow' to 'Wednesday' when we're on a monday", ->
					adjustedTime = moment()
					adjustedTime.day "Monday"

					expect( model.getDynamicTime( "Day After Tomorrow", adjustedTime ) ).to.equal "Wednesday"

				it "Should not convert 'This Weekend' when we're on a monday-friday", ->
					monday = moment().day("Monday")
					expect( model.getDynamicTime( "This Weekend", monday ) ).to.equal "This Weekend"

				it "Should convert 'This Weekend' to 'Next Weekend' when we're on a saturday/sunday", ->
					saturday = moment().day("Saturday")
					expect( model.getDynamicTime( "This Weekend", saturday ) ).to.equal "Next Weekend"

			describe "Rounding minutes and seconds", ->
				it "Should not alter minutes and seconds when delaying a task to later today", ->
					now = moment().minute(23)
					newDate = model.getDateFromScheduleOption( "later today", now )
					parsedNewDate = moment newDate
					
					expect( parsedNewDate.diff(now, "hours") ).to.equal 3				
					expect( parsedNewDate.minute() ).to.equal 23

				it "Should set minutes and seconds to 0 when selecting 'this evening'", ->
					now = moment().hour(12).minute(23).second(23)
					newDate = model.getDateFromScheduleOption( "this evening", now )
					parsedNewDate = moment newDate
					
					expect( parsedNewDate.hour() ).to.equal 18				
					expect( parsedNewDate.minute() ).to.equal 0
					expect( parsedNewDate.second() ).to.equal 0

				it "Should set minutes and seconds to 0 when selecting 'tomorrow'", ->
					newDate = model.getDateFromScheduleOption( "tomorrow", moment().minute(23).second(23) )
					parsedNewDate = moment newDate
					
					expect( parsedNewDate.minute() ).to.equal 0
					expect( parsedNewDate.second() ).to.equal 0

				it "Should set minutes and seconds to 0 when selecting 'day after tomorrow'", ->
					newDate = model.getDateFromScheduleOption( "day after tomorrow", moment().minute(23).second(23) )
					parsedNewDate = moment newDate
					
					expect( parsedNewDate.minute() ).to.equal 0
					expect( parsedNewDate.second() ).to.equal 0

				it "Should set minutes and seconds to 0 when selecting 'this weekend'", ->
					newDate = model.getDateFromScheduleOption( "this weekend", moment().minute(23).second(23) )
					parsedNewDate = moment newDate
					
					expect( parsedNewDate.minute() ).to.equal 0
					expect( parsedNewDate.second() ).to.equal 0

				it "Should set minutes and seconds to 0 when selecting 'next week'", ->
					newDate = model.getDateFromScheduleOption( "next week", moment().minute(23).second(23) )
					parsedNewDate = moment newDate
					
					expect( parsedNewDate.minute() ).to.equal 0
					expect( parsedNewDate.second() ).to.equal 0

	require ["controller/TaskInputController"], (TaskInputController) ->
		describe "Task Input", ->
			taskInput = null
			callback = null
			
			before ->
				$("body").append("<form id='add-task'><input></form>")
				taskInput = new TaskInputController()

			after ->
				taskInput.view.remove()
				taskInput = null

			describe "view", ->
				it "Should not trigger a 'create-task' event when submitting input, if the input field is empty"
					# Throw error if create-task is triggered
					# Backbone.once( "create-task", -> done new Error "'create-task' event was triggered" )
					# taskInput.view.$el.submit()

					# setTimeout =>
					# 		done()
					# 	, 200

				it "Should trigger a 'create-task' event when submitting actual input"
					# Backbone.once( "create-task", -> done() )

					# taskInput.view.input.val "here's a new task"
					# taskInput.view.$el.submit()

					# @timeout 200

			describe "controller", ->
				describe "parsing tags", ->
					it "Should be able to add tasks without tags", ->
						taskInput.createTask "I love not using tags"
						model = swipy.todos.findWhere { title: "I love not using tags" }
						expect( model ).to.exist
						expect( model.get "tags" ).to.have.length 0

					it "Should be able to parse 1 tag", ->
						result = taskInput.parseTags "I love #tags"
						expect(result).to.have.length 1
						expect(result[0]).to.equal "tags"

					it "Should be able to parse multiple tags", ->
						result = taskInput.parseTags "I love #tags, #racks, #stacks"
						expect(result).to.have.length 3
						expect(result).to.include "tags"
						expect(result).to.include "racks"
						expect(result).to.include "stacks"
					
					it "Should be able to parse tags with spaces", ->
						result = taskInput.parseTags "I love #tags, #racks and stacks"
						expect(result).to.have.length 2
						expect(result).to.include "tags"
						expect(result).to.include "racks and stacks"

					it "Should be able to seperate tags without commas", ->
						result = taskInput.parseTags "I love #tags, #racks #stacks"
						expect(result).to.have.length 3
						expect(result).to.include "tags"
						expect(result).to.include "racks"
						expect(result).to.include "stacks"

				describe "parsing title", ->
					it "Should not be able to add tags without a title", ->
						lengthBefore = swipy.todos.length
						taskInput.createTask "#just a tag"
						lengthAfter = swipy.todos.length
						expect( lengthBefore ).to.equal lengthAfter


					it "Should parse title without including 1 tag", ->
						result = taskInput.parseTitle "I love #tags"
						expect(result).to.equal "I love"
					
					it "Should parse title without including multiple tags", ->
						result = taskInput.parseTitle "I also love #tags, #rags"
						expect(result).to.equal "I also love"
					
					# it "Should parse title if it's defined after tags"

				it "Should add a new item to swipy.todos list when create-task event is fired", ->
					Backbone.trigger( "create-task", "Test task #tags, #rags" )
					model = swipy.todos.findWhere { "title": "Test task" }
					expect( model ).to.exist
					expect( model.get "tags" ).to.have.length 2
					expect( model.get "tags" ).to.include "tags"
					expect( model.get "tags" ).to.include "rags"

