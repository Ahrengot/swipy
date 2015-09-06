define ["underscore", "js/collection/slack/MessageCollection"], (_, MessageCollection) ->
	Backbone.Model.extend
		className: "Channel"
		excludeFromJSON: [ "messages" ]
		initialize: ->
			messageCollection = new MessageCollection()
			messageCollection.localStorage = new Backbone.LocalStorage("MessageCollection-" + @id )
			messageCollection.fetch()
			@set("messages", messageCollection)
		getMessages: ->
			messages = @get("messages")
			loop
				break if messages.length < 101
				messages.shift()
			messages
		getName: ->
			return @get("name") if @get("name")
			if @get("user") and swipy.slackCollections and swipy.slackCollections.users.get(@get("user"))
				return swipy.slackCollections.users.get(@get("user")).get("name")
		getApiType: ->
			apiType = "channels"
			if @get("is_im")
				apiType = "im"
			if @get("is_group")
				apiType = "groups"
			apiType
		fetchMessages: (collection) ->
			options = {channel: @id, count: 100 }
			
			collection = @get("messages")
			collection.fetch()
			if collection.models.length
				lastModel = collection.at(collection.models.length-1)
				options.oldest = lastModel.get("ts")
			swipy.slackSync.apiRequest(@getApiType() + ".history",options, 
				(res, error) =>
					if res and res.ok
						@hasFetched = true
						for message in res.messages
							@addMessage(message)
			)
		addMessage: (message, increment) ->
			collection = @get("messages")
			identifier = message.ts
			identifier = message.deleted_ts if message.deleted_ts?
			identifier = message.message.ts if message.message? and message.message.ts?
			model = collection.get(identifier)
			if !model
				if increment and message.user isnt swipy.slackCollections.users.me().id
					@save("unread_count_display", @get("unread_count_display")+1)
					if @get("is_im") and @getName() is "slackbot"
						console.log message
						swipy.sync.shortBouncedSync()
						console.log "bounced sync from sofi"
					if @get("is_im") and (!swipy.isWindowOpened or @getName() isnt swipy.activeId)
						if !swipy.bridge.bridge # OR you were mentioned in the task /TODO:
							Backbone.trigger("play-new-message")
						else
							text = "You received 1 new message"
							text = message.text if message.text
							title = "[Swipes] " + @getName() 
							swipy.bridge.callHandler("notify",{title: title, message: text})
				return if(!@hasFetched? or !@hasFetched)
				newMessage = collection.create( message )
			else
				console.log "editing", message
				if(message.deleted_ts)
					collection.remove(model)
				else
					if message.message
						model.save(message.message)
					else
						model.save(message)
		markAsRead: ->
			collection = @get("messages")
			options = {channel: @id }
			if collection.models.length
				lastModel = collection.at(collection.models.length-1)
				options.ts = lastModel.get("ts")
			swipy.slackSync.apiRequest(@getApiType() + ".mark",options, 
				(res, error) =>
					if res and res.ok
						console.log "marked"
					else
						console.log error
			)