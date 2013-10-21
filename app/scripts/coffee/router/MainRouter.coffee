define ['backbone'], (Backbone) ->
	MainRouter = Backbone.Router.extend
		routes:
			"settings": "settings"
			"settings/:id": "settings"
			"edit/:id": "edit"
			"list/:id": "gotoList"
			"*": "root"
		root: ->
			@navigate( "list/todo", yes )
		gotoList: (id) -> 
			console.log "goto #{id}"
			Backbone.trigger "hide-settings"
			Backbone.trigger( "navigate/view", id )
		edit: (taskId) ->
			Backbone.trigger "hide-settings"
			Backbone.trigger( "edit/task", taskId )
		settings: (route) ->
			console.log "Going to settings"
			Backbone.trigger "show-settings"
			if route then Backbone.trigger( "settings/view", route )