(function(calcentral) {
  'use strict';

  /**
   * Splash controller
   */
  calcentral.controller('CaloneController', ['$http', '$scope', 'apiService', function($http, $scope, apiService) {

    apiService.util.setTitle('Food and Housing');

    $http.get('/dummy/json/calone.json').success(function(data) {
      $scope.balance = data.calone.balance;
    });

  }]);

})(window.calcentral);