define ["underscore"], (_) ->
	class FilterController
		constructor: ->

			@tagsFilter = []
			@hideTagsFilter = []
			@searchFilter = ""

			@debouncedSearch = _.debounce( @applySearchFilter, 100 )
			@debouncedClearSearch = _.debounce( @removeSearchFilter, 100 )

			_.bindAll( @, "clickedTagInFooter" )
			Backbone.on( "apply-filter", @applyFilter, @ )
			Backbone.on( "remove-filter", @removeFilter, @ )

		hasFilters: ->
			@tagsFilter.length or @searchFilter.length or @hideTagsFilter.length
		applyFilter: (type, filter) ->
			if type is "tag" then @applyTagsFilter filter
			else if type is "hide-tag" then @applyTagsFilter(filter, true)
			else @debouncedSearch filter

		removeFilter: (type, filter) ->
			if type is "tag" then @removeTagsFilter filter else @debouncedClearSearch filter

		updateFilterString: (number) ->
			
			if !number 
				numString = "No"			
			else numString = ""+number
			

			category = "current"
			if Backbone.history.fragment is "tasks/later"
				category = "scheduled"
			if Backbone.history.fragment is "tasks/done"
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
				tagString = @tagsFilter.join("</b>, <b class=\"tag\">")
				filterString += withOrAndString + " tags: <b class=\"tag\">" + tagString + "</b>" 
				counter++

			if @hideTagsFilter.length
				withOrAndString = " without"
				withOrAndString = " and without" if counter > 0
				tagString = @hideTagsFilter.join("</b>, <b class=\"tag\">")
				filterString += withOrAndString + " tags: <b class=\"tag\">" + tagString + "</b>" 
				counter++
			$('#search-result-string').off( "click", @clickedTagInFooter )
			$('#search-result-string').html(filterString)
			$('#search-result-string').on( "click", "b.tag", @clickedTagInFooter )
		clickedTagInFooter: (e) ->
			@removeTagsFilter($(e.currentTarget).text())
		clearFilters: ->
			if @searchFilter.length then @removeSearchFilter()
			if @tagsFilter.length or @hideTagsFilter.length
				@tagsFilter = []
				@hideTagsFilter = []
				@removeTagsFilter()

		applyTagsFilter: (tagName, hide) ->
			targetCollection = @tagsFilter
			if hide?
				targetCollection = @hideTagsFilter
			if (tagName) and not _.contains( targetCollection, tagName )
				targetCollection.push tagName
				if hide? then @tagsFilter = _.without( @tagsFilter, tagName )
				else @hideTagsFilter = _.without( @hideTagsFilter, tagName )


			for task in swipy.collections.todos.models
				reject = yes

				if task.has( "tags" ) and _.intersection( task.getTagStrList(), @tagsFilter ).length is @tagsFilter.length and _.intersection( task.getTagStrList(), @hideTagsFilter ).length is 0
					reject = no

				task.set( "rejectedByTag", reject )
				if reject is yes and task.get("selected")
					task.set("selected",no)
		hasTagAsFilter: (tag) ->
			for filterTag in @tagsFilter
				if tag is filterTag
					return true
			for filterTag in @hideTagsFilter
				if tag is filterTag
					return true
			return false
		applySearchFilter: (filter) ->
			@searchFilter = filter
			swipy.collections.todos.each (model) =>
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
				if !didFind and model.get("selected")
					model.set("selected",no)

		removeTagsFilter: (tag) ->
			@tagsFilter = _.without( @tagsFilter, tag )
			@hideTagsFilter = _.without( @hideTagsFilter, tag )
			if @tagsFilter.length is 0 and @hideTagsFilter.length is 0
				swipy.collections.todos.invoke( "set", "rejectedByTag", no )
			else
				@applyTagsFilter()

		removeSearchFilter: (filter) ->
			@searchFilter = ""
			swipy.collections.todos.invoke( "set", "rejectedBySearch", no )

		destroy: ->
			Backbone.off( null, null, @ )
