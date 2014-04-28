(function(angular) {
  'use strict';

  angular.module('calcentral.directives').directive('ccImageLoadedDirective', function() {
    return {
      link: function(scope, elm, attrs) {
        elm.bind('load', function() {
          scope[attrs.ccImageLoadedDirective] = true;
        });
      }
    };
  });

})(window.angular);
