define [
	"controller/ViewController"
	"router/MainRouter"
	"collection/ToDoCollection"
	"collection/TagCollection"
	"view/nav/ListNavigation"
	"controller/TaskInputController"
	"controller/SidebarController"
	"controller/ScheduleController"
	"controller/FilterController"
	"controller/SettingsController"
	"controller/ErrorController"
	], (ViewController, MainRouter, ToDoCollection, TagCollection, ListNavigation, TaskInputController, SidebarController, ScheduleController, FilterController, SettingsController, ErrorController) ->
	class Swipes
		constructor: ->
			@errors = new ErrorController()
			@todos = new ToDoCollection()
			@todos.on( "reset", @init, @ )
			@fetchTodos()

		init: ->
			@cleanUp()

			@tags = new TagCollection()
			@viewController = new ViewController()
			@nav = new ListNavigation()
			@router = new MainRouter()
			@scheduler = new ScheduleController()
			@input = new TaskInputController()
			@sidebar = new SidebarController()
			@filter = new FilterController()
			@settings = new SettingsController()

			Backbone.history.start( pushState: no )
		cleanUp: ->
			@tags?.destroy()
			@viewController?.destroy()
			@nav?.destroy()
			@router?.destroy()
			@scheduler?.destroy()
			@input?.destroy()
			@sidebar?.destroy()
			@filter?.destroy()
			@settings?.destroy()

			# If we init multiple times, we need to make sure to stop the history between each.
			if Backbone.History.started then Backbone.history.stop()
		fetchTodos: ->
			@todos.fetch()