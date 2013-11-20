(function() {
  var __slice = [].slice;

  define(["underscore", "model/TagModel"], function(_, TagModel) {
    return Parse.Collection.extend({
      model: TagModel,
      initialize: function() {
        this.setQuery();
        this.on("remove", this.handleTagDeleted, this);
        this.on("add", this.handleAddTag, this);
        return this.once("reset", this.getTagsFromTasks, this);
      },
      setQuery: function() {
        this.query = new Parse.Query(TagModel);
        return this.query.equalTo("owner", Parse.User.current());
      },
      getTagsFromTasks: function() {
        var m, tag, tags, _i, _j, _len, _len1, _ref, _ref1;
        tags = [];
        _ref = swipy.todos.models;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          m = _ref[_i];
          if (m.has("tags")) {
            _ref1 = m.get("tags");
            for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
              tag = _ref1[_j];
              if (this.validateTag(tag)) {
                tags.push(tag);
              }
            }
          }
        }
        this.reset(tags);
        return this.saveNewTags();
      },
      saveNewTags: function() {
        var model, _i, _len, _ref, _results;
        _ref = this.models;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          model = _ref[_i];
          if (model.isNew()) {
            _results.push(console.log(model.get("title") + " is new!"));
          }
        }
        return _results;
      },
      handleAddTag: function(model) {
        if (!this.validateTag(model)) {
          return this.remove(model, {
            silent: true
          });
        }
      },
      validateTag: function(model) {
        if (!model.has("title")) {
          return false;
        }
        if (this.where({
          title: model.get("title")
        }).length > 1) {
          return false;
        }
        return true;
      },
      /**
      		 * Looks at a tag (Or an array of tags), finds all the tasks that are tagged with those tags.
      		 * (If multiple tags are passed, the tasks must have all of the tags applied to them)
      		 * The method then finds and returns a list of other tags that those tasks have been tagged with.
      		 *
      		 * For example, if we have three tasks like this
      		 * Task 1
      		 * 		- tags: Nina
      		 * Task 2
      		 * 		- tagged: Nina, Pinta
      		 * Task 3
      		 * 		- tagged: Nina, Pinta, Santa-Maria
      		 *
      		 * If you call getSibling( "Nina" ) you will get
      		 * [ "Pinta", "Santa-Maria" ] as the return value.
      		 *
      		 *
      		 * @param  {String/Array} tags a string or an array of strings (Tagnames)
      		 * @param  {Boolean} excludeOriginals if false, the original tags, the ones the siblings are based on, will be included in the result
      		 *
      		 * @return {array}     an array with the results. No results will return an empty array
      */

      getSiblings: function(tags, excludeOriginals) {
        var result, task, _i, _len, _ref;
        if (excludeOriginals == null) {
          excludeOriginals = true;
        }
        if (typeof tags !== "object") {
          tags = [tags];
        }
        result = [];
        _ref = swipy.todos.getTasksTaggedWith(tags);
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          task = _ref[_i];
          result.push(task.get("tags"));
        }
        result = _.flatten(result);
        result = _.unique(result);
        if (excludeOriginals) {
          return _.without.apply(_, [result].concat(__slice.call(tags)));
        } else {
          return result;
        }
      },
      handleTagDeleted: function(model) {
        var affectedTasks, oldTags, tagName, task, _i, _len, _results;
        tagName = model.get("title");
        affectedTasks = swipy.todos.filter(function(m) {
          return m.has("tags") && _.contains(m.get("tags"), tagName);
        });
        _results = [];
        for (_i = 0, _len = affectedTasks.length; _i < _len; _i++) {
          task = affectedTasks[_i];
          oldTags = task.get("tags");
          task.unset("tags", {
            silent: true
          });
          _results.push(task.set("tags", _.without(oldTags, tagName)));
        }
        return _results;
      },
      destroy: function() {
        return this.off(null, null, this);
      }
    });
  });

}).call(this);
