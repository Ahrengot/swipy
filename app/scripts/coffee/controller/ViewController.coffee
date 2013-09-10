define ["gsap"], (TweenLite) ->
	class ViewController
		constructor: (opts) ->
			@init()
			@navLinks = $ ".list-nav a"
			@lists = $ "ol.todo-list"
		
		init: ->
			# Listen for navigation events
			$(document).on( 'navigate/page', (e, slug) => @goto slug )
		
		goto: (slug) ->
			@updateNavigation slug
			@transitionViews slug
		
		updateNavigation: (slug) =>
			@navLinks.each ->
				link = $(@)
				isCurrLink = if link.attr("href")[1...] is slug then yes else no
				link.toggleClass( 'active', isCurrLink )
		
		transitionViews: (slug) ->
			# Make first letter uppercase
			viewName = slug[0].toUpperCase() + slug[1...]

			require ["view/#{ viewName }"], (View) =>
				newView = new View( el: "ol.todo-list.#{ slug }" ).render()

				if @currView? 
					@transitionOut( @currView ).then @transitionIn newView
				else
					@transitionIn newView

		transitionOut: (view) ->
			dfd = new $.Deferred()
			TweenLite.to( view.$el, 0.5, { alpha: 0, className: "hidden", onComplete: dfd.resolve } )
			
			return dfd.promise()
		
		transitionIn: (view) ->
			dfd = new $.Deferred()
			
			console.log "transitioning in ", view
			view.$el.removeClass "hidden"
			debugger unless view.$el.length
			TweenLite.fromTo( view.$el, 0.5, { alpha: 0 }, { alpha: 1, onComplete: dfd.resolve } )
			
			@currView = view
			
			return dfd.promise()

