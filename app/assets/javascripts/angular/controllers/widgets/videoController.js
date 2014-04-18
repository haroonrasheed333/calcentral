(function(angular) {
  'use strict';

  /**
   * Video controller
   */
  angular.module('calcentral.controllers').controller('VideoController', function($http, $scope, youtubePlayer) {

    var getVideos = function(title) {
      $http.get('/api/my/media/' + encodeURIComponent(title)).success(function(data) {
        angular.extend($scope, data);
        if ($scope.videos) {
          $scope.selectedVideo = $scope.videos[0];
          console.log($scope.selectedVideo);
          $scope.youtube = youtubePlayer;
          youtubePlayer.playerId = "player";
          youtubePlayer.videoId = $scope.selectedVideo.id;
          youtubePlayer.loadPlayer();
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
