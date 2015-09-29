define [
	"underscore"
	"gsap"
	"js/viewcontroller/TaskListViewController"
	"js/viewcontroller/ChatListViewController"
	"js/utility/TimeUtility"
	"collectionSubset"
	"momentjs"
	], (_, TweenLite, TaskListViewController, ChatListViewController, TimeUtility) ->
	Backbone.View.extend
		className: "channel-view-controller main-view-controller"
		initialize: ->
			@timeUtil = new TimeUtility()
			Backbone.on( "create-task", @createTask, @ )
			@bouncedHandleEdited = _.debounce(@handleEditedTask, 10)
			Backbone.on( "tasklistvc/edited-task", @bouncedHandleEdited, @)
			Backbone.on( "clicked/section", @clickedSection, @)
		render: (el) ->
			@$el.html "<div style=\"text-align:center; margin-top:100px;\">Loading</div>"
			$("#main").html(@$el)
			
			swipy.rightSidebarVC.reload()
			setTimeout( => 
				@loadMainWindow(@mainView)
			, 5)
			@updateTopbarTitle()
		open: (type, options) ->
			@identifier = options.id
			@type = type
			@mainView = "chat"

			@showSomedayMaybe = false
			@showLaterTasks = false

			swipy.rightSidebarVC.sidebarDelegate = @
			if @type isnt "im"
				collection = swipy.slackCollections.channels

				@currentList = collection.findWhere({name: @identifier})
				
			else
				collection = swipy.slackCollections.channels
			
				@currentUser = swipy.slackCollections.users.findWhere({name: @identifier})
				
				@currentList = collection.findWhere({is_im: true, user: @currentUser.id})
				
			swipy.rightSidebarVC.loadSidemenu("navbarChat") if !swipy.rightSidebarVC.activeClass?
			@render()
			action = options.action
			if action is "task" and options.actionId
				task = swipy.collections.todos.get(options.actionId)
				if task
					Backbone.trigger("edit/task", task) if task
		threadHeaderDidClickClear: (threadHeader) ->
			@taskListVC?.goBackFromEditMode()
		handleEditedTask: ->
			@updateTopbarTitle()
			return
			#if !localStorage.getItem("EnableThreadedConversations")
			
			# Is editing
			if @taskListVC? and @taskListVC.editModel
				model = @taskListVC.editModel
				@chatListVC?.chatHandler?.startsWith = "<http://swipesapp.com/task/"+ model.id
				@currentList.skipCount = 200
				@chatListVC?.chatList.hasRendered = false
				@chatListVC?.chatList.isThread = true
				@chatListVC?.threadHeader.show(true)
				@currentList.fetchMessages(null, (res, error) =>
					if res and res.ok
						@chatListVC.chatList.hasMore = true
				)
				Backbone.trigger("reload/chathandler")
			else
				@chatListVC.chatList.hasRendered = false
				@chatListVC?.chatList.isThread = false
				@chatListVC?.threadHeader.show(false)
				@currentList.skipCount = 100
				@currentList.getMessages()
				@chatListVC?.chatHandler?.startsWith = null
				Backbone.trigger("reload/chathandler")
		updateTopbarTitle: ->
			if @type isnt "im"
				name = "# "+@currentList.get("name")
			else
				name = @currentUser.get("name")
				name = "slackbot & s.o.f.i." if name is "slackbot"
			if @taskListVC? and @taskListVC.editModel
				name += " &nbsp;>&nbsp; " +@taskListVC.editModel.get("title")
			swipy.topbarVC.setMainTitleAndEnableProgress(name, false)
		loadMainWindow: (type) ->
			@vc?.destroy()
			if type is "task"
				@vc = @getTaskListVC()
			else if type is "chat"
				@vc = @getChatListVC()
			else return
			@$el.html @vc.el
			@vc.render()
		

		createTask: ( title, options ) ->
			options = {} if !options
			options.targetUserId = @currentUser.id if @currentUser?
			options.projectLocalId = @currentList.id
			@taskCollectionSubset?.child.createTask(title, options)
			Backbone.trigger("reload/taskhandler")
		clickedSection: (section) ->
			if section is "future-tasks"
				@showLaterTasks = true
			else if section is "someday-maybe"
				@showSomedayMaybe = true
			@taskListVC?.taskHandler.bouncedReloadWithEvent()

		### 
			TaskHandler delegate
		###
		taskHandlerSortAndGroupCollection: (taskHandler, collection, toggleComplete) ->
			self = @
			tasks = _.filter collection.models, (m) ->
				if toggleComplete
					m.get("completionDate")
				else
					!m.get("completionDate")
			groups = _.groupBy(tasks, (model, i) =>
				if model.get("completionDate") then return moment(model.get("completionDate")).startOf('day').unix()
				if model.getState() is "active" then return -1
				else if model.getState() is "scheduled"
					schedule = model.get("schedule")
					return 9999999999 if !schedule? or !schedule
					return 9999999998 if !@showLaterTasks
					return moment(schedule).startOf('day').unix()
			)
			
			taskGroups = []
			sortedKeys = _.keys(groups).sort()

			if toggleComplete
				sortedKeys = sortedKeys.reverse()
			
			for key in sortedKeys
				dontSort = false
				includeTasks = true
				expandClass = false
				tasks = groups[key]
				numberOfTasksForSection = tasks.length
				showSchedule = false
				if key is "-1"
					title = @currentList.get("name")+ " tasks"
					if @currentUser?
						title =  "You & " + @currentUser.get("name") + "'s tasks"
						if @currentUser.get("name") is "slackbot"
							title = "You, slackbot & s.o.f.i's tasks"
				else if key is "9999999999"
					title = "Someday/Maybe"
					if !@showSomedayMaybe
						title += " ( " + numberOfTasksForSection + " )"
						includeTasks = false
						expandClass = "someday-maybe"
				else if key is "9999999998"
					title = "Future Tasks ( " + numberOfTasksForSection + " )"
					includeTasks = false
					expandClass = "future-tasks"
				else
					dontSort = true
					showSchedule = true
					schedule = new Date(parseInt(key)*1000)
					groups[key] = _.sortBy(groups[key], (model) ->
						return -model.get("completionDate").getTime() if toggleComplete? and toggleComplete
						return model.get("schedule")?.getTime()
					)
					title = @timeUtil.dayStringForDate(schedule)
					if toggleComplete
						title = "Completed " + title
					else if title is "Today"
						title = "Later Today"
				group = {showSchedule: showSchedule, leftTitle: title, dontSort: dontSort, expandClass: expandClass }
				group.tasks = tasks if includeTasks
				
				taskGroups.push(group)

			return taskGroups



		### 
			Get A TaskListViewController that filtered for this project
		###
		getTaskListVC: ->
			# https://github.com/anthonyshort/backbone.collectionsubset
			projectId = @currentList.id
			@taskCollectionSubset = new Backbone.CollectionSubset({
				parent: swipy.collections.todos,
				filter: (task) ->
					return task.get("projectLocalId") is projectId and !task.isSubtask()
			})

			@taskListVC = new TaskListViewController
				delegate: @
				collectionToLoad: @taskCollectionSubset.child



		### 
			Get A ChatListViewController that filtered for this project
		###
		getChatListVC: ->
			chatListVC = new ChatListViewController()
			chatListVC.newMessage.addDelegate = @
			chatListVC.chatList.delegate = @
			chatListVC.threadHeader.clickDelegate = @
			chatListVC.chatList.lastRead = parseInt(@currentList.get("last_read"))
			chatListVC.chatHandler.loadCollection(@currentList)
			if @currentUser? # if is IM
				chatListVC.newMessage.setPlaceHolder("Send a message to " + @currentUser.get("name"))
				if @currentUser.get("name") is "slackbot"
					chatListVC.newMessage.setPlaceHolder("Send a message to slackbot & s.o.f.i.")
			else
				chatListVC.newMessage.setPlaceHolder("Send a message to " + @currentList.get("name"))
			@chatListVC = chatListVC

			@currentList.fetchMessages(null, (res, error) ->
				if res and res.ok
					chatListVC.chatList.hasMore = true
					chatListVC.chatList.hasRendered = false
			)
			return chatListVC
		

		###
			ChatList ChatDelegate
		###
		chatListDidScrollToTop: (chatList) ->
			return if @isFetchingMore or !chatList.numberOfChats
			return if @taskListVC? and @taskListVC.editModel
			@isFetchingMore = true
			@currentList.fetchOlderMessages((res, error) =>
				@isFetchingMore = false
				if res and res.ok
					if res.messages and res.messages.length
						lastMessage = res.messages[0]
						chatList.setScrollToMessage(lastMessage.ts)
			)
		chatListMarkAsRead: (chatList, timestamp) ->
			@currentList.markAsRead()


		###
			RightSidebarDelegate
		###
		sidebarSwitchToView: (sidebar, view) ->
			if @mainView is "task"
				@mainView = "chat" 
			else @mainView = "task"
			@render()
		sidebarGetViewController: (sidebar) ->
			if @mainView is "task"
				return @getChatListVC()
			else
				return @getTaskListVC()


		###
			NewMessage Delegate
		###
		newMessageSent: ( newMessage, message ) ->
			# Add thread identifier if needed
			if @taskListVC? and @taskListVC.editModel and localStorage.getItem("EnableThreadedConversations")
				model = @taskListVC.editModel
				message = "<http://swipesapp.com/task/" + model.id + "|" + model.get("title") + ">: " + message
			swipy.slackSync.sendMessage( message, @currentList.id)
			@chatListVC.chatList.scrollToBottomVar = true
			@chatListVC.chatList.removeUnreadIfSeen = true
		newFileSelected: (newMessage, file) ->
			newMessage.setUploading(true)
			swipy.slackSync.uploadFile(@currentList.id, file, (res, error) ->
				newMessage.setUploading(false)
				if res and res.ok
					console.log "success!"
				else
					alert("An error happened with the upload")
			)
		newMessageIsTyping: (newMessage ) ->
			options = {type: "typing", channel: @currentList.id }
			swipy.slackSync.doSocketSend(options, true)
		###
			AddTaskCard Delegate
		###
		taskCardDidCreateTask: ( taskCard, title, options) ->
			@createTask( title, options)

		destroy: ->
			@chatListVC?.destroy()
			@taskListVC?.destroy()
			Backbone.off(null,null, @)
			@vc?.destroy()