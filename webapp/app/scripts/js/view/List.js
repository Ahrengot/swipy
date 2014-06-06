(function() {
  define(["underscore", "js/view/list/ActionBar", "js/view/list/DesktopTask", "js/view/list/TouchTask", "text!templates/todo-list.html", "mousetrapGlobal"], function(_, ActionBar, DesktopTaskView, TouchTaskView, ToDoListTmpl) {
    return Parse.View.extend({
      initialize: function() {
        this.transitionDeferred = new $.Deferred();
        this.template = _.template(ToDoListTmpl);
        this.subviews = [];
        this.renderList = _.debounce(this.renderList, 5);
        this.listenTo(swipy.todos, "add remove reset change:priority change:completionDate change:schedule change:rejectedByTag change:rejectedBySearch", this.renderList);
        this.listenTo(Backbone, "complete-task", this.completeTasks);
        this.listenTo(Backbone, "todo-task", this.markTaskAsTodo);
        this.listenTo(Backbone, "schedule-task", this.scheduleTasks);
        this.listenTo(Backbone, "schedule-task", this.scheduleTasks);
        this.listenTo(Backbone, "scheduler-cancelled", this.handleSchedulerCancelled);
        this.listenTo(Backbone, "clockwork/update", this.moveTasksToActive);
        Mousetrap.bindGlobal("mod+a", $.proxy(this.selectAllTasks, this));
        return this.render();
      },
      render: function() {
        this.renderList();
        $("#add-task input").focus();
        return this;
      },
      sortTasks: function(tasks) {
        return _.sortBy(tasks, function(model) {
          var _ref;
          return (_ref = model.get("schedule")) != null ? _ref.getTime() : void 0;
        });
      },
      groupTasks: function(tasksArr) {
        var deadline, tasks, tasksByDate;
        tasksArr = this.sortTasks(tasksArr);
        tasksByDate = _.groupBy(tasksArr, function(m) {
          return m.get("scheduleStr");
        });
        return (function() {
          var _results;
          _results = [];
          for (deadline in tasksByDate) {
            tasks = tasksByDate[deadline];
            _results.push({
              deadline: deadline,
              tasks: tasks
            });
          }
          return _results;
        })();
      },
      getTasks: function() {
        return swipy.todos.getActive();
      },
      selectAllTasks: function(e) {
        var doSelect, taskInput, tasks;
        taskInput = swipy.input.view.$el.find("input");
        if (!(taskInput.val() && taskInput.is(":focus"))) {
          e.preventDefault();
          tasks = this.getTasks();
          doSelect = _.any(tasks, function(task) {
            return !task.get("selected");
          });
          return _.invoke(tasks, "set", "selected", doSelect);
        }
      },
      moveTasksToActive: function() {
        var movedFromScheduled, now;
        now = new Date().getTime();
        movedFromScheduled = _.filter(this.getTasks(), function(m) {
          if (!m.has("schedule")) {
            return false;
          }
          return now - m.get("schedule").getTime() < 1001;
        });
        if (movedFromScheduled.length) {
          if (movedFromScheduled.length === 1 && movedFromScheduled[0].get("order") === 0) {
            movedFromScheduled[0].set("animateIn", true);
          } else {
            swipy.todos.bumpOrder("down", 0, movedFromScheduled.length);
            _.invoke(movedFromScheduled, "set", {
              order: 0,
              animateIn: true
            });
          }
          return this.renderList();
        }
      },
      renderList: function() {
        var $html, group, list, model, tasksJSON, todos, view, _i, _j, _len, _len1, _ref, _ref1;
        this.$el.empty();
        this.killSubViews();
        todos = this.getTasks();
        todos = _.reject(todos, function(m) {
          return m.get("rejectedByTag") || m.get("rejectedBySearch");
        });
        _.invoke(todos, "set", {
          selected: false
        });
        this.beforeRenderList(todos);
        _ref = this.groupTasks(todos);
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          group = _ref[_i];
          tasksJSON = _.invoke(group.tasks, "toJSON");
          $html = $(this.template({
            title: group.deadline,
            tasks: tasksJSON 
          }));
          list = $html.find("ol");
          _ref1 = group.tasks;
          for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
            model = _ref1[_j];
            if (model.get("tags")) {
              console.log(model.get("tags"));
            }
            view = Modernizr.touch ? new TouchTaskView({
              model: model
            }) : new DesktopTaskView({
              model: model
            });
            this.subviews.push(view);
            list.append(view.el);
          }
          this.$el.append($html);
        }
        return this.afterRenderList(todos);
      },
      beforeRenderList: function(todos) {},
      afterRenderList: function(todos) {},
      getViewForModel: function(model) {
        var view, _i, _len, _ref;
        _ref = this.subviews;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          view = _ref[_i];
          if (view.model.cid === model.cid) {
            return view;
          }
        }
      },
      completeTasks: function(tasks) {
        var minOrder, task, view, _i, _len,
          _this = this;
        minOrder = Math.min.apply(Math, _.invoke(tasks, "get", "order"));
        swipy.todos.bumpOrder("up", minOrder, tasks.length);
        for (_i = 0, _len = tasks.length; _i < _len; _i++) {
          task = tasks[_i];
          view = this.getViewForModel(task);
          if (view != null) {
            (function() {
              var m;
              m = task;
              return view.swipeRight("completed").then(function() {
                return m.completeTask();
              });
            })();
          }
        }
        return swipy.analytics.tagEvent("Completed Tasks", {
          "Number of Tasks": tasks.length
        });
      },
      markTaskAsTodo: function(tasks) {
        var task, view, _i, _len, _results;
        _results = [];
        for (_i = 0, _len = tasks.length; _i < _len; _i++) {
          task = tasks[_i];
          view = this.getViewForModel(task);
          if (view != null) {
            _results.push((function() {
              var m;
              m = task;
              return view.swipeRight("todo").then(function() {
                return m.scheduleTask(m.getDefaultSchedule());
              });
            })());
          } else {
            _results.push(void 0);
          }
        }
        return _results;
      },
      scheduleTasks: function(tasks) {
        var deferredArr, task, view, _i, _len;
        deferredArr = [];
        for (_i = 0, _len = tasks.length; _i < _len; _i++) {
          task = tasks[_i];
          view = this.getViewForModel(task);
          if (view != null) {
            (function() {
              var m;
              m = task;
              return deferredArr.push(view.swipeLeft("scheduled", false));
            })();
          }
        }
        return $.when.apply($, deferredArr).then(function() {
          return Backbone.trigger("show-scheduler", tasks);
        });
      },
      handleSchedulerCancelled: function(tasks) {
        var task, view, _i, _len, _results;
        _results = [];
        for (_i = 0, _len = tasks.length; _i < _len; _i++) {
          task = tasks[_i];
          view = this.getViewForModel(task);
          if (view != null) {
            _results.push(view.reset());
          } else {
            _results.push(void 0);
          }
        }
        return _results;
      },
      transitionInComplete: function() {
        this.actionbar = new ActionBar();
        return this.transitionDeferred.resolve();
      },
      killSubViews: function() {
        var view, _i, _len, _ref;
        _ref = this.subviews;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          view = _ref[_i];
          view.remove();
        }
        return this.subviews = [];
      },
      customCleanUp: function() {},
      remove: function() {
        this.cleanUp();
        return this.$el.empty();
      },
      cleanUp: function() {
        var _ref;
        this.customCleanUp();
        this.transitionDeferred = null;
        this.stopListening();
        this.undelegateEvents();
        if ((_ref = this.actionbar) != null) {
          _ref.kill();
        }
        swipy.todos.invoke("set", {
          selected: false
        });
        return this.killSubViews();
      }
    });
  });

}).call(this);
