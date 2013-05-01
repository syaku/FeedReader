FeedParser = require 'feedparser'
request = require 'request'

@include = ->
  utils = @utils
  
  mongoose = @mongoose
  Schema = @mongoose.Schema
  ObjectId = Schema.ObjectId

  SiteSchema = new Schema
    title: String
    url: {type:String, required: true, unique:true}

  Sites = @mongoose.model('Site', SiteSchema)
  @models = @models||{}
  @models.Sites = Sites

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
    Sites.findOne({url:@req.param('url')}).exec (err, site)=>
      if err
        @next err
      else
        ((callback)=>
          if site
            callback({title: site.title, site: site._id})
          else
            site = new Sites({title: "no title.", url:@req.param('url')})
            utils.FeedUtils.get_articles(site, (err, articles, site)=>
              if err
                @next err
              else
                site.save (err)=>
                  if err
                    @next(err)
                  else
                    Articles = mongoose.model('Article')
                    for item in articles
                      article = new Articles()
                      article.site = site._id
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
                    callback({title: site.title, site: site._id})
            )
          )((new_feed)=>
            models.Users.findOne({identifier: @req.user.identifier}).exec (err, user)=>
              feed = new models.UserFeeds()
              feed.title = new_feed.title
              feed.site = new_feed.site
              user.feeds.push feed
              user.save (err)=>
                if err
                  @next err
                else
                  @json new_feed
         )

  @get "/sites/:site", @myAuth, ->
    Sites.findById @req.param("site"), (err, site)=>
      if err
        @next err
      else
        if site?
          @json(site)
        else
          @send(404)
