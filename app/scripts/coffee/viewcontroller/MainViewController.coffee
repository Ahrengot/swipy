define [
	"underscore"
	"gsap"
	"js/viewcontroller/ChannelViewController"
	"js/viewcontroller/MyTasksViewController"
	"js/viewcontroller/SearchViewController"
	"js/viewcontroller/AppViewController"
	], (_, TweenLite, ChannelViewController, MyTasksViewController, SearchViewController, AppViewController) ->
	class MainViewController
		constructor: (opts) ->
			@init()
		init: ->
			# Listen for navigation events
			Backbone.on( 'open/viewcontroller', @openVC, @)
		openVC: (viewcontroller, options) ->
			activeChannels = swipy.slackCollections.channels.where({"is_active_channel": true})
			for channel in activeChannels
				channel.set("is_active_channel", false)
				
			if @currentControllerName is viewcontroller
				@currentViewController.open( viewcontroller, options )
			else
				@loadViewController(viewcontroller).then (ViewController) =>
					@currentViewController?.destroy()
					viewController = new ViewController()
					viewController.open( viewcontroller, options )
					@currentControllerName = viewcontroller
					@currentViewController = viewController
			swipy.activeId = options.id if options?.id
			swipy.sync?.shortBouncedSync()
			activeMenuDet = viewcontroller
			if viewcontroller is "im"
				activeMenuDet = "member"
			activeMenu = "sidebar-"+activeMenuDet + "-" + options.id if options?.id
			if viewcontroller is "tasks"
				activeMenu = "sidebar-tasks-now"
			Backbone.trigger("set-active-menu", activeMenu)
		loadViewController: (viewcontroller) ->
			dfd = new $.Deferred()
			if viewcontroller is "im" then dfd.resolve ChannelViewController
			else if viewcontroller is "channel" then dfd.resolve ChannelViewController
			else if viewcontroller is "group" then dfd.resolve ChannelViewController
			else if viewcontroller is "search" then dfd.resolve SearchViewController
			else if viewcontroller is "app" then dfd.resolve AppViewController
			else dfd.resolve MyTasksViewController
			return dfd.promise()
		destroy: ->
			@currView?.remove()
			Backbone.off( null, null, @ )