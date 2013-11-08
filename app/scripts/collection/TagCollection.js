(function() {
  var __slice = [].slice;

  define(["underscore", "backbone"], function(_, Backbone) {
    return Backbone.Collection.extend({
      initialize: function() {
        this.getTagsFromTasks();
        this.on("remove", this.handleTagDeleted, this);
        return this.on("add", this.validateTag, this);
      },
      getTagsFromTasks: function() {
        var tagObjs, tagname, tags;
        tags = [];
        swipy.todos.each(function(m) {
          var tag, _i, _len, _ref, _results;
          if (m.has("tags")) {
            _ref = m.get("tags");
            _results = [];
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              tag = _ref[_i];
              _results.push(tags.push(tag));
            }
            return _results;
          }
        });
        tags = _.unique(tags);
        tagObjs = (function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = tags.length; _i < _len; _i++) {
            tagname = tags[_i];
            _results.push({
              title: tagname
            });
          }
          return _results;
        })();
        return this.reset(tagObjs);
      },
      validateTag: function(model) {
        if (this.where({
          title: model.get("title")
        }).length > 1) {
          return this.remove(model, {
            silent: true
          });
        }
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
