define ["underscore"], (_) ->
	class TaskSortModel

		sortBySchedule: (todos) ->
			result = _.sortBy( todos, (m) -> 
				schedule = m.get("schedule")
				if !schedule
					0
				else 
					schedule.getTime()
			)
			result.reverse()
			return result

		setTodoOrder: (todos, newOnTop) ->
			defaultOrderVal = -1
			sortedTodoArray = []

			groupedItems = _.groupBy( todos, (m) -> 
				if m.has("order") and m.get("order") > defaultOrderVal then "ordered" else "unordered"
			)

			if groupedItems.unordered?
				unorderedItems = @sortBySchedule groupedItems.unordered
				sortedTodoArray = unorderedItems

			if groupedItems.ordered?
				orderedItems = _.sortBy( groupedItems.ordered , (m) -> m.get "order" )
				sortedTodoArray = if newOnTop then sortedTodoArray.concat orderedItems else orderedItems.concat sortedTodoArray
			
			orderNumber = 0
			for m in sortedTodoArray
				if !m.has("order") or m.get("order") isnt orderNumber
					m.updateOrder "order", orderNumber
				orderNumber++

			return sortedTodoArray