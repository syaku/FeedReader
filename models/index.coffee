@include = ->
  mongoose = @mongoose

  Schema = @mongoose.Schema
  ObjectId = Schema.ObjectId

  FeedSchema = new Schema
    url: {type:String, required: true, unique:true}
    title: String

  UserSchema = new Schema(
    identifier: {type: String, unique: true}
    displayName: String
    feeds: [FeedSchema]
  )

  ArticleSchema = new Schema
    feed: {type:ObjectId, index:true}
    meta: {title: String, link: String}
    title: String
    author: String
    link: String
    description: String
    guid: {type:String, unique:true}
    date: {type:Date, index:true}

  ReadSchema = new Schema
    user: {type:ObjectId, index:true}
    feed: {type:ObjectId, index:true}
    article: {type:ObjectId, index:true}

  ArticleSchema.statics.findByFeeds = (feeds, callback)->
    this.where('feed').in(feeds).sort('-date').limit(100).exec callback
    
  ArticleSchema.statics.read = (user,feed,article, callback)=>
    ReadSchema.findOne({user:user, feed:feed, article:article}).exec (err, read)=>
      if err
        callback(err)
      else
        if !read
          read = new @models.Reads({user:user, feed:feed, article:article})
          read.save (err)->
            callback(err)

  @models = @models||{}
  @models.Users = @mongoose.model('Users', UserSchema)
  @models.Feeds = @mongoose.model('Feeds', FeedSchema)
  @models.Articles = @mongoose.model('Articles', ArticleSchema)
  @models.Reads = @mongoose.model('Reads', ReadSchema)
