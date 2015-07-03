define [
	"jquery"
	"backbone"
	"localStorage"
	"js/model/extra/ClockWork"
	"js/viewcontroller/MainViewController"
	"js/controller/AnalyticsController"
	"js/router/MainRouter"
	"js/collection/ToDoCollection"
	"js/collection/TagCollection"
	"js/collection/WorkCollection"
	"js/controller/TaskInputController"
	"js/controller/SidebarController"
	"js/viewcontroller/SidebarViewController"
	"js/controller/ScheduleController"
	"js/controller/FilterController"
	"js/controller/SettingsController"
	"js/controller/ErrorController"
	"js/controller/SyncController"
	"js/controller/APIController"
	"js/controller/KeyboardController"
	"js/controller/BridgeController"
	"js/controller/UserController"
	"js/controller/WorkController"
	"gsap"
	], ($, Backbone, BackLocal, ClockWork, MainViewController, AnalyticsController, MainRouter, ToDoCollection, TagCollection, WorkCollection, TaskInputController, SidebarController, SidebarViewController, ScheduleController, FilterController, SettingsController, ErrorController, SyncController, APIController, KeyboardController, BridgeController, UserController, WorkController) ->
	class Swipes
		UPDATE_INTERVAL: 30
		UPDATE_COUNT: 0
		handleQueryString:(queryString) ->
			clean = false
			if queryString and queryString.href
				@href = queryString.href
				if history.pushState
					newurl = window.location.protocol + "//" + window.location.host + window.location.pathname
					if window.location.hash
						newurl += window.location.hash
					window.history.pushState({path:newurl},'',newurl)
				
		constructor: ->
			##@tags.fetch()
			$(window).focus @openedWindow

		manualInit: ->
			#@hackParseAPI()
			# Base app data
			@todos = new ToDoCollection()
			@tags = new TagCollection()

			@bridge = new BridgeController()
			@analytics = new AnalyticsController()
			@errors = new ErrorController()
			
			
			@workSessions = new WorkCollection()

			# Synchronization
			@settings = new SettingsController()
			@sync = new SyncController()
			@api = new APIController()
			@updateTimer = new ClockWork()

			# Keyboard/Shortcut handler
			@shortcuts = new KeyboardController()
			
			
		start: ->
			if @sync.lastUpdate?
				@tags.fetch()
				@todos.fetch()
				@workSessions.fetch()
				_.invoke(@todos.models, "set", { selected: no } )
				@todos.repairActionStepsRelations()
				@init()
			else
				Backbone.once( "sync-complete", @init, @ )
			@sync.sync()
		init: ->
			@cleanUp()

			@sidebarVC = new SidebarViewController()
			@mainViewController = new MainViewController()
			@router = new MainRouter()
			
			
			@scheduler = new ScheduleController()
			@input = new TaskInputController()
			@sidebar = new SidebarController()

			@filter = new FilterController()
			@userController = new UserController()
			@workmode = new WorkController()

			Backbone.history.start( pushState: no )
			$(".load-indicator").remove()
			

			$('.search-result a').click( (e) ->
				swipy.filter.clearFilters()
				Backbone.trigger( "remove-filter", "all" )
				return false
			)
			@workmode.checkForWork()
			if @href
				switch @href
					when "keyboard" then @sidebar.showKeyboardShortcuts()
					
				@href = false

		cleanUp: ->
			#@stopAutoUpdate()
			##@tags?.destroy()
			@mainViewController?.destroy()
			@router?.destroy()
			@scheduler?.destroy()
			@input?.destroy()
			@sidebar?.destroy()
			@filter?.destroy()
			@settings?.destroy()

			# If we init multiple times, we need to make sure to stop the history between each.
			if Parse.History.started then Parse.history.stop()
		openedWindow: ->
			Backbone.trigger("opened-window")
			if swipy?
				swipy.sync.sync()
				swipy.userController.fetchUser()
			