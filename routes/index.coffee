@include = ->

  @get '/auth/google': @passport.authenticate('google')

  @get '/auth/google/return', @passport.authenticate('google', failureRedirect: '/'), ->
    @res.redirect '/'

  @get '/auth/logout':->
    @req.logout()
    @res.redirect '/'

  @get '/': ->
    @render index:{}

  @include 'routes/users'
  @include 'routes/feeds'
  @include 'routes/articles'
