define [
	"underscore"
	"gsap"
	], (_, TweenLite) ->
	Backbone.View.extend
		className: "app-view-controller"
		initialize: ->
		render: ->

		open: (type, options) ->
			swipy.rightSidebarVC.hideSidemenu()
			@$el.html "Loading App"
			$("#main").html(@$el)
			
			# Set the file identifier for loading files as text (manual parse)
			apiUrl = swipy.api.getAPIURL()
			$iframe = $("<iframe src=\"" + apiUrl + "apps.load?appId=" + options.id + "&token=" + localStorage.getItem("swipy-token") + "\" class=\"app-frame-class\" frameborder=\"0\">")


			@$el.html ($iframe)
			doc = $iframe[0].contentWindow
			swipy.api.setListener(doc, apiUrl)
			swipy.api.setDelegate(swipy.swipesSync)
			$iframe.on("load", (e, b) =>
				
				$(document).mousedown(
					(e) =>
						$iframe.blur() if @isInIframe
				)
				$iframe.mouseenter(
					(e) =>
						@isInIframe = true
				)
				$iframe.mouseleave(
					(e) =>
						@isInIframe = false		
				)
			)
			
		receivedMessageFromApp: (message, test) ->
			window.receivedMessageFromApp = message
			
			data = JSON.parse(message.data)
			console.log "message from app", data
		destroy: ->
			console.log("destroying app view controller")
###
	A fake Inbox app

define [
	"underscore"
	"text!templates/apps/inbox-app.html"
	], (_, Tmpl) ->
	Backbone.View.extend
		className: "inbox-app-extension"
		initialize: ->
			@template = _.template Tmpl, {variable: "data" }
			@render()
		render: ->
			@$el.html @template()
			return @
###