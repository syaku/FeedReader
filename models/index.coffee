mongooseTypes = require 'mongoose-types'
@include = ->
  utils = @utils
  
  mongoose = @mongoose
  mongooseTypes.loadTypes(mongoose)

  Schema = @mongoose.Schema
  ObjectId = Schema.ObjectId
  Url = mongoose.SchemaTypes.Url

  FeedSchema = new Schema
    _id: {type:String, required: true, unique:true}
    title: String

  UserSchema = new Schema(
    identifier: {type: String, unique: true}
    displayName: String
    feeds: [FeedSchema]
  )

  ArticleSchema = new Schema
    feedUrl: {type:String, index:true}
    meta: {title: String, link: String}
    title: String
    author: String
    link: String
    description: String
    guid: {type:String, unique:true}
    date: Date

  ArticleSchema.static 'findByFeeds', (feeds, callback)->
    this.where('feedUrl').in(feeds).sort('-date').limit(100).exec callback

  @models = @models||{}
  @models.Users = @mongoose.model('Users', UserSchema)
  @models.Feeds = @mongoose.model('Feeds', FeedSchema)
  @models.Articles = @mongoose.model('Articles', ArticleSchema)

  @include "models/user"
  @include "models/site"
  @include "models/article"
