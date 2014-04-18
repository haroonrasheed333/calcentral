(function(angular) {

  'use strict';

  angular.module('calcentral.factories').run(function($rootScope, $window) {
    var tag = document.createElement('script');
    tag.src = "//www.youtube.com/iframe_api";
    var firstScriptTag = document.getElementsByTagName('script')[0];
    firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);
  }).factory('youtubePlayer', function($window, $rootScope) {
    var ytplayer = {
      "playerId": null,
      "playerObj": null,
      "videoId": null,
      "height": 390,
      "width": 640
    };

    $window.onYouTubeIframeAPIReady = function() {
      console.log("inside onYouTubeIframeAPIReady");
      // $rootScope.$broadcast('apiReady');
      $rootScope.$apply();
    };

    ytplayer.loadPlayer = function() {
      console.log("inside loadPlayer");
      console.log(this);
       this.playerObj = new YT.Player(this.playerId, {
          height: this.height,
          width: this.width,
          videoId: this.videoId
        });
    };
    return ytplayer;
  });

}(window.angular));
