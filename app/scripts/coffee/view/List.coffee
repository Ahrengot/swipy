define ["underscore", "view/Default", "text!templates/todo-list.html"], (_, DefaultView, TodoListTemplate) ->
	DefaultView.extend
		events:
			if Modernizr.touch then "tap" else "click "
		init: ->
			# Set HTML tempalte for our list
			@template = _.template TodoListTemplate

			# Store subviews in this array so we can kill them (and free up memory) when we no longer need them
			@subviews = []

			# Render the list whenever it updates
			#swipy.collection.on "change", @renderList, @
		render: ->
			@renderList()
			return @
		groupTasks: (data) ->
			# result = _.groupBy( data, (json) -> json.scheduleString )
			# debugger
			
			{ items: data }
		getDummyData: ->
			data = [
					title: "Follow up on Martin"
					order: 0
					schedule: new Date("September 16, 2013 16:30:02")
					completionDate: null
					repeatOption: "never"
					repeatDate: null
					tags: ["work", "client"]
					notes: ""
				,
					title: "Make visual research"
					order: 1
					schedule: new Date("October 13, 2013 11:13:00")
					completionDate: null
					repeatOption: "never"
					repeatDate: null
					tags: ["work", "Project y19"]
					notes: ""
				,
					title: "Buy a new Helmet"
					order: 2
					schedule: new Date("March 1, 2014 16:30:02")
					completionDate: null
					repeatOption: "never"
					repeatDate: null
					tags: ["Personal", "Bike", "Outside"]
					notes: ""
				,
					title: "Renew Wired Magazine subscription"
					order: 3
					schedule: new Date("September 14, 2013 16:30:02")
					completionDate: null
					repeatOption: "never"
					repeatDate: null
					tags: ["Personal", "Home"]
					notes: ""
				,
					title: "Get a Haircut"
					order: 4
					schedule: new Date("September 14, 2013 16:30:02")
					completionDate: null
					repeatOption: "never"
					repeatDate: null
					tags: ["Errand", "Home"]
					notes: ""
				,
					title: "Clean up the house"
					order: 5
					schedule: new Date("September 15, 2013 16:30:02")
					completionDate: null
					repeatOption: "never"
					repeatDate: null
					tags: ["Errand", "City"]
					notes: ""
			]

			models = []
			require ["model/ToDoModel"], (Model) ->
				for obj in data
					models.push new Model obj

			return models
		renderList: ->
			# items = new Backbone.Collection( swipy.collection.getActive() )
			items = new Backbone.Collection @getDummyData()
			@$el.html( @template @groupTasks items.toJSON() )
			@afterRenderList items
		afterRenderList: (models) ->
			type = if Modernizr.touch then "Touch" else "Desktop"

			require ["view/list/#{type}ListItem"], (ListItemView) => 
				@$el.find('ol.todo > li').each (i, el) =>
					@subviews.push new ListItemView el: el, model: models.at(i)
		customCleanUp: ->
			# Unbind all events
			#swipy.collection.off()
			
			view.remove() for view in @subviews
