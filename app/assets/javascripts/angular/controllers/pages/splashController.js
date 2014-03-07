(function(angular) {
  'use strict';

  /**
   * Splash controller
   */
  angular.module('calcentral.controllers').controller('SplashController', function($http, $scope, apiService) {

    apiService.util.setTitle('Home');

    $http.get('/api/blog/release_notes/latest').success(function(data) {
      $scope.latestReleaseNote = data.entries[0];
    });

  });

})(window.angular);
