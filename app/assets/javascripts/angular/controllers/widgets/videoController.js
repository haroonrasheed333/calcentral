(function(angular) {
  'use strict';

  /**
   * Video controller
   */
  angular.module('calcentral.controllers').controller('VideoController', function($http, $scope) {

    var getVideos = function(title) {
      $http.get('/api/my/videos/' + encodeURIComponent(title)).success(function(data) {
        angular.extend($scope, data);
        if ($scope.videos) {
          $scope.selectedVideo = $scope.videos[0];
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

    $scope.$watchCollection('[$parent.selected_course.sections, api.user.profile.features.videos]', function(returnValues) {
      if (returnValues[0] && returnValues[1] === true) {
        formatClassTitle();
      }
    });

  });

})(window.angular);
