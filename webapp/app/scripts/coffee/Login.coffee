### Analytics Controller ###

isInt = (n) ->
		typeof n is 'number' and n % 1 is 0;

class AnalyticsController
	constructor: ->
		@init()
	init: ->
		@customDimensions = ["Standard"]
		@screens = []
		@createSession()
	createSession: ->
		@session = LocalyticsSession @getKey()
		@session.open()
		@session.upload()
		@setUser Parse.User.current()
	getKey: ->
		key = if liveEnvironment then "0c159f237171213e5206f21-6bd270e2-076d-11e3-11ec-004a77f8b47f" else "f2f927e0eafc7d3c36835fe-c0a84d84-18d8-11e3-3b24-00a426b17dd8" 
		# Figure out which one to use here...
		return key
	hasDimension: (dimension) ->
		if isInt( dimension ) and @customDimensions.length < dimension >= 0
			return true
		else return false
	customDimension: (dimension) ->
		if @hasDimension dimension
			return @customDimensions[dimension]
		else
			return false
	setCustomDimension: (dimension, value) ->
		if @hasDimension dimension
			@customDimensions[dimension] = value
	tagEvent: (ev, options) ->
		@session.tagEvent( ev, options, @customDimensions )
	tagScreen: (screenName) ->
		@session.tagScreen screenName
	pushScreen: (screenName) ->
		@session.tagScreen screenName
		@screens.push screenName
	popScreen: ->
		if @screens.length
			@screens.pop()
			@session.tagScreen _.last @screens
	setUser: (user) ->
		cdUserLevel = switch parseInt( user.get( "userLevel" ), 10 )
			when 1 then "Trial"
			when 2 then "Plus Monthly"
			when 3 then "Plus Yearly"
			else "Standard"

		# Update custom dimensions if not standard user
		if cdUserLevel isnt @customDimensions[0]
			@setCustomDimension( 0, cdUserLevel )

		# If user email changed, update the one used by the session
		if user.get( "email" ) isnt @session.customerEmail
			@session.setCustomerEmail user.get "email"

		# If user id changed, update the one used by the session
		if user.id? isnt @session.customerId
			@session.setCustomerId user.id

### /Analytics Controller ###

LoginView = Backbone.View.extend
	el: "#login"
	events:
		"submit form": "handleSubmitForm"
		"click #facebook-login": "facebookLogin"
		"click .reset-password": "resetPassword"
	facebookLogin: (e) -> @doAction "facebookLogin"
	setBusyState: ->
		$("body").addClass "busy"
		@$el.find("input[type=submit]").val "please wait ..."
	removeBusyState: ->
		$("body").removeClass "busy"
		@$el.find("input[type=submit]").val "Continue"
	handleSubmitForm: (e) ->
		e.preventDefault()
		@doAction "login"
	doAction: (action) ->
		if $("body").hasClass "busy" then return console.warn "Can't do #{action} right now — I'm busy ..."
		@setBusyState()

		switch action
			when "login"
				email = @$el.find( "#email" ).val().toLowerCase()
				password = @$el.find( "#password" ).val()
				return @removeBusyState() unless @validateFields( email, password )

				Parse.User.logIn( email, password, {
					success: => @handleUserLoginSuccess()
					error: (user, error) => @handleError( user, error, { email, password } )
				})
			when "register"
				console.log "Registering a new user"
				email = @$el.find( "#email" ).val().toLowerCase()
				password = @$el.find( "#password" ).val()
				return @removeBusyState() unless @validateFields( email, password )

				@createUser( email, password ).signUp()
				.done( => @handleUserLoginSuccess() )
				.fail (user, error) => @handleError( user, error )
			when "facebookLogin"
				Parse.FacebookUtils.logIn( null, {
					success: (success) => @handleFacebookLoginSuccess success
					error: (user, error) => @handleError( user, error )
				})
	handleFacebookLoginSuccess: (user) ->
		if user.isNew
			@wasSignup = yes
		if not user.existed
			signup = yes # Will be true if it was a signup
		unless user.get "email" then FB.api "/me", (response) ->
			if response.gender
				user.set( "gender", response.gender )
			if response.email
				user.set( "email", response.email )
				user.set( "username", response.email )
				user.save()
			@handleUserLoginSuccess()
		else
			@handleUserLoginSuccess()
	handleAnalyticsForLogin: ->
		analytics = new AnalyticsController()
		user = Parse.User.current()

		if @wasSignup
			analytics.tagEvent("Signed Up")
		else
			analytics.tagEvent("Logged In")
	handleUserLoginSuccess: ->
		@handleAnalyticsForLogin()
		user = Parse.User.current()
		level = user.get "userLevel"

		if level and parseInt( level ) >= 1
			location.pathname = "/"
		else
			@removeBusyState()
			$("body").addClass( "swipes-plus-required" ).one "click", ".plus-required .cancel", ->
				$("body").removeClass "swipes-plus-required"
	resetPassword: ->
		email = prompt "Which email did you register with?"
		if email then Parse.User.requestPasswordReset( email, {
			success: -> alert "An email was sent to '#{email}' with instructions on resetting your password"
			error: (error) -> alert "Error: #{ error.message }"
		})
	createUser: (email, password) ->
		user = new Parse.User()
		user.set( "username", email )
		user.set( "password", password )
		user.set( "email", email )
		return user
	validateFields: (email, password) ->
		if not email
			alert "Please fill in your e-mail address"
			return no

		if not password
			alert "Please fill in your password"
			return no

		if email.length is 0 or password.length is 0
			alert "Please fill out both fields"
			return no
		if not @validateEmail email
			alert "Please use a real email address"
			return no
		# Everything passed
		return yes
	validateEmail: (email) ->
		regex = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
		return regex.test email
	handleError: (user, error, triedLoginWithCredentials = no) ->
		if triedLoginWithCredentials
			checkEmailOpts =
				success: (result, error) =>
					if not result
						if confirm "You're about to create a new user with the e-mail #{ triedLoginWithCredentials.email }. Do you want to continue?"
							@removeBusyState()
							return @doAction "register"
						else
							return @removeBusyState()
					else
						@removeBusyState()
						return alert "Wrong password."
				error: =>
					alert "Something went wrong. Please try again."
					@removeBusyState()

			Parse.Cloud.run( "checkEmail" , { email:triedLoginWithCredentials.email }, checkEmailOpts );

		else
			@removeBusyState()
			if error and error.code then return @showError error
			else alert "something went wrong. Please try again."
	showError: (error) ->
		switch error.code
			when Parse.Error.USERNAME_TAKEN, Parse.Error.EMAIL_NOT_FOUND then alert "The password was wrong"
			when Parse.Error.INVALID_EMAIL_ADDRESS then alert "The provided email is invalid. Please check it, and try again"
			when Parse.Error.TIMEOUT then alert "The connection timed out. Please try again."
			when Parse.Error.USERNAME_TAKEN then alert "The email/username was already taken"
			when 202 then alert "The email is already in use, please login instead"
			when 101 then alert "Wrong email or password"
			else alert "something went wrong. Please try again."

# Log into services
appId = if liveEnvironment then "nf9lMphPOh3jZivxqQaMAg6YLtzlfvRjExUEKST3" else "0qD3LLZIOwLOPRwbwLia9GJXTEUnEsSlBCufqDvr"
jsId = if liveEnvironment then "SEwaoJk0yUzW2DG8GgYwuqbeuBeGg51D1mTUlByg" else "TcteeVBhtJEERxRtaavJtFznsXrh84WvOlE6hMag"
Parse.initialize(appId, jsId);

# Handle Fabebook Login
window.fbAsyncInit = ->
	fbKey = if liveEnvironment then '531435630236702' else "312199845588337"
	Parse.FacebookUtils.init
		appId: fbKey	        	                # App ID from the app dashboard
		channelUrl : 'http://swipesapp.com/channel.php' 		# Channel file for x-domain comms
		status: no                		                 		# Check Facebook Login status
		cookie: yes                           		      		# enable cookies to allow Parse to access the session
		xfbml: yes                                				# Look for social plugins on the page

# Load Fabebook JS SDK
do ->
	if document.getElementById 'facebook-jssdk' then return

	firstScriptElement = document.getElementsByTagName( 'script' )[0]
	facebookJS = document.createElement 'script'

	facebookJS.id = 'facebook-jssdk'
	facebookJS.src = '//connect.facebook.net/en_US/all.js'

	firstScriptElement.parentNode.insertBefore( facebookJS, firstScriptElement )

# Finally, instantiate a new SwipesLogin
login = new LoginView()