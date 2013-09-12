(function() {
  define(["view/Default", "text!templates/todo-list.html"], function(DefaultView, TodoListTemplate) {
    return DefaultView.extend({
      events: Modernizr.touch ? "tap" : "click ",
      init: function() {
        return this.template = _.template(TodoListTemplate);
      },
      render: function() {
        this.renderList();
        return this;
      },
      getDummyData: function() {
        return [
          {
            title: "Follow up on Martin",
            order: 0,
            schedule: new Date(),
            completionDate: null,
            repeatOption: "never",
            repeatDate: null,
            tags: ["work", "client"],
            notes: ""
          }, {
            title: "Make visual research",
            order: 1,
            schedule: new Date(),
            completionDate: null,
            repeatOption: "never",
            repeatDate: null,
            tags: ["work", "Project y19"],
            notes: ""
          }, {
            title: "Buy a new Helmet",
            order: 2,
            schedule: new Date(),
            completionDate: null,
            repeatOption: "never",
            repeatDate: null,
            tags: ["Personal", "Bike", "Outside"],
            notes: ""
          }, {
            title: "Renew Wired Magazine subscription",
            order: 3,
            schedule: new Date(),
            completionDate: null,
            repeatOption: "never",
            repeatDate: null,
            tags: ["Personal", "Home"],
            notes: ""
          }, {
            title: "Get a Haircut",
            order: 4,
            schedule: new Date(),
            completionDate: null,
            repeatOption: "never",
            repeatDate: null,
            tags: ["Errand", "Home"],
            notes: ""
          }, {
            title: "Clean up the house",
            order: 5,
            schedule: new Date(),
            completionDate: null,
            repeatOption: "never",
            repeatDate: null,
            tags: ["Errand", "City"],
            notes: ""
          }
        ];
      },
      renderList: function() {
        var items;
        items = this.getDummyData();
        this.$el.html(this.template({
          items: items
        }));
        return this.afterRenderList(items);
      },
      afterRenderList: function(models) {
        return console.log("Rendered json: ", models);
      },
      customCleanUp: function() {}
    });
  });

}).call(this);
