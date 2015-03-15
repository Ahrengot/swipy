define ["text!templates/sidemenu/settings/sidemenu-settings-tweaks.html"], (Tmpl) ->
	Backbone.View.extend
		className: "tweaks"
		events:
			"click .group > a": "toggleSelection"
		initialize: ->
			@setTemplate()
			@render()
		setTemplate: ->
			@template = _.template Tmpl
		render: ->
			settings = swipy.settings.model.toJSON()
			@$el.html @template { settings: settings }
		toggleSelection: (e) ->
			target = $(e.currentTarget)
			isOn = target.hasClass("on")
			if target.hasClass "add-to-bottom"
				setting = "SettingAddToBottom"
			if target.hasClass "calendar-start-monday"
				setting = "SettingCalendarStartMonday"
			if target.hasClass "twenty-four-clock"
				setting = "Setting24HourClock"
			swipy.settings.set setting, !isOn
			@render()
			false
		destroy: ->
			@cleanUp()
		cleanUp: ->
			