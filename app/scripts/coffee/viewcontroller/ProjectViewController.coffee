define [
	"underscore"
	"gsap"
	"text!templates/viewcontroller/project-view-controller.html"
	"js/view/tasklist/TaskList"
	"js/view/tasklist/AddTaskCard"
	"js/handler/TaskHandler"
	], (_, TweenLite, Template, TaskList, AddTaskCard, TaskHandler) ->
	Backbone.View.extend
		className: "project-view-controller"
		initialize: ->
			@setTemplate()

			@addTaskCard = new AddTaskCard()
			@addTaskCard.addDelegate = @


			@taskList = new TaskList()
			@taskList.targetSelector = ".project-view-controller .task-list-container"
			@taskList.enableDragAndDrop = true
			@taskList.addTaskDelegate = @
			@taskList.delegate = @

			@taskHandler = new TaskHandler()
			@taskHandler.listSortAttribute = "projectOrder"

			# Settings the Task Handler to receive actions from the task list
			@taskList.taskDelegate = @taskHandler
			@taskList.dragDelegate = @taskHandler


		setTemplate: ->
			@template = _.template Template
		render: ->
			@$el.html @template({})
			$("#main").html(@$el)

			@addTaskCard.render()
			@$el.find('.task-column').prepend( @addTaskCard.el )

			
		open: (options) ->
			@projectId = options.id
			@render()
			@loadProject(@projectId)
		loadProject: (projectId) ->
			@taskList.dataSource = @taskHandler
			@currentProject = swipy.collections.projects.get(projectId)
			
			swipy.topbarVC.setMainTitleAndEnableProgress(@currentProject.get("name"),true)
			@taskHandler.loadSubcollection(
				(task) ->
					return task.get("projectId") is projectId and !task.isSubtask()
			)
			@taskList.reload()
		destroy: ->

		###
			AddTaskCard Delegate
		###
		taskCardDidCreateTask: ( taskCard, title, options) ->
			options = {} if !options
			options.projectId = @projectId
			Backbone.trigger("create-task", title, options)
			@taskList.reload()