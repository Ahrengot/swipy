(function() {
  define(["underscore", "backbone"], function(_, Backbone) {
    return Backbone.View.extend({
      initialize: function() {
        this.content = this.$el.find('.todo-content');
        return this.render();
      },
      enableInteraction: function() {},
      disableInteraction: function() {
        return console.warn("Disabling gestures for ", this.model.toJSON());
      },
      render: function() {
        this.enableInteraction();
        return this.el;
      },
      remove: function() {
        this.destroy();
        return this.model.off();
      },
      destroy: function() {
        this.disableInteraction();
        return console.log("CLEEEAAAANED!!!!!");
      }
    });
  });

}).call(this);
