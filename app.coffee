config = require 'config'

require('zappajs').run config.env.port, config.env.host, ->
  {CronJob} = require 'cron'
  @mongoose = require 'mongoose'
  @mongoose.connect 'mongodb://localhost/reader'

  passport = require 'passport'
  GoogleStrategy = require('passport-google').Strategy;

  passport.serializeUser (user, done)->
    done null, user

  passport.deserializeUser (obj, done)->
    done null, obj

  passport.use new GoogleStrategy({
      returnURL: "http://#{config.env.host}:#{config.env.port}/auth/google/return"
      realm: "http://#{config.env.host}:#{config.env.port}/"
    },
    (identifier, profile, done)=>
      @models.Users.findOne {identifier: identifier}, (err, user)=>
        if err
          done err, null
        else
          if !user
            user = new @models.Users()
            user.displayName = profile.displayName
            user.feeds = [] 
            user.identifier = identifier
            user.save (err)->
              done err, user
          else
            if user.feeds?
              done null, user
            else
              user.feeds = []
              user.save (err)->
                done err, user
  )

  @myAuth = ->
    if @req.user
      @next()
    else
      @res.send 401
 
  @configure =>
    @use 'methodOverride', 'bodyParser', 'cookieParser', session: {secret: 'foo'}, passport.initialize(), passport.session(), 'static'
    @set 'view engine': 'jade', views: "#{__dirname}/views"

  @include "utils"
  @include "models"
  @include "client"

  @get '/auth/google': passport.authenticate('google')

  @get '/auth/google/return', passport.authenticate('google', failureRedirect: '/'), ->
    @res.redirect '/'

  @get '/auth/logout':->
    @req.logout()
    @res.redirect '/'

  @get '/': ->
    @render index:{}
    
  # 30分ごとに監視
  cronTime = "*/30 * * * *"
  
  job = new CronJob(
    cronTime: cronTime
    onTick: =>
      @models.Feeds.find({}, (err, feeds)=>
        if err
          console.log err
          return
        for feed in feeds
          do (feed)=>
            @utils.FeedUtils.get_articles feed, (err, articles)=>
              if err
                console.log err
                return
              for item in articles
                article = new @models.Articles()
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
      )
      console.log 'tick'
    onComplete: ->
      console.log "complete"
    start: false
    timeZone: "Japan/Tokyo"
  )
  
  job.start()

