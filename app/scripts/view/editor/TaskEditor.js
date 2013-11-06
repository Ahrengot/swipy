(function() {
  define(["underscore", "backbone", "text!templates/task-editor.html", "view/editor/TagEditor"], function(_, Backbone, TaskEditorTmpl, TagEditor) {
    return Backbone.View.extend({
      tagName: "article",
      className: "task-editor",
      events: {
        "click .save": "save",
        "click time": "reschedule"
      },
      initialize: function() {
        $("body").addClass("edit-mode");
        this.$el.addClass(this.model.getState());
        this.setTemplate();
        this.render();
        return this.listenTo(this.model, "change:schedule", this.render);
      },
      setTemplate: function() {
        return this.template = _.template(TaskEditorTmpl);
      },
      killTagEditor: function() {
        if (this.tagEditor != null) {
          this.tagEditor.cleanUp();
          return this.tagEditor.remove();
        }
      },
      createTagEditor: function() {
        return this.tagEditor = new TagEditor({
          el: this.$el.find(".icon-tags"),
          model: this.model
        });
      },
      render: function() {
        this.$el.html(this.template(this.model.toJSON()));
        this.killTagEditor();
        this.createTagEditor();
        return this.el;
      },
      save: function() {
        var atts, opts,
          _this = this;
        atts = {
          title: this.getTitle(),
          notes: this.getNotes()
        };
        opts = {
          success: function() {
            return swipy.router.back();
          },
          error: function() {
            return swipy.errors["throw"]("Something went wrong. Please try again in a little bit.", arguments);
          }
        };
        return this.model.save(atts, opts);
      },
      reschedule: function() {
        return Backbone.trigger("show-scheduler", [this.model]);
      },
      transitionInComplete: function() {},
      getTitle: function() {
        return this.$el.find(".title input").val();
      },
      getNotes: function() {
        return this.$el.find(".notes textarea").val();
      },
      remove: function() {
        $("body").removeClass("edit-mode");
        this.undelegateEvents();
        this.stopListening();
        return this.$el.remove();
      }
    });
  });

}).call(this);
