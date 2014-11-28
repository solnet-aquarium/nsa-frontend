

# define our app
@nsa = nsa = {}


configure = ($routeProvider, $locationProvider) -> 
  $locationProvider.html5Mode(true);
  $routeProvider.when('/',
      {templateUrl: '/partials/dashboard.html'})



init = ($log, $i18n, $config) ->


modules = [
  'ngRoute',
  'ngAnimate'
]

module = angular.module("nsa", modules)

module.config([
    "$routeProvider",
    "$locationProvider",
    "$httpProvider",
    "$provide",
    configure
])

module.run([
    "$log",
    "$rootScope",
    init
])