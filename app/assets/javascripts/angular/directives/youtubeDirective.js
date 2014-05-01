(function(angular) {
  'use strict';

  angular.module('calcentral.directives').directive('ccYoutubeDirective', function($sce, $compile) {
    return {
      restrict: 'ACE',
      replace: true,
      link: function(scope, elem, attrs) {
        scope.$watch(attrs.ccYoutubeDirective, function(value) {
          var videoid = value;
          var imageDivId = 'image-placeholder-' + videoid;
          var videoDivId = 'video-placeholder-' + videoid;
          var videourl = 'https://www.youtube.com/embed/' + videoid + '?version=3&f=playlists&app=youtube_gdata&showinfo=0&theme=light&modestbranding=1&autoplay=1';

          if (videoid) {
            angular.element(document.querySelector('#' + videoDivId)).remove();
            angular.element(document.querySelector('#' + imageDivId)).remove();
            var imageUrl = 'http://img.youtube.com/vi/' + videoid + '/maxresdefault.jpg';
            scope.imageUrl = $sce.trustAsResourceUrl(imageUrl);
            var imagetemplate = '<div id="' + imageDivId + '" data-ng-click="loadVideo=1"><img ng-src="{{imageUrl}}" class="cc-youtube-thumbnail-image"></img><div class="cc-youtube-thumbnail-button"></div></div>';
            var el = angular.element(imagetemplate);
            var compiled = $compile(el);
            elem.append(el);
            compiled(scope);
          }

          elem.on('click', function() {
            angular.element(document.querySelector('#' + imageDivId)).remove();
            angular.element(document.querySelector('#' + videoDivId)).remove();
            var videotemplate = '<div id="' + videoDivId + '" class="cc-youtube-video"><iframe type="text/html" width="100%" height="100%" src=' + videourl + ' frameborder="0" allowfullscreen></iframe></div>';
            var el = angular.element(videotemplate);
            var compiled = $compile(el);
            elem.append(el);
            compiled(scope);
          });

        });
      }
    };

  });

})(window.angular);
