define ["underscore", "text!templates/calendar.html", "js/utility/TimeUtility", "momentjs", "clndr"], (_, CalendarTmpl, TimeUtility) ->
	Backbone.View.extend
		tagName: "div"
		className: "calendar-wrap"
		initialize: ->
			

			@listenTo( @model, "change:date", @renderDate )
			@listenTo( @model, "change:time", @renderTime )
			@today = moment()
			@bouncedMonthChange = _.debounce(@handleMonthChanged, 30)
			_.bindAll( @, "handleClickDay", "handleMonthChanged", "bouncedMonthChange" )
			@timeUtil = new TimeUtility()
		getCalendarOpts: ->
			weekOffset = swipy.settings.get("SettingCalendarStartMonday") ? 1 : 0
			return {
				template: CalendarTmpl
				weekOffset: weekOffset
				targets:
					nextButton: "next"
					previousButton: "previous"
					day: "day"
				clickEvents:
					click: @handleClickDay
					onMonthChange: @bouncedMonthChange
				doneRendering: @afterRender
				adjacentDaysChangeMonth: on
				constraints:
					startDay: @getTodayStr()
				ready: => @selectDay @today
				daysOfTheWeek: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
			}
		createCalendar: ->
			@clndr = @$el.clndr @getCalendarOpts()
		getTodayStr: ->
			new moment().format "YYYY-MM-DD"
		getElementFromMoment: (moment) ->
			dateStr = moment.format "YYYY-MM-DD"
			@days.filter -> $(@).attr( "class" ).indexOf( dateStr ) isnt -1
		getTimeObj: (moment) ->
			snoozes = swipy.settings.get "snoozes"
			day = @selectedDay.day()
			weekSetting = swipy.settings.get "SettingWeekStartTime"
			weekendSetting = swipy.settings.get "SettingWeekendStartTime"
					  # sunday    # Saturday
			if day is 0 or day is 6
				hour: @timeUtil.hourForSeconds( weekendSetting )
				minute: @timeUtil.minutesForSeconds( weekendSetting)
			else
				hour: @timeUtil.hourForSeconds( weekSetting )
				minute: @timeUtil.minutesForSeconds( weekSetting )
		getSelectedDateText: ->
			if @selectedDay.isSame(new moment(), 'year')
				@selectedDay.format("MMM Do")
			else
				@selectedDay.format("MMM Do 'YY")
		selectDay: (moment, element) ->
			@days = @$el.find ".day"
			@days.removeClass "selected"
			if not element? then element = @getElementFromMoment moment
			$( element ).addClass "selected"
			@selectedDay = moment

			# This class disables the "Previous month" button, if we're at the current month
			@$el.toggleClass( "displaying-curr-month", moment.isSame( @today, "month" ) )

			@model.unset( "date", { silent: yes } )
			@model.set( "date", @selectedDay )

			if @model.get "userManuallySetTime"
				@renderTime()
			else
				@model.set( "time", @getTimeObj @selectedDay )
				@model.set( "timeEditedBy", "calendar" )
		handleClickDay: (day) ->
			return false if $( day.element ).hasClass "past"
			@selectDay( day.date, day.element )
		handleMonthChanged: (moment) ->
			# Push selected day to new month.
			newDate = moment


			# Check if newMonth has as many days as current month
			# (I.e. switching from a 31 day month to a 29 day month)
			# Moment.js does this automatically.
			oldDate = @selectedDay.date()
			maxDate = newDate.daysInMonth()
			newDate.date Math.min( oldDate, maxDate )

			# Also check that we don't select a date prior to today
			if newDate.isBefore @today then newDate = @today
			@selectDay newDate
		render: ->
			@createCalendar()
			return @
		renderDate: ->
			@$el.find(".month .selected-date").html @getSelectedDateText()
		renderTime: ->
			time = @model.get "time"
			amPm = @timeUtil.isAmPm()
			@$el.find(".month time").html @timeUtil.getFormattedTime( time.hour, time.minute, amPm )
		remove: ->
			@undelegateEvents()
			@stopListening()
			@$el.remove()