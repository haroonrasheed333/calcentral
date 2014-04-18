// (function(angular) {
//   'use strict';

//   angular.module('calcentral.directives').directive('ccYoutubeDirective', function($sce) {
//     return {
//       restrict: 'AEC',
//       scope: {link: '='},
//       replace: true,
//       template: '<iframe type="text/html" width="100%" height="100%" src="{{url}}" frameborder="0" allowfullscreen></iframe>',
//       link: function(scope) {
//           scope.$watch('link', function(urlValue) {
//              if (urlValue) {
//                  scope.url = $sce.trustAsResourceUrl(urlValue);
//              }
//           });
//       }
//     };
//   });

// })(window.angular);

(function(angular) {
  'use strict';

  angular.module('calcentral.directives').directive('ccYoutubeDirective', ['youtubePlayer', function(youtubePlayerApi) {
    console.log("ccYoutubeDirective1");
    return {
      restrict: 'AEC',
      link: function(scope,element,attrs) {
        youtubePlayerApi.playerId = attrs.id;
        youtubePlayerApi.videoId = attrs.code;
      }
    };
  }]);
})(window.angular);
