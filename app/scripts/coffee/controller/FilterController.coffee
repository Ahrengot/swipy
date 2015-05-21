define ["underscore"], (_) ->
	class FilterController
		constructor: ->

			@tagsFilter = []
			@searchFilter = ""

			@debouncedSearch = _.debounce( @applySearchFilter, 100 )
			@debouncedClearSearch = _.debounce( @removeSearchFilter, 100 )

			Backbone.on( "apply-filter", @applyFilter, @ )
			Backbone.on( "remove-filter", @removeFilter, @ )

		hasFilters: ->
			@tagsFilter.length or @searchFilter.length
		applyFilter: (type, filter) ->
			if type is "tag" then @applyTagsFilter filter else @debouncedSearch filter

		removeFilter: (type, filter) ->
			if type is "tag" then @removeTagsFilter filter else @debouncedClearSearch filter

		updateFilterString: (number) ->
			
			if !number 
				numString = "No"			
			else numString = ""+number
			

			category = "current"
			if Backbone.history.fragment is "list/scheduled"
				category = "scheduled"
			if Backbone.history.fragment is "list/completed"
				category = "completed"
			

			filterString = "<b>" + numString + " " + category + "</b> "


			filterString += "task"
			filterString += "s" if number != 1

			counter = 0


			if @searchFilter.length
				 filterString += " matching <b>\"" + @searchFilter + "\"</b>"
				 counter++

			if @tagsFilter.length
				withOrAndString = " with"
				withOrAndString = " and" if counter > 0
				tagString = @tagsFilter.join(", ")
				filterString += withOrAndString + " tags: <b>" + tagString + "</b>" 
				counter++

			$('#search-result-string').html(filterString)

		clearFilters: ->
			if @searchFilter.length then @removeSearchFilter()
			if @tagsFilter.length
				@tagsFilter = []
				@removeTagsFilter()

		applyTagsFilter: (addTag) ->
			if (addTag) and not _.contains( @tagsFilter, addTag )
				@tagsFilter.push addTag

			for task in swipy.todos.models
				reject = yes

				if task.has( "tags" ) and _.intersection( task.getTagStrList(), @tagsFilter ).length is @tagsFilter.length
					reject = no

				task.set( "rejectedByTag", reject )
		hasTagAsFilter: (tag) ->
			for filterTag in @tagsFilter
				if tag is filterTag
					return true
			return false
		applySearchFilter: (filter) ->
			@searchFilter = filter
			swipy.todos.each (model) =>
				didFind = false
				return if model.get "parentLocalId"

				if model.get( "title" ).toLowerCase().indexOf( @searchFilter ) isnt -1
					didFind = true
				if model.get("subtasksLocal")? and model.get("subtasksLocal")
					for subtask in model.get("subtasksLocal") 
						if subtask.get( "title" ).toLowerCase().indexOf( @searchFilter ) isnt -1
							didFind = true
				if model.get("notes")? and model.get("notes").toLowerCase().indexOf( @searchFilter ) isnt -1
					didFind = true
				if model.get("tags") and model.get("tags")
					for tag in model.get("tags")
						if tag.get("title").toLowerCase().indexOf(@searchFilter) isnt -1
							didFind = true

				model.unset("rejectedBySearch", {silent:true})
				model.set( "rejectedBySearch", !didFind )

		removeTagsFilter: (tag) ->
			@tagsFilter = _.without( @tagsFilter, tag )
			if @tagsFilter.length is 0
				swipy.todos.invoke( "set", "rejectedByTag", no )
			else
				@applyTagsFilter()

		removeSearchFilter: (filter) ->
			@searchFilter = ""
			swipy.todos.invoke( "set", "rejectedBySearch", no )

		destroy: ->
			Backbone.off( null, null, @ )
