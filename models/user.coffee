@include = ->
  Schema = @mongoose.Schema
  ObjectId = Schema.ObjectId

  UserFeedSchema = new Schema(
    site: {type:ObjectId, required:true}
    title: {type:String, required:true}
  )

  UserSchema = new Schema(
    identifier: {type: String, unique: true}
    displayName: String
    feeds: [UserFeedSchema]
  )

  @models = @models||{}
  @models.Users = @mongoose.model('Users', UserSchema)
  @models.UserFeeds = @mongoose.model('UserFeeds', UserFeedSchema)
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
