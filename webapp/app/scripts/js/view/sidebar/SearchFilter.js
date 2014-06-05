(function() {
  define(["underscore", "backbone"], function(_, Backbone) {
    return Parse.View.extend({
      events: {
        "submit form": "search",
        "keyup input": "search",
        "change input": "search"
      },
      initialize: function() {
        return this.input = $("form input");
      },
      search: function(e) {
        var eventName, value;
        e.preventDefault();
        value = this.input.val();
        eventName = value.length ? "apply-filter" : "remove-filter";
        return Backbone.trigger(eventName, "search", value.toLowerCase());
      },
      destroy: function() {
        this.stopListening();
        return this.undelegateEvents();
      }
    });
  });

}).call(this);
