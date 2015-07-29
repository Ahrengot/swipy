define [
	"underscore"
	"gsap"
	"js/viewcontroller/TaskListViewController"
	"js/viewcontroller/ChatListViewController"
	
	], (_, TweenLite, TaskListViewController, ChatListViewController) ->
	Backbone.View.extend
		className: "project-view-controller main-view-controller"
		initialize: ->

		render: (el) ->
			@$el.html ""
			$("#main").html(@$el)
			
			swipy.rightSidebarVC.reload()
			@loadMainWindow(@mainView)

		open: (options) ->
			@projectId = options.id
			@mainView = "task"

			swipy.rightSidebarVC.sidebarDelegate = @
			
			@currentProject = swipy.collections.projects.get(@projectId)
			swipy.topbarVC.setMainTitleAndEnableProgress(@currentProject.get("name"),false)
			swipy.rightSidebarVC.loadSidemenu("navbarChat") if !swipy.rightSidebarVC.activeClass?
			@render()

			
		loadMainWindow: (type) ->
			@vc?.destroy()
			if type is "task"
				@vc = @getTaskListVC()
			else if type is "chat"
				@vc = @getChatListVC()
			else return
			@$el.html @vc.el
			@vc.render()


		taskHandlerSortAndGroupCollection: (taskHandler, collection) ->
			self = @
			taskGroups = [{leftTitle: "PROJECT TASKS" , tasks: collection.models}]
			return taskGroups
		### 
			Get A TaskListViewController that filtered for this project
		###
		getTaskListVC: ->
			taskListVC = new TaskListViewController()
			taskListVC.addTaskCard.addDelegate = @
			taskListVC.taskHandler.listSortAttribute = "projectOrder"
			taskListVC.taskHandler.delegate = @

			# https://github.com/anthonyshort/backbone.collectionsubset
			projectId = @projectId
			@collectionSubset = new Backbone.CollectionSubset({
				parent: swipy.collections.todos,
				filter: (task) ->
					return task.get("projectLocalId") is projectId and !task.get("completionDate") and !task.isSubtask()
			})
			taskListVC.taskHandler.loadCollection(@collectionSubset.child)
			
			return taskListVC


		### 
			Get A ChatListViewController that filtered for this project
		###
		getChatListVC: ->
			projectId = @projectId
			@collectionSubset = new Backbone.CollectionSubset({
				parent: swipy.collections.messages,
				filter: (message) ->
					return message.get("projectLocalId") is projectId
			})
			chatListVC = new ChatListViewController()
			chatListVC.newMessage.addDelegate = @
			chatListVC.chatHandler.loadCollection(@collectionSubset.child)
			chatListVC.newMessage.setPlaceHolder("Send message to " + @currentProject.get("name"))
			return chatListVC
		
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
			options = {}
			options.projectLocalId = @projectId
			options.ownerId = @currentProject.get("ownerId")
			Backbone.trigger("send-message", message, options)
			Backbone.trigger("reload/chathandler")
		###
			AddTaskCard Delegate
		###
		taskCardDidCreateTask: ( taskCard, title, options) ->
			options = {} if !options
			options.projectLocalId = @projectId
			options.ownerId = @currentProject.get("ownerId")
			Backbone.trigger("create-task", title, options)
			Backbone.trigger("reload/taskhandler")

		destroy: ->
			Backbone.off(null,null, @)
			@vc?.destroy()