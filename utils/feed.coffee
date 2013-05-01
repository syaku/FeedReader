FeedParser = require 'feedparser'
request = require 'request'

@include =->
  @utils = @utils||{}
  @utils.FeedUtils =
    get_articles: (site, callback)=>
      articles = []
      request(site.url)
        .pipe(new FeedParser())
        .on('error', (err)->
          callback(err)
        )
        .on('meta', (meta)->
          site.title = meta.title
        )
        .on('article', (article)->
          articles.push article
        )
        .on('end', ->
          callback(null, articles, site)
        )
