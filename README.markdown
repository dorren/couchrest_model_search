# couchrest_model_search

Search integration for `couchrest_model` users that are using couchdb-lucene. 

## Install

    $ gem install couchrest_model_search
  
## Usage

By simply requiring 'couchrest_model_search' in your project, all of your `CouchRest::Model::Base` models will respond to a `search` class method. This method will, by default, perform a full-text search on your model for any query you pass to it. 

For example, suppose we have defined the following model:

    class Article < CouchRest::Model::Base
      property :title
      property :author
      property :body
    end

And now, let's create some articles:

    Article.create(
      :title => "CouchDB is fun!", 
      :author => "moonmaster9000", 
      :body => "CouchDB is the most fun EVAR."
    )

    Article.create(
      :title => "CouchDB Lucene FTW", 
      :author => "moonmaster9000", 
      :body => "CouchDB Lucene makes your documents easily searchable!"
    )

    Article.create(
      :title => "Search your CouchDB documents from Ruby", 
      :author => "dorren", 
      :body => "Use the couchrest_model_search gem to search your documents from Ruby."
    )

If we searched for "CouchDB", we would receive all documents we've created, since they all contained the word "CouchDB" in one of the properties:

    Article.search("CouchDB").map(&:title) 
      #==> ["CouchDB is fun!", "CouchDB Lucene FTW", "Search your CouchDB documents from Ruby"]

Of course, searching for "moonmaster9000" would only return the first two documents:

    Article.search("moonmaster9000").map(&:title) 
      #==> ["CouchDB is fun!", "CouchDB Lucene FTW"]


### Creating more search functions

By default, the `search` method will use an underlying fulltext search index function to query your content. You can override the definition of this default "fulltext" search index function via the `search_by` class method:

    class Article < CouchRest::Model::Base
      property :title
      property :author
      property :body

      search_by :fulltext, 
        :index => %(
          function(doc){
            //... your code here
          }
        )
    end

You can also create other search indexes. For example, suppose we'd like to index only the titles of articles for search:


    class Article < CouchRest::Model::Base
      property :title
      property :author
      property :body

      search_by :title, 
        :index => %(
          function(doc){
            var contentToIndex = new Document();
            contentToIndex.add(doc.title);
            return contentToIndex;
          }
        )
    end

Now, to perform a search by title (instead of a fulltext search), simply pass `:by_title` along with your query to the `search` method:

    Article.search "some query", :by_title

### CouchDB-Lucene Query options

You can pass any CouchDB-Lucene query options to your search via an optional third parameter to search:

    Article.search "apples", :fulltext, :limit => 10


### Escaping special characters

The following characters have special meaning to Lucene when added to a query:

    + - && || ! ( ) { } [ ] ^ " ~ * ? : \

By default, `couchrest_model_search` will not escape your query. If you want it to automatically escape these special characters in your query, then use the `escaped_search` method:

    Article.escaped_search "2001:March:10"
