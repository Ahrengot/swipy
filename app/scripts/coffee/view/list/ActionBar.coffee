define ["underscore", "backbone", "view/list/TagEditorOverlay"], (_, Backbone, TagEditorOverlay) ->
	Backbone.View.extend
		el: ".action-bar"
		events:
			"click .edit": "editTask"
			"click .tags": "editTags"
			"click .delete": "deleteTasks"
			"click .share": "shareTasks"
		initialize: ->
			@hide()
			@listenTo( swipy.todos, "change:selected", @toggle )
		toggle: ->
			if @shown
				if swipy.todos.where( selected: yes ).length is 0
					@hide()
			else
				if swipy.todos.where( selected: yes ).length > 0
					@show()
		show: ->
			@$el.toggleClass( "fadeout", no )
			@shown = yes

		hide: ->
			@$el.toggleClass( "fadeout", yes )
			@shown = no
		kill: ->
			@stopListening()
			@hide()
		editTask: ->
			targetCid = swipy.todos.findWhere( selected: yes ).cid
			swipy.router.navigate( "edit/#{ targetCid }", yes )
		editTags: ->
			@tagEditor = new TagEditorOverlay( models: swipy.todos.where( selected: yes ) )
		deleteTasks: ->
			targets = swipy.todos.where( selected: yes )
			if confirm "Delete #{targets.length} tasks?"
				for model in targets
					if model.has "order"
						order = model.get "order"
						model.unset "order"
						swipy.todos.bumpOrder( "up", order )
					model.destroy()

				@hide()
		shareTasks: ->
			alert "Task sharing is coming soon :)"
