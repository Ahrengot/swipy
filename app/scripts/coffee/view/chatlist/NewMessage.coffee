define ["underscore"
		"text!templates/chatlist/new-message.html"
	], (_, Tmpl) ->
	Backbone.View.extend
		className: "chat-new-message"
		shiftDown: false
		offset: null
		initialize: ->
			self = @
			@placeholder = "Write new message"
			@template = _.template Tmpl, { variable: "data" }
			@render()
			_.bindAll(@, "pressedKey")
			
			textarea = @$el.find('textarea')
			@offset = textarea[0].offsetHeight - textarea[0].clientHeight
		events:
			"keyup textarea": "pressedKey"
			"keydown textarea": "keyDown"
			"click .attach-button-container": "clickedAttach"
			"change #file-input": "fileChanged"
		render: ->
			@$el.html @template({placeholder: @placeholder})
			@delegateEvents()
			return @
		setPlaceHolder: (placeholder) ->
			@placeholder = placeholder
			@$el.find('textarea').attr('placeholder',placeholder)
		autoExpand: () ->
			chatContainer = $('.chat-list-container')
			textarea = @$el.find('textarea')
			textareaHeight = textarea.height()
			textarea.css('height', 'auto').css 'height', textarea[0].scrollHeight + @offset
			chatContainer.css('height', 'calc(100% - ' + textareaHeight + 'px - 30px)')
			return
		pressedKey: (e) ->
			nowStamp = new Date().getTime()
			if !@lastSentTyping? or (@lastSentTyping + 3500) < nowStamp
				@lastSentTyping = new Date().getTime()
				if @addDelegate? and _.isFunction(@addDelegate.newMessageIsTyping)
					@addDelegate.newMessageIsTyping( @ )
			if e.keyCode is 16
				@shiftDown = false
			if e.keyCode is 13 && @shiftDown == false
				@sendMessage()
			@autoExpand()
			return false
		keyDown: (e) ->
			if e.keyCode is 16
				@shiftDown = true
		clickedAttach: ->
			$("#file-input").click()
		fileChanged: (e) ->
			file = $("#file-input")[0].files[0]
			if @addDelegate? and _.isFunction(@addDelegate.newFileSelected)
				@addDelegate.newFileSelected(@, file)
		setUploading: (isUploading) ->
			@$el.find(".attach-button-container").toggleClass("isUploading", isUploading)
		sendMessage: ->
			message = @$el.find("textarea").val()
			return if message.length is 0

			if @addDelegate? and _.isFunction(@addDelegate.newMessageSent)
				@addDelegate.newMessageSent( @, message )
			else
				throw new Error("NewMessage must have an addDelegate that implements newMessageSent")
			@$el.find("textarea").val ""
		remove: ->
			@destroy()
			@$el.empty()
		destroy: ->
			@undelegateEvents()