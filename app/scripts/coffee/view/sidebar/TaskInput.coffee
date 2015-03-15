define ["underscore", "text!templates/sidemenu/sidemenu-add.html"], (_, AddTmpl) ->
	Backbone.View.extend
		className: "add-sidemenu"
		events:
			"submit": "triggerAddTask"
			"keyup textarea": "saveText"
			"focus textarea": "focusTextArea"
			"click .priority": "togglePriority"
		initialize: ->
			@oldTaskText = ""
			@oldTaskText = localStorage.getItem("addText") if localStorage.getItem("addText")
			@template = _.template AddTmpl
			@render()
			_.bindAll(@, "keyUpHandling", "focusTextArea")
			
		render: ->
			@$el.html @template {oldTaskText: @oldTaskText}
		togglePriority: (e) ->
			$('.add-new').toggleClass("is-priority")
		saveText: (e) ->
			localStorage.setItem("addText",$(e.currentTarget).val())
		focusTextArea: (e) ->
			val = $(e.currentTarget).val()
			$(e.currentTarget).val("").val(val)
		keyDownHandling: (e) ->
			if e.keyCode is 13
				e.preventDefault()
		keyUpHandling: (e) ->
			if e.keyCode is 13
				@triggerAddTask(e)
				localStorage.setItem("addText", "")
			if e.keyCode is 27
				swipy.sidebar.popView()
		triggerAddTask: (e) ->
			e.preventDefault()
			return if @$el.find(".add-task-field").val() is ""
			console.log @$el.find(".add-task-field").val()
			Backbone.trigger( "create-task", @$el.find(".add-task-field").val() )
			@$el.find(".add-task-field").val ""
		destroy: ->
			@remove()
		remove: ->
			@$el.remove()