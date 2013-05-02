@include = ->
  utils = @utils
  
  models = @models

  @get "/sites", @myAuth, ->
    if @req.user
      models.Users.findOne {identifier: @req.user.identifier}, (err, user)=>
        if err
          @next err
        else
          @json user.feeds
    else
      @res.send 401

  @post "/sites", @myAuth, ->
    console.log @req.param('url')
    models.Feeds.findById @req.param('url'), (err, feed)=>
      if err
        @next err
      else
        ((callback)=>
          if feed
            callback(feed)
          else
            feed = new models.Feeds({title: "no title.", _id: @req.param('url')})
            utils.FeedUtils.get_articles(feed, (err, articles, feed)=>
              if err
                @next err
              else
                feed.save (err)=>
                  if err
                    @next(err)
                  else
                    for item in articles
                      article = new models.Articles()
                      article.feedUrl = feed._id
                      article.meta = {}
                      article.meta.title = item.meta.title
                      article.meta.link = item.meta.link
                      article.title = item.title
                      article.author = item.author
                      article.link = item.link
                      article.description = item.description
                      article.guid = item.guid
                      if item.date
                        article.date = item.date
                      else
                        article.date = item.meta.date
                      article.save()
                    callback(feed)
            )
          )((new_feed)=>
            models.Users.findOne({identifier: @req.user.identifier}).exec (err, user)=>
              feed = new models.Feeds()
              feed.title = new_feed.title
              feed._id = new_feed._id
              user.feeds.push feed
              user.save (err)=>
                if err
                  @next err
                else
                  @json new_feed
         )

  @get "/sites/:feed", @myAuth, ->
    models.Feeds.findById @req.param("feed"), (err, feed)=>
      if err
        @next err
      else
        if feed?
          @json(feed)
        else
          @send(404)
