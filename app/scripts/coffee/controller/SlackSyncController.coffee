###
	Everytime on save call saveToSync with objects

	saveToSync:
	sync:attributes:forIdentifier
	sync

###

define ["underscore", "jquery", "js/utility/Utility"], (_, $, Utility) ->
	class SlackSyncController
		constructor: ->
			@token = localStorage.getItem("slack-token")
			@baseURL = "https://slack.com/api/"
			@util = new Utility()
			@currentIdCount = 0
			@sentMessages = {}
			_.bindAll(@, "onSocketMessage", "onSocketClose", "onOpenedWindow")
			Backbone.on("opened-window", @onOpenedWindow, @)
		start: ->
			return if @isStarting?
			@isStarting = true
			@apiRequest("rtm.start", {simple_latest: false}, (data, error) =>
				@isStarting = null
				if data and data.ok
					@handleSelf(data.self) if data.self
					@handleUsers(data.users) if data.users
					@handleBots(data.bots) if data.bots
					@_channelsById = {}
					@handleChannels(data.channels) if data.channels
					@handleChannels(data.groups) if data.groups
					@handleChannels(data.ims) if data.ims
					@clearDeletedChannels()
					@openWebSocket(data.url)
					localStorage.setItem("slackLastConnected", new Date())
					Backbone.trigger('slack-first-connected')
					
			)
		handleSelf:(self) ->
			collection = swipy.slackCollections.users
			model = collection.get(self.id)
			model = collection.create(self) if !model
			model.set("me",true)
			model.save(self)
		handleUsers:(users) ->
			for user in users
				collection = swipy.slackCollections.users
				model = collection.get(user.id)
				model = collection.create(user) if !model
				model.save(user)
		handleBots:(bots) ->
			for bot in bots
				collection = swipy.slackCollections.bots
				model = collection.get(bot.id)
				model = collection.create(bot) if !model
				model.save(bot)
		handleChannels: (channels) ->
			
			for channel in channels
				@_channelsById[channel.id] = channel
				collection = swipy.slackCollections.channels

				model = collection.get(channel.id)
				model = collection.create(channel) if !model
				model.save(channel)
		clearDeletedChannels: ->
			channelsToDelete = []
			for channel in swipy.slackCollections.channels.models
				if !@_channelsById[channel.id]
					channelsToDelete.push(channel)
			for channel in channelsToDelete
				swipy.slackCollections.channels.remove(channel)
				channel.localStorage = swipy.slackCollections.channels.localStorage
				channel.destroy()
		handleReceivedMessage: (message, incrementUnread) ->
			channel = swipy.slackCollections.channels.get(message.channel)
			channel.addMessage(message, incrementUnread)

		openWebSocket: (url) ->
			@webSocket = new WebSocket(url)
			@webSocket.onopen = @onSocketOpen
			@webSocket.onclose = @onSocketClose
			@webSocket.onmessage = @onSocketMessage
			@webSocket.onerror = @onSocketError


		onSocketOpen: (evt) ->
		onSocketClose: (evt) ->
			@webSocket = null if @webSocket?
			@start()
		onSocketMessage: (evt) ->
			if evt and evt.data
				
				data = JSON.parse(evt.data)
				# Reply to sent data over websocket
				if data.ok and data.reply_to
					sentMessage = @sentMessages[""+data.reply_to]
					return if !sentMessage?
					if sentMessage.type is "message"
						sentMessage.ts = data.ts
						delete sentMessage["id"]
						@handleReceivedMessage(sentMessage)
						delete @sentMessages[""+data.reply_to]
					return
				if data.type is "presence_change"
					user = swipy.slackCollections.users.get(data.user)
					user.save("presence", data.presence)
				else if data.type is "message"
					@handleReceivedMessage(data, true)
				else if data.type is "channel_marked" or data.type is "im_marked" or data.type is "group_marked"
					channel = swipy.slackCollections.channels.get(data.channel)
					channel.save("last_read", data.ts)
					channel.save("unread_count_display", data.unread_count_display)
				else if data.type is "channel_joined"
					channel = swipy.slackCollections.channels.get(data.channel.id)
					channel.save(data.channel)
				else if data.type is "channel_left"
					channel = swipy.slackCollections.channels.get(data.channel)
					channel.save("is_member", false)
				else if data.type is "im_close" or data.type is "group_close"
					channel = swipy.slackCollections.channels.get(data.channel)
					channel.save("is_open", false)
				else if data.type is "im_open" or data.type is "group_open"
					channel = swipy.slackCollections.channels.get(data.channel)
					channel.save("is_open", true)

			console.log evt.data
		onSocketError: (evt) ->
			console.log evt
		doSocketSend: (message, dontSave) ->
			if _.isObject(message)
				message.id = ++@currentIdCount
				@sentMessages[""+message.id] = message if !dontSave
				message = JSON.stringify(message)
			@webSocket?.send(message)
		onOpenedWindow: ->
			if !@webSocket?
				@start()
		sendMessage:(message, channel, callback) ->
			self = @
			options = {text: message, channel: channel, as_user: true, link_names: 1}
			@apiRequest("chat.postMessage", options, (res, error) ->
				if res and res.ok
					slackbotChannelId = swipy.slackCollections.channels.slackbot().id
					type = self.util.slackTypeForId(channel)
					if type is "DM" and channel is slackbotChannelId
						type = "Slackbot"
					console.log "Sent Message", type
					swipy.analytics.logEvent("[Engagement] Sent Message", {"Type": type})
				callback?(res, error)
			)
		uploadFile: (channels, file, callback, initialComment) ->
			formData = new FormData()
			formData.append("token", @token)
			formData.append("channels", channels)
			formData.append("filename", file.name)
			formData.append("file", file);
			console.log "upload called"
			@apiRequest("files.upload", {}, (res, error) ->
				console.log "response", res, error
				callback?(res,error)
			, formData)
		sendMessageAsSlackbot: (message, channel, callback) ->
			options = {text: message, channel: channel, as_user: false, link_names: 1, username: "slackbot", icon_url: "http://team.swipesapp.com/styles/img/slackbot72.png" }
			@apiRequest("chat.postMessage", options, (res, error) ->
				callback?(res, error)
			)
		sendMessageAsSofi: (message, channel, callback, attachments) ->
			options = {text: message, channel: channel, as_user: false, link_names: 1, username: "s.o.f.i.", icon_url: "http://team.swipesapp.com/styles/img/sofi48.jpg"}
			options.attachments = attachments if attachments
			@apiRequest("chat.postMessage", options, (res, error) ->
				callback?(res, error)
			)
		apiRequest: (command, options, callback, formData) ->
			url = @baseURL + command
			options = {} if !options? or !_.isObject(options)
			options.token = @token

			settings = 
				url : url
				type : 'POST'
				success : ( data ) ->
					console.log "slack success", data
					if data and data.ok
						callback?(data);
					else
						@util.sendError( data, "Sync Error" )
						callback?(false, data);
				error : ( error ) ->
					console.log "slack error", error
					@util.sendError( error, "Server Error")
					callback?(false, error)
				crossDomain : true
				context: @
				data : options
				processData : true
			if formData
				settings.data = formData
				settings.processData = false
				settings.contentType = false
			#console.log serData
			$.ajax( settings )