@include = ->
  models = @models

  @get "/users", @myAuth, ->
    if @req.user
      models.Users.findOne {identifier: @req.user.identifier}, (err, user)=>
        if err
          @next err
        else
          @json user
    else
      @res.send 401
