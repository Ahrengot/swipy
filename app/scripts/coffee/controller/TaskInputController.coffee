define ["underscore", "view/TaskInput", "model/TagModel"], (_, TaskInputView, TagModel) ->
	class TaskInputController
		constructor: ->
			@view = new TaskInputView()
			Backbone.on( "create-task", @createTask, @ )
		parseTags: (str) ->
			result = str.match /#(.[^,#]+)/g

			if result
				# Trim white space and remove #-character from results
				tagNameList = ( $.trim tag.replace("#", "") for tag in result )
				tags = []

				for tagName in tagNameList
					tag = swipy.tags.getTagByName tagName
					if not tag then tag = new TagModel( title: tagName )
					tags.push tag

				return tags
			else
				return []

		parseTitle: (str) ->
			if str[0] is "#"
				return ""

			result = str.match(/[^#]+/)?[0]
			if result then result = $.trim result
			return result
		createTask: (str) ->
			return unless swipy.todos?

			tags = @parseTags str
			title = @parseTitle str
			order = 0
			animateIn = yes

			# If user is trying to add
			if !title
				msg = "You cannot create a todo by simply adding a tag. We need a title too. Titles should come before tags when you write out your task."
				Backbone.trigger( "throw-error", msg )
				return

			swipy.todos.bumpOrder()
			swipy.todos.create { title, tags, order, animateIn }

		destroy: ->
			Backbone.off( null, null, @ )