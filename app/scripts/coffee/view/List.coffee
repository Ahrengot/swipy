define ["underscore", "view/Default", "view/list/ActionBar", "text!templates/todo-list.html"], (_, DefaultView, ActionBar, ToDoListTmpl) ->
	DefaultView.extend
		init: ->
			# This deferred is resolved after view has been transitioned in
			@transitionDeferred = new $.Deferred()

			# Set HTML tempalte for our list
			@template = _.template ToDoListTmpl

			# Store subviews in this array so we can kill them (and free up memory) when we no longer need them
			@subviews = []

			# Render the list whenever it updates
			@listenTo( swipy.todos, "add remove reset change:completionDate change:schdule", @renderList )

			# Handle completed tasks
			@listenTo( Backbone, "complete-task", @completeTasks )
		render: ->
			@renderList()
			return @
		sortTasks: (tasks) ->
			return _.sortBy tasks, (model) -> model.get( "schedule" ).getTime()
		groupTasks: (tasksArr) ->
			tasksArr = @sortTasks tasksArr
			tasksByDate = _.groupBy( tasksArr, (m) -> m.get "scheduleStr" )
			return ( { deadline, tasks } for deadline, tasks of tasksByDate )
		getTasks: ->
			# Fetch todos that are active
			return swipy.todos.getActive()
		renderList: ->
			type = if Modernizr.touch then "Touch" else "Desktop"

			require ["view/list/#{type}Task"], (TaskView) =>
				# Remove any old HTML before appending new stuff.
				@$el.empty()
				@killSubViews()

				todos = @getTasks()

				@beforeRenderList todos

				for group in @groupTasks todos
					tasksJSON = _.invoke( group.tasks, "toJSON" )
					$html = $( @template { title: group.deadline, tasks: tasksJSON } )
					list = $html.find "ol"
					
					for model in group.tasks
						view = new TaskView( { model } )
						@subviews.push view
						list.append view.el

					@$el.append $html
					
				@afterRenderList todos

		beforeRenderList: (todos) ->
		afterRenderList: (todos) ->

		completeTasks: (tasks) ->
			console.log "Complete: ", tasks

		transitionInComplete: ->
			@actionbar = new ActionBar()
			@transitionDeferred.resolve()
		killSubViews: ->
			view.remove() for view in @subviews
			@subviews = []
		customCleanUp: ->
			# Extend this in subviews
		cleanUp: ->
			# A hook for the subviews to do custom clean ups
			@customCleanUp()

			# Reset transitionDeferred
			@transitionDeferred = null

			# Unbind all events
			@stopListening()
			
			# Deactivate actionbar (Do this before killing subviews)
			@actionbar.kill()

			# Deselect all todos, so selection isnt messed up in new view
			swipy.todos.invoke( "set", { selected: no } )
			
			# Run clean-up routine on sub views
			@killSubViews()


			# Clean up DOM element
			@$el.empty()
