(function() {
  var __slice = [].slice;

  define(["underscore", "js/model/TagModel"], function(_, TagModel) {
    return Backbone.View.extend({
      events: {
        "click .add-new-tag": "toggleTagPool",
        "submit .add-tag": "createTag",
        "click .tag-pool li:not(.tag-input)": "addTag",
        "click .applied-tags > li": "removeTag"
      },
      initialize: function() {
        this.toggled = false;
        this.model.on("change:tags", this.render, this);
        return this.render();
      },
      toggleTagPool: function() {
        if (this.toggled) {
          return this.hideTagPool();
        } else {
          return this.showTagPool();
        }
      },
      showTagPool: function() {
        this.toggleButton(false);
        this.$el.addClass("show-pool");
        this.$el.find("form.add-tag input").focus();
        return this.toggled = true;
      },
      hideTagPool: function() {
        this.toggleButton(true);
        this.$el.removeClass("show-pool");
        this.$el.find("form.add-tag input").blur();
        return this.toggled = false;
      },
      toggleButton: function(flag) {
        var icon;
        icon = this.$el.find(".add-new-tag span");
        icon.removeClass("icon-plus icon-minus");
        return icon.addClass(flag === true ? "icon-plus" : "icon-minus");
      },
      addTag: function(e) {
        return this.addTagToModel($(e.currentTarget).text(), false);
      },
      removeTag: function(e) {
        var tagName, tags;
        tagName = $.trim($(e.currentTarget).text());
        tags = _.reject(this.model.get("tags"), function(t) {
          return t.get("title") === tagName;
        });
        return this.model.updateTags(tags);
      },
      createTag: function(e) {
        var tagName;
        e.preventDefault();
        tagName = this.$el.find("form.add-tag input").val();
        if (tagName === "") {
          return;
        }
        return this.addTagToModel(tagName);
      },
      addTagToModel: function(tagName, addToCollection) {
        var newTag, tag, tags;
        if (addToCollection == null) {
          addToCollection = true;
        }
        tags = this.model.get("tags") || [];
        if (_.filter(tags, function(t) {
          return t.get("title") === tagName;
        }).length) {
          return alert("You've already added that tag");
        }
        tag = swipy.tags.findWhere({
          title: tagName
        });
        if (tag != null) {
          tags.push(tag);
        } else {
          newTag = swipy.tags.create ({
            title: tagName
          });
          tags.push(newTag);
        }
        return this.model.updateTags(tags);
      },
      render: function() {
        this.renderTags();
        this.renderTagPool();
        if (this.toggled) {
          this.$el.find("form.add-tag input").focus();
        }
        return this.el;
      },
      renderTags: function() {
        var icon, list, poolToggler, tag, tags, _i, _len;
        list = this.$el.find(" > .rounded-tags");
        list.empty();
        if (this.model.has("tags")) {
          tags = _.invoke(this.model.get("tags"), "get", "title");
          tags = _.sortBy(tags, function(tag) {
            return tag.toLowerCase();
          });
          for (_i = 0, _len = tags.length; _i < _len; _i++) {
            tag = tags[_i];
            this.renderTag(tag, list, "selected");
          }
        }
        icon = "<span class='" + (this.toggled ? "icon-minus" : "icon-plus") + "'></span>";
        poolToggler = "				<li class='add-new-tag'>					<a href='JavaScript:void(0);' title='Add a new tag'>" + icon + "</a>				</li>			";
        return list.append(poolToggler);
      },
      renderTagPool: function() {
        var allTags, list, tagInput, tagname, unusedTags, _i, _len, _ref;
        list = this.$el.find(".tag-pool .rounded-tags");
        list.empty();
        allTags = swipy.tags.pluck("title");
        if (this.model.has("tags")) {
          unusedTags = _.without.apply(_, [allTags].concat(__slice.call(_.invoke(this.model.get("tags"), "get", "title"))));
        } else {
          unusedTags = allTags;
        }
        _ref = _.sortBy(unusedTags, function(tag) {
          return tag.toLowerCase();
        });
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          tagname = _ref[_i];
          this.renderTag(tagname, list);
        }
        tagInput = "				<li class='tag-input'>					<form class='add-tag'>						<input type='text' placeholder='Add new tag'>					</form>				</li>			";
        return list.append(tagInput);
      },
      renderTag: function(tagName, parent, className) {
        var tag;
        if (className == null) {
          className = "";
        }
        tag = $("<li class='" + className + "'>" + tagName + "</li>");
        return parent.append(tag);
      },
      cleanUp: function() {
        this.model.off(null, null, this);
        return this.undelegateEvents();
      }
    });
  });

}).call(this);
