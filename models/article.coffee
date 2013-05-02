_ = require 'underscore'

@include = ->
  models = @models

  @get '/articles', @myAuth,  ->
    if @req.param('site')
      feeds = [@req.param('site')]
      models.Articles.findByFeeds feeds, (err, articles)=>
        if err
          @next err
        else
          @json articles
    else
      models.Users.findOne({identifier: @req.user.identifier}).exec (err, user)=>
        feeds = _.map user.feeds, (item)->
          item._id
        console.log feeds
        models.Articles.findByFeeds feeds, (err, articles)=>
          if err
            @next err
          else
            @json articles

  @get '/articles/:article', @myAuth, ->
    models.Articles.findById @req.param('article'), (err, article)=>
      if err
        @next err
      else
        @json(article)
