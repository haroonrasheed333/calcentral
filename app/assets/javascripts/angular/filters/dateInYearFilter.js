(function(angular) {
  'use strict';

  angular.module('calcentral.filters').filter('cc.dateInYear', function(dateService, $filter) {
    return function(millisecondsEpoch, currentYearFormat, otherYearFormat) {
      var isCurrentYear = dateService.moment().format('YYYY') === dateService.moment(millisecondsEpoch).format('YYYY');
      var standardDateFilter = $filter('date');
      currentYearFormat = currentYearFormat || 'MM/dd';
      otherYearFormat = otherYearFormat || 'MM/dd/yyyy';

      if (isCurrentYear) {
        return standardDateFilter(millisecondsEpoch, currentYearFormat);
      } else {
        return standardDateFilter(millisecondsEpoch, otherYearFormat);
      }
    };
  });
}(window.angular));
