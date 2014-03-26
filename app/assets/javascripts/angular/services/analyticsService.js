(function(angular) {

  'use strict';

  angular.module('calcentral.services').service('analyticsService', function($rootScope, $window, $location) {

    /**
     * Send an analytics event
     * @param {String} category e.g. Video
     * @param {String} action e.g. Play
     * @param {String} label e.g. Flying to Belgium
     * More info on https://developers.google.com/analytics/devguides/collection/analyticsjs/events
     */
    var sendEvent = function(category, action, label) {
      if ($window && $window.ga) {
        $window.ga('send', 'event', category, action, label);
      }
    };

    /**
     * Track when there is an external link being clicked
     * @param {String} section The section you're currently in (e.g. Up Next / My Classes / Activity)
     * @param {String} website The website you're trying to access (Google Maps)
     * @param {String} url The URL you're accessing
     */
    var trackExternalLink = function(section, website, url) {
      sendEvent('External link', url, 'section: ' + section + ' - website: ' + website);
    };

    /**
     * This will track the the page that you're viewing
     * e.g. /, /dashboard, /settings
     */
    var trackPageview = function() {
      sendEvent('pageview', $location.path());
    };

    // Whenever we're changing the content loaded, we need to track which page we're viewing.
    $rootScope.$on('$viewContentLoaded', trackPageview);

    // Expose methods
    return {
      sendEvent: sendEvent,
      trackExternalLink: trackExternalLink
    };

  });

}(window.angular));
