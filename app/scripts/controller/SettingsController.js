(function() {
  define(["underscore", "backbone", "view/scheduler/SettingsOverlay", "model/SettingsModel"], function(_, Backbone, SettingsOverlayView, SettingsModel) {
    var SettingsController;
    return SettingsController = (function() {
      function SettingsController(opts) {
        this.init();
      }

      SettingsController.prototype.init = function() {
        this.model = new SettingsModel();
        this.view = new SettingsOverlayView({
          model: this.model
        });
        $("body").append(this.view.render().el);
        Backbone.on("show-settings", this.view.show, this.view);
        return Backbone.on("hide-settings", this.view.hide, this.view);
      };

      SettingsController.prototype.destroy = function() {
        this.view.remove();
        return Backbone.off(null, null, this);
      };

      return SettingsController;

    })();
  });

}).call(this);
