define ["view/Default"], (DefaultView) ->
	DefaultView.extend
		events:
			if Modernizr.touch then "tap" else "click "
		init: ->
			# Set HTML tempalte for our list
			#@listTmpl = _.template $("#template-list").html()

			# Render the list whenever it updates
			#swipy.collection.on "change", @renderList, @
		render: ->
			@renderList()
			return @
		getDummyData: ->
			[
				{
					schedule: ""
				}
			]
		renderList: ->
			#items = @getDummyData()
			# items = new Backbone.Collection( swipy.collection.getActive() )
			# @$el.find('.list-wrap').html( @listTmpl( { items: items.toJSON() } ) )
			#@afterRenderList items
		afterRenderList: (models) ->
			# type = if Modernizr.touch then "Touch" else "Desktop"

			# require ["view/list/#{type}ListItem"], (ListItemView) => 
			# 	@$el.find('ol.todo > li').each (i, el) =>
			# 		new ListItemView el: el, model: models.at(i)
		customCleanUp: ->
			# Unbind all events
			#swipy.collection.off()
