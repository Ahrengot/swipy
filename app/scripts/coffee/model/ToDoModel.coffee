define ["backbone", "momentjs"], (Backbone, Moment) ->
	Backbone.Model.extend
		defaults: 
			title: ""
			order: undefined
			schedule: null
			completionDate: null
			repeatOption: "never"
			repeatDate: null
			repeatCount: 0
			tags: null
			notes: ""
			deleted: no
		
		initialize: ->
			# Schedule defaults to a new date object 1 second in the past
			if @get( "schedule" ) is null
				@set( "schedule", @getDefaultSchedule() )

			# Convert schedule to date obj if for some reason it's a string
			if typeof @get( "schedule" ) is "string" 
				@set( "schedule", new Date @get( "schedule" ) )

			@setScheduleStr()
			@setTimeStr()

			@on "change:schedule", =>
				@setScheduleStr()
				@setTimeStr()
				@set( "selected", no )

			@on "change:completionDate", => 
				@setCompletionStr()
				@setCompletionTimeStr()
				@set( "selected", no )
			
			if @has "completionDate" 
				@setCompletionStr()
				@setCompletionTimeStr()

			@on "change:order", =>
				if @get( "order" )? and @get( "order" ) < 0
					console.error "Model order value set to less than 0"

		getDefaultSchedule: ->
			now = new Date()
			now.setSeconds now.getSeconds() - 1
			return now
		
		getValidatedSchedule: ->
			schedule = @get "schedule"
			
			if typeof schedule is "string"
				@set( "schedule", new Date schedule )

			return @get "schedule"

		getDayWithoutTime: (moment) ->
			# Date is within the next week, so just sat the day name — calendar() returns something like "Tuesday at 3:30pm", 
			# and we only want "Tuesday", so use this little RegEx to select everything before the first space.
			return moment.calendar().match( /\w+/ )[0]
		
		setScheduleStr: ->
			schedule = @get "schedule"
			if !schedule 
				if @get "completionDate"
					@set( "scheduleStr", "the past" )
					return @get "scheduleStr"
				else
					return @set( "scheduleStr", "unspecified" )

			now = moment()
			parsedDate = moment schedule

			# Check if parsedDate is in the past
			if parsedDate.isBefore() then return @set( "scheduleStr", "the past" )

			# If difference is more than 1 week, we want different formatting
			if Math.abs( parsedDate.diff( now, "days" ) ) >= 7
				# If it's next year, add year suffix
				if parsedDate.year() > now.year() then result = parsedDate.format "MMM Do 'YY"
				else result = parsedDate.format "MMM Do"

				return @set( "scheduleStr", result )

			dayWithoutTime = @getDayWithoutTime parsedDate

			# Change "Today" to "Later today"
			if dayWithoutTime is "Today" then dayWithoutTime = "Later today"

			@set( "scheduleStr", dayWithoutTime )
		
		setTimeStr: ->
			schedule = @get "schedule"
			if !schedule then return @set( "timeStr", undefined )
			
			# We have a schedule set, update timeStr prop
			@set( "timeStr", moment( schedule ).format "h:mmA" )

		setCompletionStr: ->
			completionDate = @get "completionDate"
			if !completionDate then return @set( "completionStr", undefined )

			now = moment()
			parsedDate = moment completionDate

			# If difference is more than 1 week, we want different formatting
			if parsedDate.diff( now, "days" ) <= -7
				# If it's the previous year, add year suffix
				if parsedDate.year() < now.year() then result = parsedDate.format "MMM Do 'YY"
				else result = parsedDate.format "MMM Do"

				return @set( "completionStr", result )

			dayWithoutTime = @getDayWithoutTime parsedDate

			# Change "Today" to "Later today"
			if dayWithoutTime is "Today" then dayWithoutTime = "Earlier today"

			@set( "completionStr", dayWithoutTime )

		setCompletionTimeStr: ->
			completionDate = @get "completionDate"
			if !completionDate then return @set( "completionTimeStr", undefined )

			# We have a completionDate set, update timeStr prop
			@set( "completionTimeStr", moment( completionDate ).format "h:mmA" )