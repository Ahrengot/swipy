define [
	"underscore"
	"gsap"
	], (_, TweenLite, EditTaskView) ->
	class ViewController
		constructor: (opts) ->
			@init()

		init: ->
			# Listen for navigation events
			Backbone.on( 'navigate/view', @goto, @ )
			Backbone.on( 'edit/task', @editTask, @ )

		goto: (slug, options) ->
			@loadView(slug).then (View) =>
				newView = new View( el: "ol.todo-list.#{ slug }" )

				if @currView? then @transitionOut( @currView ).then =>
					@transitionIn( newView ).then ->
						newView.transitionInComplete.call newView, options

				else @transitionIn( newView ).then ->
					newView.transitionInComplete.call newView, options

		editTask: (taskId) ->
			console.log "edit"
			model = m for m in swipy.collections.todos.models when m.id is taskId or m.get("tempId") is taskId
			if not model?
				swipy.router.navigate( "", yes )
				return console.warn "Model with id #{taskId} couldn't be found — Returning to root"

			if @currView?
				@transitionOut( @currView ).then => @loadTaskEditor model
			else @loadTaskEditor model

		loadTaskEditor: (model) ->
			require ["js/view/editor/TaskEditor"], (EditTaskView) =>
				editView = new EditTaskView( model: model )
				$("#main-content").prepend editView.el
				@transitionIn( editView ).then ->
					editView.transitionInComplete?.call editView
		loadView: (slug) ->
			dfd = new $.Deferred()
			if slug is "scheduled" then require ["js/view/Scheduled"], (View) -> dfd.resolve View
			else if slug is "completed" then require ["js/view/Completed"], (View) -> dfd.resolve View
			else require ["js/view/Todo"], (View) -> dfd.resolve View

			return dfd.promise()

		transitionOut: (view) ->
			dfd = new $.Deferred()

			opts =
				alpha: 0
				onComplete: =>
					view.$el.addClass "hidden"
					view.remove()
					dfd.resolve()

			TweenLite.to( view.$el, 0, opts )

			return dfd.promise()
		transitionIn: (view) ->
			dfd = new $.Deferred()

			opts =
				alpha: 1
				onComplete: dfd.resolve

			view.$el.removeClass "hidden"
			TweenLite.fromTo( view.$el, 0, { alpha: 0 }, opts )

			@currView = view

			return dfd.promise()
		destroy: ->
			@currView?.remove()
			Backbone.off( null, null, @ )