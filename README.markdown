# couchrest_model_search

Search integration for `couchrest_model` users that are using couchdb-lucene. 

## Install

    $ gem install couchrest_model_search
  
## Usage

    class Article < CouchRest::Model::Base
    end

    @articles = Article.search "apple"  # search by keyword apple
    
    # you can also customize the search function.
    class CustomArticle < CouchRest::Model::Base
      search_by :fulltext,
                :index => %(
                   function(doc) {
                     // ....
                   }
                )
    end
