(function() {
  require(['jquery', 'underscore', 'backbone', 'Bootstrap', 'plugins/log'], function($, _, Backbone, App) {
    window.$ = window.jQuery = $;
    window._ = _;
    window.Backbone = Backbone;
    return App.init();
  });

}).call(this);
