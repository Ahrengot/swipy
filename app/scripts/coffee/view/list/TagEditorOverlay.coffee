define ["underscore", "js/view/Overlay", "js/model/TagModel", "text!templates/tags-editor-overlay.html"], (_, Overlay, TagModel, TagsEditorOverlayTmpl) ->
	Overlay.extend
		className: 'overlay tags-editor'
		events:
			"click .overlay-bg": "destroy"
			"click .save": "destroy"
			"click .rounded-tags li:not(.tag-input)": "toggleTag"
			"submit form": "createTag"
		initialize: ->
			if arguments[ 0 ]
				@options = arguments[ 0 ]
			Overlay::initialize.apply( @, arguments )
			@showClassName = "tags-editor-open"
			@hideClassName = "hide-tags-editor"
			@render()

		bindEvents: ->
			_.bindAll( @, "handleResize" )
			$(window).on( "resize", @handleResize )
		setTemplate: ->
			@template = _.template TagsEditorOverlayTmpl
		getTagsAppliedToAll: ->
			# First check that all currently selected tasks have tags applied
			tagLists = _.invoke( @options.models, "get", "tags" )
			return [] if _.contains( tagLists, null )

			# Convert tag lists from a list of models to a list of strings
			stringLists = []
			for modelList in tagLists
				stringLists.push _.invoke( modelList, "get", "title" )

			# Then, go over each task and find out if there are any tags shared by all of them
			return _.intersection stringLists...
		getTagFromName: (tagName) ->
			# First see if tag exists
			tag = swipy.tags.findWhere { title: tagName }
			if tag then return tag
		render: () ->
			@$el.html @template( { allTags: swipy.tags.toJSON(), tagsAppliedToAll: @getTagsAppliedToAll() } )
			if not $("body").find(".overlay.tags-editor").length
				$("body").append @$el

			@show()
			@handleResize()
			@$el.find( ".tag-input input" ).focus()
			return @
		afterShow: ->
			swipy.shortcuts.lock()
		afterHide: ->
			Backbone.trigger "redraw-sortable-list"
			swipy.shortcuts.unlock()
		toggleTag: (e) ->
			target = $ e.currentTarget
			remove = target.hasClass "selected"
			tag = target.text()

			if remove
				@removeTagFromModels tag
				swipy.analytics.sendEvent( "Tags", "Unassigned", "Select Tasks", 1)
				swipy.analytics.sendEventToIntercom( "Unassign Tags", { "From": "Select Tasks", "Number of Tasks": @options.models.length, "Number of Tags": 1 })
			else 
				@addTagToModels( tag, no )
				swipy.analytics.sendEvent( "Tags", "Assigned", "Select Tasks", 1)
				swipy.analytics.sendEventToIntercom( "Assign Tags", { "From": "Select Tasks", "Number of Tasks": @options.models.length, "Number of Tags": 1 })
		createTag: (e) ->
			e.preventDefault()
			tagName = @$el.find("form.add-tag input").val()
			return if tagName is ""

			@addTagToModels tagName
		addTagToModels: (tagName, addToCollection = yes) ->
			if addToCollection and _.contains( swipy.tags.pluck( "title" ), tagName )
				return alert "That tag already exists"
			else
				tag = @getTagFromName tagName
				if not tag and addToCollection 
					tag = swipy.tags.create { title: tagName }
					swipy.analytics.sendEvent("Tags", "Added", "Select Tasks", tagName.length)
					swipy.analytics.sendEventToIntercom( "Added Tag", { "From": "Select Tasks", "Length": tagName.length })
					tag.save({}, {sync:true})
				@addTagToModel( tag, model ) for model in @options.models

				@render()
		modelHasTag: (model, tag) ->
			tagName = tag.get "title"
			return !!_.filter( model.get( "tags" ), (t) -> t.get( "title" ) is tagName ).length
		addTagToModel: (tag, model) ->
			if model.has "tags"
				if @modelHasTag( model, tag ) then return
				tags = model.get "tags"
				tags.push tag
				model.updateTags tags
			else
				model.updateTags [ tag ]
		removeTagFromModels: (tagName) ->
			for model in @options.models
				tags = model.get "tags"
				newTags = _.reject( tags, (tagModel) -> tagModel.get( "title" ) is tagName )
				model.updateTags newTags

			@render()
		handleResize: ->
			return unless @shown

			content = @$el.find ".overlay-content"
			offset = ( window.innerHeight / 2 ) - ( content.height() / 2 )
			content.css( "margin-top", offset )
		cleanUp: ->
			$(window).off("resize", @handleResize)

			# Same as super() in real OOP programming
			Overlay::cleanUp.apply( @, arguments )

