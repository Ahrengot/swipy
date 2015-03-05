define ["underscore"], (_) ->
	class KeyboardController
		constructor: ->
			@pushedDelegates = []
			@delegate = null
			@lockDelegate = null
			@isLocked = false
			_.bindAll( @, "keyDownHandling", "keyUpHandling", "lock", "unlock", "handleClick" )
			$(document).on('keydown', @keyDownHandling )
			$(document).on('keyup', @keyUpHandling )
			$('#scrollcont').on("click.keycontroller", @handleClick)
			 
		destroy: ->
			$(document).off('keydown', @keyDownHandling )
			$(document).off('keyup', @keyUpHandling )
			$('#scrollcont').off("click.keycontroller")
		keyDownHandling: (e) ->
			return if @isLocked or !@delegate?
			if _.isFunction(@delegate.keyDownHandling)
				@delegate.keyDownHandling(e)
		keyUpHandling: (e) ->
			return if @isLocked or !@delegate?
			if _.isFunction(@delegate.keyUpHandling)
				@delegate.keyUpHandling(e)
		handleClick: (e) ->
			if e.target.id is "scrollcont" and @delegate?
				if _.isFunction(@delegate.handleClick)
					@delegate.handleClick(e)

		setDelegate: ( delegate ) ->
			@delegate = delegate
			@pushedDelegates = []
		pushDelegate: ( delegate ) ->
			if @delegate?
				@pushedDelegates.push( @delegate )
			@delegate = delegate
		popDelegate: ->
			@delegate = @pushedDelegates.pop()
		lock: ->
			@isLocked = true
		unlock: ->
			@isLocked = false