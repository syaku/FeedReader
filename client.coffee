@include = ->
  @client "/js/main.js":->
    class FeedReader
      constructor: ->
        @user = {
          displayName: ko.observable(null)
          feeds: {}
          feedKeys: ko.observableArray()
          deleteFeed: (data, event)=>
            $.ajax {type: 'DELETE', url: "/feeds/#{encodeURIComponent(data)}", dataType: 'json', success: (user, status)=>
              keys = @user.feedKeys()
              index = $.inArray(data, keys)
              @user.feedKeys.splice(index, 1)
            }
        }
        
        @selectedArticle = null
        @articleKeys = ko.observableArray()
        @articles = {}

        @new_feed =
          url: ko.observable('')
          title: ko.observable('')
        
        $.ajax {type: 'GET', url: '/users', dataType: 'json', success: ((user, status)=>
          @user.displayName(user.displayName)
          for feed in user.feeds
            @user.feeds[feed._id] = feed
            @user.feedKeys.push feed._id

        ),error: (req, status, err)=>
        }
      
      addFeed: =>
        data =
          url: @new_feed.url()
          title: @new_feed.title()
        $.post '/feeds', data, (result, status)=>
          @user.feeds.push result
        $('#add-feed').modal('hide')

      selectFeed: (id, event)->
        $.getJSON '/articles', {site:id}, (articles)=>
          @articleKeys([])
          @selectedArticle = null
          for article in articles
            article.date = new Date(article.date)
            article.selected = ko.observable(false)
            article.selected.subscribe ((selected)->
              if selected
                this.read(true)
            ), article
            article.read = ko.observable(false)
            @articles[article._id] = article
            @articleKeys.push article._id

          $('html, body').animate {scrollTop: 0}, {queue: false}

      selectArticle: (key)=>
        $('.accordion-body').hide()
        $("##{key} .accordion-body").show()
        @articles[key].selected(true)
        @selectedArticle = key

      onKeypress: (sender, event)->
        switch event.keyCode
          when 32
            keys = @articleKeys()
            if @selectedArticle
              index = $.inArray(@selectedArticle, keys)
              key = keys[index+1]
            
            if !key
              key = keys[0]
            @selectArticle(key)

            $('html, body').animate(
              {scrollTop: $("##{key}").offset().top - 60}
              {queue: false}
            )
            return false

    feedReader = new FeedReader()

    @get "#/": ->
      feedReader.selectFeed(null)
  
    @get "#/feed/:feed": ->
      feedReader.selectFeed(@params.feed)

    @get "#/feed/new/:url": ->
      $.post '/feeds', {url:@params.url}, (feed, status)->
        feedReader.user.feeds[feed._id] = feed
        feedReader.user.feedKeys.push(feed._id)
        feedReader.selectFeed(feed._id)

    $ ->
      $("#sidenav").affix()
      ko.applyBindings(feedReader)

    @connect()
