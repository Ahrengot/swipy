(function() {
  require(["jquery", "underscore", "backbone"], function($, _, Backbone) {
    var contentHolder, helpers;
    contentHolder = $("#content-holder");
    helpers = {
      getListItemModel: function() {
        return {
          title: "Follow up on Martin",
          order: 0,
          schedule: new Date(),
          completionDate: null,
          repeatOption: "never",
          repeatDate: null,
          tags: ["work", "client"],
          notes: ""
        };
      },
      renderTodoList: function(data) {
        var dfd;
        dfd = new $.Deferred();
        require(["text!templates/todo-list.html"], function(ListTempl) {
          var tmpl;
          tmpl = _.template(ListTempl);
          contentHolder.html(tmpl(data));
          return dfd.resolve();
        });
        return dfd.promise();
      }
    };
    describe("Basics", function() {
      return it("App should be up and running", function() {
        return expect(window.app).to.exist;
      });
    });
    require(["model/ToDoModel"], function(Model) {
      return describe("List Item model", function() {
        var model;
        model = new Model();
        it("Should set scheduleStr when instantiated", function() {
          return expect(model.get("scheduleString")).to.be("past");
        });
        return it("Should update scheduleStr when schedule property is changed", function() {
          return expect(2).to.be.lessThan(1);
        });
      });
    });
    return require(["model/ToDoModel", "view/list/DesktopListItem"], function(Model, View) {
      return describe("List Item View", function() {
        return describe("Selection", function() {
          return it("Should toggle selection when clicked", function() {
            var model;
            model = new Model(helpers.getListItemModel());
            return helpers.renderTodoList({
              items: [model.toJSON()]
            }).then(function() {
              var el, view;
              el = $("#content-holder .todo > li").first();
              view = new View({
                el: el,
                model: model
              });
              el.click();
              expect(model.get("selected")).to.be["true"];
              expect(el.hasClass("selected")).to.be["true"];
              return contentHolder.empty();
            });
          });
        });
      });
    });
  });

}).call(this);
