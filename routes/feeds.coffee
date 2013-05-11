@include = ->
  utils = @utils
  
  models = @models

  @get "/feeds", @myAuth, ->
    if @req.user
      models.Users.findOne {identifier: @req.user.identifier}, (err, user)=>
        if err
          @next err
        else
          @json user.feeds
    else
      @res.send 401

  @post "/feeds", @myAuth, ->
    models.Feeds.findOne {url:@req.param('url')}, (err, feed)=>
      if err
        @next err
      else
        ((callback)=>
          if feed
            callback(feed)
          else
            feed = new models.Feeds({title: "no title.", url: @req.param('url')})
            utils.FeedUtils.get_articles(feed, (err, articles, feed)=>
              if err
                @next err
              else
                feed.save (err)=>
                  if err
                    @next(err)
                  else
                    for item in articles
                      article = new models.Articles(item)
                      article.feed = feed._id
                      if item.date
                        article.date = item.date
                      else
                        article.date = item.meta.date
                      article.save()
                    callback(feed)
            )
          )((new_feed)=>
            models.Users.findOne({identifier: @req.user.identifier}).exec (err, user)=>
              user.feeds.push new_feed
              user.save (err)=>
                if err
                  @next err
                else
                  @json new_feed
         )

  @del "/feeds/:feed", @myAuth, ->
    models.Users.findOne {identifier: @req.user.identifier}, (err, user)=>
      user.feeds.id(@req.param("feed")).remove()
      user.save (err)=>
        if err 
          @next err
        else
          @json user

  @get "/feeds/:feed", @myAuth, ->
    models.Feeds.findById @req.param("feed"), (err, feed)=>
      if err
        @next err
      else
        if feed?
          @json(feed)
        else
          @send(404)
