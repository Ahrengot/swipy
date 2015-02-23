define ["js/utility/Utility"], ( Utility ) ->
	Backbone.Model.extend
		className: "BaseModel"
		defaultAttributes: [ "objectId", "tempId", "deleted" ]
		sync: -> true
		constructor: ( attributes ) ->
			if attributes && !attributes.objectId
				util = new Utility()
				attributes.tempId = util.generateId 12
				attributes.objectId = attributes.tempId
				attributes.needSaveToServer = true
			Backbone.Model.apply @, arguments
		deleteObj: ->
			@save "deleted", yes, { silent:true, sync: true }
		handleForSync: ( key, val, options ) ->
			attrs = {}
			if key is null or typeof key is 'object'
				attrs = key
				options = val
			else 
				attrs[ key ] = val
			if options and options.sync
				swipy.sync.handleModelForSync( @, attrs )
				return true
			return false
		doSync: (create) ->
			command = "update"
			if @isNew() # or create? and create
				command = "create"
			if @get "deleted"
				command = "delete"
			Backbone.sync(command, @)
			if command is "delete"
				if @className is "ToDo"
					swipy.todos.remove(@)
				else if @className is "Tag"
					swipy.tags.remove(@)
		toServerJSON: ( attrList ) ->
			if !@attrWhitelist
				return console.log "please add attrWhiteList in model for sync support"
			attrList = @attrWhitelist.concat( @defaultAttributes ) if !attrList
			json = _.pick( @attributes, attrList )
			# Prepare all the dates to proper format for server
			for key, value of json
				if _.isDate value
					json[ key ] = { "__type": "Date", "iso": value }
			json

		updateFromServerObj: ( obj ) ->
			if @get("needSaveToServer")
				@set("needSaveToServer", false, {localSync: true})
			@set "deleted", obj.deleted, {localSync: true} if obj.deleted