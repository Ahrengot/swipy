define ["underscore", "backbone", "text!templates/task-editor.html", "js/view/editor/TagEditor"], (_, Backbone, TaskEditorTmpl, TagEditor) ->
	Backbone.View.extend
		tagName: "article"
		className: "task-editor"
		events:
			"click .save": "save"
			"click .priority": "togglePriority"
			"click time": "reschedule"
			"click .repeat-picker a": "setRepeat"
			"blur .title input": "updateTitle"
			"blur .notes textarea": "updateNotes"
		initialize: ->
			$("body").addClass "edit-mode"
			@setTemplate()

			@render()
			@listenTo( @model, "change:schedule change:repeatOption change:priority", @render )
		setTemplate: ->
			@template = _.template TaskEditorTmpl
		killTagEditor: ->
			if @tagEditor?
				@tagEditor.cleanUp()
				@tagEditor.remove()
		createTagEditor: ->
			@tagEditor = new TagEditor { el: @$el.find(".icon-tag-bold"), model: @model }
		setStateClass: ->
			@$el.removeClass("active scheduled completed").addClass @model.getState()
		render: ->
			subtasks = @model.getOrderedSubtasks()
			jsonedSubtasks = [] 
			for task in subtasks
				jsonedTask = task.toJSON()
				jsonedSubtasks.push(jsonedTask)
			taskJSON = @model.toJSON()
			taskJSON.subtasks = jsonedSubtasks
			@$el.html @template taskJSON

			@setStateClass()
			@killTagEditor()
			@createTagEditor()
			return @el
		save: ->
			swipy.router.back()
		reschedule: ->
			Backbone.trigger( "show-scheduler", [@model] )
		transitionInComplete: ->
		togglePriority: ->
			@model.togglePriority()
		setRepeat: (e) ->
			@model.setRepeatOption $(e.currentTarget).data "option"
		updateTitle: ->
			@model.updateTitle @getTitle()
		updateNotes: ->
			@model.updateNotes @getNotes()
		getTitle: ->
			@$el.find( ".title input" ).val()
		getNotes: ->
			@$el.find( ".notes textarea" ).val()
		remove: ->
			$("body").removeClass "edit-mode"
			@undelegateEvents()
			@stopListening()
			@$el.remove()
