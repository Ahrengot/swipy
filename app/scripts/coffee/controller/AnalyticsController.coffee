define ["underscore"], (_) ->
	isInt = (n) ->
		typeof n is 'number' and n % 1 is 0

	class AnalyticsController
		constructor: ->
			@init()
		init: ->
			analyticsKey = 'UA-41592802-7'
			@screens = []
			@customDimensions = {}
			@loadedIntercom = false

			@user = swipy.slackCollections.users.me()
			console.log "collection", @user
			if @user? and @user.id
				ga('create', analyticsKey, { 'userId' : @user.id } )
			else
				ga('create', analyticsKey, 'auto' )

			ga('send', 'pageview')
			@startIntercom()
			@updateIdentity()
		startIntercom: ->
			console.log "intercom" , @user
			return if !@user?
			userId = @user.id

			if @validateEmail @user.get("profile").email
				email = @user.get("profile").email
			
			window.Intercom('boot', {
				app_id: 'n15mxyvs'
				email: email
				user_id: userId
			})
			@loadedIntercom = true
		validateEmail: (email) ->
			regex = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
			regex.test email
		sendEvent: (category, action, label, value) ->
			platform = "Web"
			if @isMac?
				platform = "Mac"
			ga('set', {"dimension7": platform})
			ga('send', 'event', category, action, label, value)
		sendEventToIntercom: (eventName, metadata) ->
			Intercom('trackEvent', eventName, metadata )
		pushScreen: (screenName) ->
			ga('send', 'screenview', {
  				'screenName': screenName
			})
			@screens.push screenName
		popScreen: ->
			if @screens.length
				@screens.pop()
				lastScreen = _.last @screens
				return if !lastScreen?
				ga('send', 'screenview', {
  					'screenName': lastScreen
				})
		updateIdentity: ->
			gaSendIdentity = {}
			intercomIdentity = {}

			userLevel = "None"
			if @user?
				userLevel = "User"
				numberUserLevel = parseInt( @user.get( "userLevel" ), 10 )
				if numberUserLevel > 1
					userLevel = "Plus"

			currentUserLevel = @customDimensions['user_level']
			if currentUserLevel isnt userLevel
				gaSendIdentity["dimension1"] = userLevel
				intercomIdentity["user_level"] = userLevel


			theme = "Light"
			currentTheme = @customDimensions['active_theme']
			if currentTheme isnt theme
				gaSendIdentity['dimension3'] = theme
				intercomIdentity['active_theme'] = theme

			if swipy?
				recurringTasks = swipy.collections.todos.filter (m) -> m.get("repeatOption") isnt "never"
				recurringCount = recurringTasks.length
				currentRecurringCount = @customDimensions['recurring_tasks']
				if currentRecurringCount isnt recurringCount
					gaSendIdentity['dimension4'] = recurringCount
					intercomIdentity["recurring_tasks"] = recurringCount

				numberOfTags = swipy.collections.tags.length
				currentNumberOfTags = @customDimensions['number_of_tags']
				if currentNumberOfTags isnt numberOfTags
					gaSendIdentity['dimension5'] = numberOfTags
					intercomIdentity["number_of_tags"] = numberOfTags


			if _.size( gaSendIdentity ) > 0
				ga('set', gaSendIdentity)
				@sendEvent("Session", "Updated Identity")

			if _.size( intercomIdentity ) > 0
				Intercom("update", intercomIdentity)

