(function() {
  define(["model/ClockWork", "controller/ViewController", "router/MainRouter", "collection/ToDoCollection", "collection/TagCollection", "view/nav/ListNavigation", "controller/TaskInputController", "controller/SidebarController", "controller/ScheduleController", "controller/FilterController", "controller/SettingsController", "controller/ErrorController"], function(ClockWork, ViewController, MainRouter, ToDoCollection, TagCollection, ListNavigation, TaskInputController, SidebarController, ScheduleController, FilterController, SettingsController, ErrorController) {
    var Swipes;
    return Swipes = (function() {
      function Swipes() {
        this.errors = new ErrorController();
        this.todos = new ToDoCollection();
        this.updateTimer = new ClockWork();
        this.todos.on("reset", this.init, this);
        this.fetchTodos();
      }

      Swipes.prototype.init = function() {
        this.cleanUp();
        this.tags = new TagCollection();
        this.viewController = new ViewController();
        this.nav = new ListNavigation();
        this.router = new MainRouter();
        this.scheduler = new ScheduleController();
        this.input = new TaskInputController();
        this.sidebar = new SidebarController();
        this.filter = new FilterController();
        this.settings = new SettingsController();
        return Backbone.history.start({
          pushState: false
        });
      };

      Swipes.prototype.cleanUp = function() {
        var _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8;
        if ((_ref = this.tags) != null) {
          _ref.destroy();
        }
        if ((_ref1 = this.viewController) != null) {
          _ref1.destroy();
        }
        if ((_ref2 = this.nav) != null) {
          _ref2.destroy();
        }
        if ((_ref3 = this.router) != null) {
          _ref3.destroy();
        }
        if ((_ref4 = this.scheduler) != null) {
          _ref4.destroy();
        }
        if ((_ref5 = this.input) != null) {
          _ref5.destroy();
        }
        if ((_ref6 = this.sidebar) != null) {
          _ref6.destroy();
        }
        if ((_ref7 = this.filter) != null) {
          _ref7.destroy();
        }
        if ((_ref8 = this.settings) != null) {
          _ref8.destroy();
        }
        if (Backbone.History.started) {
          return Backbone.history.stop();
        }
      };

      Swipes.prototype.fetchTodos = function() {
        return this.todos.fetch();
      };

      return Swipes;

    })();
  });

}).call(this);
