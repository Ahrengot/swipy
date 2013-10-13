(function() {
  define(["underscore", "backbone", "text!templates/edit-task.html", "view/editor/TagEditor"], function(_, Backbone, TaskTmpl, TagEditor) {
    return Backbone.View.extend({
      tagName: "article",
      className: "task-editor",
      events: {
        "click .cancel": "back",
        "click .save": "save"
      },
      initialize: function() {
        this.$el.addClass(this.model.getState());
        this.setTemplate();
        this.render();
        return this.createTagEditor();
      },
      setTemplate: function() {
        return this.template = _.template(TaskTmpl);
      },
      createTagEditor: function() {
        return this.tagEditor = new TagEditor({
          el: this.$el.find(".icon-tags"),
          model: this.model
        });
      },
      render: function() {
        this.$el.html(this.template(this.model.toJSON()));
        return this.el;
      },
      back: function() {
        return history.back();
      },
      save: function() {
        var atts, opts,
          _this = this;
        atts = {
          title: this.getTitle(),
          notes: this.getNotes()
        };
        console.log("Saving ", atts);
        opts = {
          success: function() {
            return _this.back();
          },
          error: function() {
            console.warn("Error saving ", arguments);
            return alert("Something went wrong. Please try again in a little bit.");
          }
        };
        return this.model.save(atts, opts);
      },
      getTitle: function() {
        return this.$el.find(".title input").val();
      },
      getNotes: function() {
        return this.$el.find(".notes textarea").val();
      },
      remove: function() {
        this.cleanUp();
        return this.$el.remove();
      },
      cleanUp: function() {
        this.model.off();
        return this.undelegateEvents();
      }
    });
  });

}).call(this);
