define ["jquery", "model/ListSortModel", "gsap", "gsap-draggable", "hammerjs"], ($, ListSortModel, TweenLite, Draggable) ->
	class ListSortController
		constructor: (container, views, @onDragCompleteCallback) ->
			@model = new ListSortModel( container, views )
			@enableTouchListners()
		enableTouchListners: ->
			$( @model.container[0] ).hammer().on( "hold", "ol > li", @activate )
		disableTouchListeners: ->
			$( @model.container[0] ).hammer().off( "hold", @activate )
		activate: (e) =>
			@disableTouchListeners()
			@model.init()
			Backbone.on( "redraw-sortable-list", @redraw, @ )
			@listenForOrderChanges()
			@setInitialOrder()
			@createDraggable @model.getViewFromId e.currentTarget.getAttribute "data-id"
			if e then @draggable.startDrag e.gesture.srcEvent
		deactivate: (removeCSS = no) =>
			@stopListenForOrderChanges()
			@killDraggable removeCSS
			Backbone.off( "redraw-sortable-list", @redraw )
			@model.destroy()
			@enableTouchListners()
		setInitialOrder: ->
			@model.container.height ""
			@model.container.height( @model.container.height() )

			for view in @model.views
				view.$el.css { position: "absolute", width: "100%" }
				@reorderView.call( view, view.model, view.model.get( "order" ), no )
		createDraggable: (view) ->
			if @draggable? then @killDraggable()

			self = @

			dragOpts =
				type: "y"
				bounds: @model.container

				# Throwing / Dragging
				edgeResistance: 0.75
				throwProps: yes
				resistance: 3000
				snap: y: (endValue) ->
					# Snap to closest row
					return Math.max( @minY, Math.min( @maxY, Math.round( endValue / self.model.rowHeight ) * self.model.rowHeight ) );

				# Handlers
				onDragStartParams: [view, @model.views]
				onDragStart: @onDragStart
				onDragParams: [view, @model]
				onDrag: @onDrag
				onDragEndParams: [view, @model]
				onDragEnd: @onDragEnd
				onThrowComplete: =>
					@deactivate()
					@onDragCompleteCallback?.call @

			dragOpts.trigger = view.$el.find ".todo-content"
			@draggable = new Draggable( view.el, dragOpts )
		redraw: ->
			@killDraggable()
			@model.rows = @model.getRows()
			@setInitialOrder()
		listenForOrderChanges: ->
			for view in @model.views
				view.model.on( "change:order", @reorderView, view )
		stopListenForOrderChanges: ->
			if @model?
				view.model.off(null, null, @) for view in @model?.views
		onDragStart: (view, allViews) =>
			view.$el.addClass "selected"
			view.$el.off( "click", ".todo-content", view.toggleSelected )
		onDrag: (view, model) ->
			model.reorderRows( view, @y )
			model.scrollWindow( @minY, @maxY, @y, @pointerY )
		onDragEnd: (view, model) ->
			model.reorderRows( view, @endY )
			model.oldTaskY = null
			view.$el.removeClass( "selected" ) unless view.model.get "selected"
			setTimeout ->
					view.$el.on( "click", ".todo-content", view.toggleSelected )
				, 500
		reorderView: (model, newOrder, animate = yes) ->
			dur = if animate then 0.3 else 0
			TweenLite.to( @el, dur, { y: newOrder * @$el.height() } )
		killDraggable: (removeCSS) ->
			if @draggable?
				@draggable.disable()
				@draggable = null
				@removeInlineStyles() if removeCSS
		removeInlineStyles: ->
			view.$el.removeAttr "style" for view in @model.views
		destroy: ->
			@deactivate yes
			@disableTouchListeners()
			@model = null