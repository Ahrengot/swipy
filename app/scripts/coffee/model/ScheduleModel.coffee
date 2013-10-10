define ["underscore", "momentjs"], (_, Moment) ->
	class ScheduleModel
		constructor: (@settings) ->
			@validateSettings()
			@data = @getData()
			
		validateSettings: ->

		getData: ->
			return [
				{ id: "later today", title: @getDynamicTime( "Later Today" ), disabled: no }
				{ id: "this evening", title: @getDynamicTime( "This Evening" ), disabled: no }
				{ id: "tomorrow", title: @getDynamicTime( "Tomorrow" ), disabled: no }
				{ id: "day after tomorrow", title: @getDynamicTime( "Day After Tomorrow" ), disabled: no }
				{ id: "this weekend", title: @getDynamicTime( "This Weekend" ), disabled: no }
				{ id: "next week", title: @getDynamicTime( "Next Week" ), disabled: no }
				{ id: "unspecified", title: @getDynamicTime( "Unspecified" ), disabled: no }
				{ id: "at location", title: @getDynamicTime( "At Location" ), disabled: yes }
				{ id: "pick a date", title: @getDynamicTime( "Pick A Date" ), disabled: no }
			]

		getDateFromScheduleOption: (option, now) ->
			if now
				newDate = moment now
			else
				newDate = moment()

			# Check settings for 'this evening' setting, but for now just use 18:00
			switch option
				when "later today"
					newDate.hour( newDate.hour() + swipy.settings.model.get("laterTodayDelay") )
				when "this evening"
					if newDate.hour() >= swipy.settings.get("snoozes").evening then newDate.add( "days", 1 )
					newDate.hour swipy.settings.get("snoozes").evening
					newDate = newDate.startOf "hour"
				when "tomorrow"
					newDate.add( "days", 1 )
					newDate.hour swipy.settings.get("snoozes").weekday.morning
					newDate = newDate.startOf "hour"
				when "day after tomorrow"
					newDate.add( "days", 2 )
					newDate.hour swipy.settings.get("snoozes").weekday.morning
					newDate = newDate.startOf "hour"
				when "this weekend"
					# If we're on weekend start date, fast-forward 7 days.
					if newDate.day() is swipy.settings.get("snoozes").startOfWeekend
						newDate.add( "days", 7 )
					else
						newDate.day swipy.settings.get("snoozes").weekend.start
					
					newDate.hour swipy.settings.get("snoozes").weekend.morning
					newDate = newDate.startOf "hour"
				when "next week"
					# If we're on week start date, fast-forward 7 days.
					if newDate.day() is swipy.settings.get("snoozes").startOfWeek
						newDate.add( "days", 7 )
					else
						newDate.day swipy.settings.get("snoozes").weekday.start
					
					newDate.hour swipy.settings.get("snoozes").weekday.morning
					newDate = newDate.startOf "hour"
				else 
					# Catch any errors and return null, because then they aren't lost, just simply 
					# put in the 'unspecified' pile
					return null

			return newDate.toDate()
		getDynamicTime: (time, now) ->
			if not now then now = moment()

			switch time
				when "This Evening"
					return if now.hour() >= 18 then "Tomorrow Evening" else "This Evening"
				when "Day After Tomorrow"
					dayAfterTomorrow = moment( now ).add( "days", 2 )
					return dayAfterTomorrow.format "dddd"
				when "This Weekend"
					return if now.day() < 5 then "This Weekend" else "Next Weekend"
				else 
					return time

		toJSON: ->
			return { options: @data }
