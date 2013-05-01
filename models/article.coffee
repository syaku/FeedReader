_ = require 'underscore'

@include = ->
  Schema = @mongoose.Schema
  ObjectId = Schema.ObjectId

  ArticleSchema = new Schema
    site: {type:ObjectId, index:true}
    meta: {title: String, link: String}
    title: String
    author: String
    link: String
    description: String
    guid: {type:String, unique:true}
    date: Date

  ArticleSchema.static 'findByFeeds', (feeds, callback)->
    this.where('site').in(feeds).sort('-date').limit(100).exec callback

  Articles = @mongoose.model('Article', ArticleSchema)

  @models = @models||{}
  @models.Articles = Articles
  models = @models

  @get '/articles', @myAuth,  ->
    if @req.param('site')
      feeds = [@req.param('site')]
      Articles.findByFeeds feeds, (err, articles)=>
        if err
          @next err
        else
          @json articles
    else
      models.Users.findOne({identifier: @req.user.identifier}).exec (err, user)=>
        feeds = _.map user.feeds, (item)->
          item.site
        Articles.findByFeeds feeds, (err, articles)=>
          if err
            @next err
          else
            @json articles

  @get '/articles/:article', @myAuth, ->
    Articles.findById @req.param('article'), (err, article)=>
      if err
        @next err
      else
        @json(article)
