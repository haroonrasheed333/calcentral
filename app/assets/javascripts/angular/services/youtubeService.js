(function(angular) {

  'use strict';
  angular.module('calcentral.services').run(function() {
    var tag = document.createElement('script');
    tag.src = "https://www.youtube.com/iframe_api";
    var firstScriptTag = document.getElementsByTagName('script')[0];
    firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);
    }).service('youtubePlayerApi', function($window, $rootScope) {
        var service = this;

        var youtube = {
            ready: false,
            player: null,
            playerId: null,
            videoId: null,
            videoTitle: null,
            playerHeight: '290',
            playerWidth: '350',
            state: 'stopped'
        };

        // Youtube callback when API is ready
        $window.onYouTubeIframeAPIReady = function() {
            console.log('Youtube API is ready');
            youtube.ready = true;
            service.bindPlayer('player');
            service.loadPlayer();
            $rootScope.$apply();
        };

        function onYoutubeReady(event) {
            console.log('YouTube Player is ready');
            // event.target.playVideo();
            // youtube.player.cueVideoById(selectedVideo.id);
            // youtube.videoId = selectedVideo.id;
            // youtube.videoTitle = selectedVideo.title;
        }

        function onYoutubeStateChange(event) {
          console.log("onYoutubeStateChange");
          console.log(event.data);
            if (event.data == YT.PlayerState.PLAYING) {
                youtube.state = 'playing';
            } else if (event.data == YT.PlayerState.PAUSED) {
                youtube.state = 'paused';
            } else if (event.data == YT.PlayerState.ENDED) {
                youtube.state = 'ended';
            }
            $rootScope.$apply();
        }

        this.bindPlayer = function(elementId) {
            console.log('Binding to ' + elementId);
            youtube.playerId = elementId;
        };

        this.setVideoId = function(vidId) {
            console.log('Video ID ' + vidId);
            youtube.videoId = vidId;
        };

        this.setVideoTitle = function(title) {
            console.log('Title ' + title);
            youtube.videoTitle = title;
        };

        this.createPlayer = function() {
            console.log('Creating a new Youtube player for DOM id ' + youtube.playerId + ' and video ' + youtube.videoId);
            return new YT.Player(youtube.playerId, {
                height: youtube.playerHeight,
                width: youtube.playerWidth,
                videoId: youtube.videoId,
                playerVars: {
                    rel: 0,
                    showinfo: 0
                },
                events: {
                    'onReady': onYoutubeReady,
                    'onStateChange': onYoutubeStateChange
                }
            });
        };

        this.loadPlayer = function() {
            if (youtube.ready && youtube.playerId) {
                // if (youtube.player) {
                //     youtube.player.destroy();
                // }
                youtube.player = service.createPlayer();
                // return youtube;
            }
        };

        this.launchPlayer = function(id, title) {
            youtube.videoId = id;
            youtube.videoTitle = title;
            // if (youtube.player) {
            //   youtube.player.destroy();
            // }
            youtube.player = service.createPlayer();
            // return youtube;
        }

        return service;
    });
}(window.angular));
