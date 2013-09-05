define ->
	class ViewController
		constructor: (opts) ->
			@setOpts opts
			@init()
			@navLinks = $('nav a')
		setOpts: (opts) ->
			defaultOptions = {
				$wrap: $('.pt-perspective')
				$pages: $('.pt-page')
				isAnimating: no
				endOldPage: no
				endNewPage: no
				animEndEventNames: {
					'WebkitAnimation' : 'webkitAnimationEnd',
					'OAnimation' : 'oAnimationEnd',
					'msAnimation' : 'MSAnimationEnd',
					'animation' : 'animationend'
				}
			}

			defaultOptions.numPages = defaultOptions.$pages.length
			defaultOptions.animEndEventName = defaultOptions.animEndEventNames[ Modernizr.prefixed( 'animation' ) ]

			# Merge default options with user specified ones
			@options = $.extend defaultOptions, opts
		init: ->
			# Save original classes for all pages
			@options.$pages.each -> $(@).data 'originalClassList', $(@).attr('class')

			# Set the first page as current page
			@options.$pages.eq(0).addClass 'pt-page-current'

			# Listen for navigation events
			$(document).on 'navigate/page', (e, slug) => @goto slug

			# Set up responsive height
			$(window).on "resize", @handleResize
			@handleResize()
		goto: (slug) ->
			return false if @options.isAnimating
			@options.isAnimating = yes

			# Store a reference to the current page (The one we're transitioning from)
			oldPage = @options.$pages.filter '.pt-page-current'

			# Store a reference to the next page (The one we're transitioning to)
			newPage = @options.$pages.filter -> $(@).attr('id') is slug

			@transitionPages oldPage, newPage
			@updateNavigation slug
		updateNavigation: (slug) =>
			@navLinks.each ->
				link = $(@)
				isCurrLink = if link.attr('href')[2...] is slug then yes else no
				link.toggleClass 'active', isCurrLink
		handleResize: (e) =>
			totalH = window.innerHeight 
			menubarH = $("body > article > header").height()

			$(".pt-perspective").height totalH - menubarH
		transitionPages: (oldPage, newPage) ->
			console.log "out: '#{oldPage.attr('id')}' /// in: '#{newPage.attr('id')}'"

			if @options.currView? then @options.currView.cleanUp()

			newPage.addClass 'pt-page-current'
			transitionOut = @getTransitionsForPage(oldPage.attr('id')).out
			transitionIn = @getTransitionsForPage(newPage.attr('id')).in

			# First, kick off transition out
			oldPage.addClass(transitionOut).one @options.animEndEventName, =>
				@options.endOldPage = yes
				if @options.endNewPage then @onEndAnimation(oldPage, newPage)

			# Then transition in for the new page
			newPage.addClass(transitionIn).one @options.animEndEventName, =>
				@options.endNewPage = yes
				if @options.endOldPage then @onEndAnimation(oldPage, newPage)

			@loadPageScripts( newPage.attr('id'), newPage )
		onEndAnimation: (oldPage, newPage) ->
			@options.endOldPage = no
			@options.endNewPage = no
			@resetPage(oldPage, newPage)
			@options.isAnimating = no
		resetPage: (oldPage, newPage) ->
			oldPage.attr('class', oldPage.data('originalClassList'))
			newPage.attr('class', newPage.data('originalClassList') + ' pt-page-current')
		getTransitionsForPage: (slug) ->
			transitions = { in: '', out: '' }

			switch slug
				when 'todo'
					transitions.in = "pt-page-flipInLeft"
					transitions.out = "pt-page-moveToLeft"
					break
				when 'schedule'
					transitions.in = "pt-page-moveFromRight"
					transitions.out = "pt-page-rotateRightSideFirst"
					break
				else
					transitions.in = "pt-page-moveFromRightFade"
					transitions.out = "pt-page-moveToLeftFade"

			return transitions
		loadPageScripts: (slug, pageEl) ->
			require ["view/#{slug}"], (View) =>
				@options.currView = new View( el: pageEl )