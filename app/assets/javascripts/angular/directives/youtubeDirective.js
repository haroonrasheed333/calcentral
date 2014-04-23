(function(angular) {
  'use strict';

  angular.module('calcentral.directives').directive('ccYoutubeDirective', function($sce) {
    var imagetemplate = '<div id="image-placeholder"><img ng-src="{{imageUrl}}" class="cc-youtube-thumbnail-image"></img><div class="cc-youtube-thumbnail-button"></div></div>';
    var videotemplate = '<div id="video-placeholder"><iframe type="text/html" width="100%" height="100%" src="{{videoUrl}}" frameborder="0" allowfullscreen></iframe></div>';

    var getTemplate = function(contentType) {
      if (contentType === 'image') {
        return imagetemplate;
      } else if (contentType === 'video') {
        return videotemplate;
      }
    }
    return {
      restrict: 'ACE',
      scope: {
        video: '@video',
        content: '=content'
      },
      replace: true,
      template: function(element, attrs) {
        return getTemplate(attrs.content);
      },
      link: function(scope, element, attrs) {
        scope.$watch('video', function(value) {
          var vid = scope.$eval(value);
          var videoid = vid.video.id;
          var videourl = vid.video.link;
          var content = vid.content;

          if (videoid && content === 'image') {
            var imageUrl = 'http://img.youtube.com/vi/' + videoid + '/maxresdefault.jpg'
            scope.imageUrl = $sce.trustAsResourceUrl(imageUrl);
          } else if (videourl && content === 'video') {
            var videoUrl = videourl + '&autoplay=1'
            scope.videoUrl = $sce.trustAsResourceUrl(videoUrl);
          }
        });
      }
    }
  });

})(window.angular);
