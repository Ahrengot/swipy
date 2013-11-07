(function() {
  define(["underscore", "backbone"], function(_, Backbone) {
    return Backbone.View.extend({
      events: {
        "click li": "toggleFilter",
        "click .remove": "removeTag",
        "submit form": "createTag"
      },
      initialize: function() {
        this.listenTo(swipy.tags, "add remove reset", this.render);
        this.listenTo(Backbone, "apply-filter remove-filter", this.handleFilterChange);
        return this.render();
      },
      handleFilterChange: function(type) {
        var _this = this;
        return _.defer(function() {
          if (type === "tag") {
            return _this.render();
          }
        });
      },
      toggleFilter: function(e) {
        var el, tag;
        tag = $.trim($(e.currentTarget).text());
        el = $(e.currentTarget);
        if (!el.hasClass("selected")) {
          return Backbone.trigger("apply-filter", "tag", tag);
        } else {
          return Backbone.trigger("remove-filter", "tag", tag);
        }
      },
      createTag: function(e) {
        var tagName;
        e.preventDefault();
        tagName = this.$el.find("form.add-tag input").val();
        if (tagName === "") {
          return;
        }
        return this.addTag(tagName);
      },
      addTag: function(tagName) {
        return swipy.tags.add({
          title: tagName
        });
      },
      removeTag: function(e) {
        var tag, tagName, wasSelected;
        e.stopPropagation();
        tagName = $.trim($(e.currentTarget.parentNode).text());
        tag = swipy.tags.findWhere({
          title: tagName
        });
        wasSelected = $(e.currentTarget.parentNode).hasClass("selected");
        if (tag && confirm("Are you sure you want to permenently delete this tag?")) {
          return tag.destroy({
            success: function(model, response) {
              swipy.todos.remove(model);
              if (wasSelected) {
                return Backbone.trigger("remove-filter", "tag", tagName);
              }
            },
            error: function(model, response) {
              alert("Something went wrong trying to delete the tag '" + (model.get('title')) + "' please try again.");
              return console.warn("Error deleting tag — Response: ", response);
            }
          });
        }
      },
      isValid: function(tag) {
        var otherTag, otherTags, result, task, _i, _j, _len, _len1, _ref;
        if (_.contains(swipy.filter.tagsFilter, tag)) {
          return true;
        } else {
          otherTags = [];
          result = false;
          _ref = swipy.todos.getTasksTaggedWith(tag);
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            task = _ref[_i];
            otherTags = _.union(otherTags, task.get("tags"));
          }
          for (_j = 0, _len1 = otherTags.length; _j < _len1; _j++) {
            otherTag = otherTags[_j];
            if (_.contains(swipy.filter.tagsFilter, otherTag)) {
              result = true;
            }
          }
          return result;
        }
      },
      render: function() {
        var list, tag, _i, _j, _len, _len1, _ref, _ref1, _ref2;
        list = this.$el.find(".rounded-tags");
        list.empty();
        if (((_ref = swipy.filter) != null ? _ref.tagsFilter.length : void 0) > 0) {
          _ref1 = swipy.tags.pluck("title");
          for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
            tag = _ref1[_i];
            if (this.isValid(tag)) {
              this.renderTag(tag, list);
            }
          }
        } else {
          _ref2 = swipy.tags.pluck("title");
          for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
            tag = _ref2[_j];
            this.renderTag(tag, list);
          }
          this.renderTagInput(list);
        }
        return this;
      },
      renderTag: function(tag, list) {
        if ((swipy.filter != null) && _.contains(swipy.filter.tagsFilter, tag)) {
          return list.append("<li class='selected'>" + tag + "</li>");
        } else {
          return list.append("<li>" + tag + "</li>");
        }
      },
      renderTagInput: function(list) {
        return list.append("				<li class='tag-input'>					<form class='add-tag'>						<input type='text' placeholder='Add new tag'>					</form>				</li>");
      },
      remove: function() {
        this.stopListening();
        this.undelegateEvents();
        return this.$el.remove();
      }
    });
  });

}).call(this);
