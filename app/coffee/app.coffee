

# define our app
@nsa = nsa = {}


configure = ($routeProvider, $locationProvider) -> 
  $routeProvider.when('/',
      {templateUrl: '/partials/dashboard.html'})