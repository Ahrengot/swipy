LoginView = Parse.View.extend
	el: "#login"
	events:
		"submit form": "doAction"
		"click #facebook-login": "facebookLogin"
	facebookLogin: (e) -> @doAction( e, "facebookLogin" )
	setBusyState: ->
		$("body").addClass "busy"
		@$el.find("input[type=submit]").val "please wait ..."
	removeBusyState: ->
		$("body").removeClass "busy"
		@$el.find("input[type=submit]").val "Continue"
	doAction: (e, action = "login") ->
		e.preventDefault()

		if $("body").hasClass "busy" then return console.warn "Can't do #{action} right now — I'm busy ..."
		@setBusyState()

		switch action
			when "login"
				email = @$el.find( "#email" ).val()
				password = @$el.find( "#password" ).val()
				return @removeBusyState() unless @validateFields( email, password )

				Parse.User.logIn( email, password, {
					success: ->
						location.pathname = "/"
					error: (user, error) =>
						@handleError( user, error, yes )
				})
			when "register"
				email = @$el.find( "#email" ).val()
				password = @$el.find( "#password" ).val()
				return @removeBusyState() unless @validateFields( email, password )

				@createUser( email, password ).signUp( null, {
					success: ->
						location.pathname = "/"
					error: (user, error) =>
						@handleError( user, error )
				})
			when "facebookLogin"
				Parse.FacebookUtils.logIn( null, {
					success: @handleFacebookLoginSuccess
					error: (user, error) =>
						@handleError( user, error )
				})
	handleFacebookLoginSuccess: (user) ->
		if not user.existed
			signup = yes # Will be true if it was a signup
		unless user.get "email" then FB.api "/me", (response) ->
			if response.gender
				user.set( "gender", response.gender )
			if response.email
				user.set( "email", response.email )
				user.set( "username", response.email )
				user.save()
			location.href = "/"
		else
			location.href = "/"
	createUser: (email, password) ->
		user = new Parse.user()
		user.set( "username", email )
		user.set( "password", password )
		user.set( "email", email )
		return user
	validateFields: (email, password) ->
		if not email
			alert "Please fill in you e-mail address"
			return no

		if not password
			alert "Please fill in you password"
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
	handleError: (user, error, triedLogin = no) ->
		if triedLogin
			console.log "Tried logging in and failed. Will register user instead."
			# Figure out if the error was that the user didn't exist. If true, do the login.

		@removeBusyState()

		if error and error.code then switch error.code
			when 202 then alert "The email is already in use, please login instead"
			when 101 then alert "Wrong email or password"
			else alert "something went wrong. Please try again."

# Log into services
Parse.initialize( "0qD3LLZIOwLOPRwbwLia9GJXTEUnEsSlBCufqDvr", "TcteeVBhtJEERxRtaavJtFznsXrh84WvOlE6hMag" )

# Handle Fabebook Login
window.fbAsyncInit = ->
	Parse.FacebookUtils.init
		appId: '312199845588337'	        	                # App ID from the app dashboard
		channelUrl : 'http://test.swipesapp.com/channel.html' 	# Channel file for x-domain comms
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