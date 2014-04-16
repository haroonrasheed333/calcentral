(function(angular) {
  'use strict';

  angular.module('calcentral.directives').directive('ccYoutubeDirective', function($sce) {
    return {
      restrict: 'AEC',
      scope: {link: '='},
      replace: true,
      template: '<iframe type="text/html" width="100%" height="100%" src="{{url}}" frameborder="0" allowfullscreen></iframe>',
      link: function(scope) {
          scope.$watch('link', function(urlValue) {
             if (urlValue) {
                 scope.url = $sce.trustAsResourceUrl(urlValue);
             }
          });
      }
    };
  });

})(window.angular);
