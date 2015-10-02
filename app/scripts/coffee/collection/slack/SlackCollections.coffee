define [
	"underscore"
	"backbone"
	"js/collection/slack/UserCollection"
	"js/collection/slack/BotCollection"
	"js/collection/slack/TeamCollection"
	"js/collection/slack/ChannelCollection"
	"collectionSubset"
	], (_, Backbone, UserCollection, BotCollection, TeamCollection, ChannelCollection) ->
	class Collections
		constructor: ->
			
			@users = new UserCollection()
			@bots = new BotCollection()
			@teams = new TeamCollection()
			@channels = new ChannelCollection()
			@channels.localStorage = new Backbone.LocalStorage("ChannelCollection")

			@all = [@teams, @users, @bots, @channels]
		fetchAll: ->
			for collection in @all
				collection.fetch()