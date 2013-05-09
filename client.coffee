@include = ->
  @client "/js/main.js":->
    FeedReader = ()->
      self = this

      @user = {
        displayName: ko.observable(null)
        feeds: ko.observableArray([])
        deleteFeed: (data, event)->
          $.ajax {type: 'DELETE', url: "/sites/#{encodeURIComponent(data._id)}", dataType: 'json', success: (user, status)=>
            console.log status
            feeds = self.user.feeds()
            for feed, index in feeds
              if feed._id == data._id
                feeds.splice(index, 1)
                self.user.feeds(feeds)
                return
          }
      }
      @items = ko.observableArray(null)
        
      $.ajax {type: 'GET', url: '/users', dataType: 'json', success: ((user, status)=>
       self.user.displayName(user.displayName)
       self.user.feeds(user.feeds)
      ),error: ((req, status, err)=>
      )}

      @new_feed =
        url: ko.observable('')
        title: ko.observable('')

      @addFeed = =>
        data =
          url: @new_feed.url()
          title: @new_feed.title()

        $.post '/sites', data, (result, status)=>
          @user.feeds.push result
        
        $('#add-feed').modal('hide')

      @selectFeed = (id)->
        $.getJSON '/articles', {site:id}, (articles)->
          for article in articles
            article.date = new Date(article.date)
            article.selected = ko.observable(false)
            article.selected.subscribe ((selected)->
              if selected
                this.read(true)
            ), article
            article.read = ko.observable(false)
          self.items(articles)
      
      @selectArticle = (article)-> 
        for item in self.items()
          if item._id == article._id
            article.selected(!article.selected())
          else
            item.selected(false)

      self

    feedReader = new FeedReader()

    @get "#/": ->
      feedReader.selectFeed(null)
      $('html, body').animate {scrollTop: 0}, {queue: false}

    @get "#/feed/:site": ->
      feedReader.selectFeed(@params.site)
      $('html, body').animate {scrollTop: 0}, {queue: false}

    $ ->
      $("#sidenav").affix()

      $('html').keydown (e)->
        if e.keyCode == 32
          items = feedReader.items()
          for item, i in items
            if item.selected()
              item.selected(false)
              if i < items.length-1
                items[i+1].selected(true)
                target = $("##{items[i+1]._id}")
                $('html, body').animate(
                  {scrollTop: target.offset().top - 60}
                  {queue: false}
                )
              return false

          items[0].selected(true)
          $('html, body').animate(
            {scrollTop: $("##{items[0]._id}").offset().top - 60}
            {queue: false}
          )
          return false

      ko.applyBindings(feedReader)

    @connect()
