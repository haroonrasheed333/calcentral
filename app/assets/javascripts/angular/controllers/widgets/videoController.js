(function(angular) {
  'use strict';

  /**
   * Video controller
   */
  angular.module('calcentral.controllers').controller('VideoController', function($http, $scope, youtubePlayerApi) {

    var getVideos = function(title) {
      $http.get('/api/my/media/' + encodeURIComponent(title)).success(function(data) {
        angular.extend($scope, data);
        if ($scope.videos) {
          $scope.selectedVideo = $scope.videos[0];
          $scope.youtube = youtubePlayerApi;
          youtubePlayerApi.bindPlayer("player");
          youtubePlayerApi.setVideoId($scope.selectedVideo.id);
          youtubePlayerApi.setVideoTitle($scope.selectedVideo.title);
          youtubePlayerApi.loadPlayer();
          // youtubePlayerApi.launchPlayer($scope.selectedVideo.id, $scope.selectedVideo.title);
        }
      });
    };

    var formatClassTitle = function() {
      var courseDepartment = $scope.selected_course.dept_desc;
      var courseCategory = $scope.selected_course.course_catalog;
      var courseSection = $scope.selected_course.sections[0].section_number;
      var courseSemester = $scope.selectedSemester.name;
      var title = courseDepartment + ' ' + courseCategory + ', ' + courseSection + ' - ' + courseSemester;
      var encodedTitle = title.replace(/\//g, '_slash_');
      getVideos(encodedTitle);
    };

    $scope.launch = function(id, title) {
      // youtubePlayerApi.launchPlayer(id, title);
      youtubePlayerApi.bindPlayer("player");
      youtubePlayerApi.setVideoId(id);
      youtubePlayerApi.setVideoTitle(title);
      youtubePlayerApi.loadPlayer();
      console.log('Launched id:' + id + ' and title:' + title);
    };

    // $scope.youtube = youtubePlayer;
    // console.log(youtubePlayer);
    // $scope.$on('apiReady', function() {
    //   youtubePlayer.loadPlayer();
    // });

    $scope.$watchCollection('[$parent.selected_course.sections, api.user.profile.features.videos]', function(returnValues) {
      if (returnValues[0] && returnValues[1] === true) {
        formatClassTitle();
      }
    });

  });

})(window.angular);
