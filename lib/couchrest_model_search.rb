require 'couchrest_model'

module CouchRest
  module Model
    module DesignDoc
      module ClassMethods
        alias_method :orig_default_design_doc, :default_design_doc
        def default_design_doc          
          orig_default_design_doc.update "fulltext" => 
            { "by_fulltext" => {
                "index" => %(
                  function(doc) {
                    var ret = new Document();
                    function idx(obj) {
                      for (var key in obj){
                        switch (typeof obj[key]) {
                          case 'object':
                            idx(obj[key]);
                            break;
                          case 'function':
                            break;
                          default:
                            ret.add(obj[key]);
                            break;
                        }
                      }
                    };

                    if (doc['couchrest-type'] == '#{self.to_s}') {
                      idx(doc);

                      if (doc._attachments) {
                        for (var i in doc._attachments) {
                          ret.attachment('attachment', i);
                        }
                      }
                    }
                    return ret;
                  }
                )
              }
            }
        end
        
        def update_search_doc
          saved = stored_design_doc
          if saved && saved["fulltext"] != design_doc["fulltext"]
            saved["fulltext"] = design_doc["fulltext"]
            saved.save
            saved
          elsif !saved
            design_doc.delete("_rev")
            design_doc.database = database
            design_doc.save
            design_doc
          end
        end
        
        alias_method :orig_save_design_doc, :save_design_doc
        def save_design_doc(db = database, force = false)
          orig_save_design_doc(db, force)
          update_search_doc
        end
      end
    end
  end
end

module CouchRest
  module Search
    module Escape
      def escape_special_characters(query)
        new_query = query.dup
        lucene_special_characters.map {|c| new_query.gsub!(c, %{\\} + c)}
        new_query
      end

      def lucene_special_characters
        @lucene_special_characters ||= %w[\ + - && || ! ( ) { } [ ] ^ " ~ * ? :]
      end
    end
  end
end

class CouchRest::Database
  include CouchRest::Search::Escape

  def search(klass, view_fn, query, options={})
    url = CouchRest.paramify_url("#{@root}/_fti/_design/#{klass}/#{view_fn}", options.merge(:q => query))
    ActiveSupport::Notifications.instrument("search.lucene",
                                                :query => url) do
      CouchRest.get url
    end
  end

  def escaped_search(klass, view_fn, query, options={})
    search klass, view_fn, escape_special_characters(query), options
  end
end

class CouchRest::Model::Base
  class << self
    include CouchRest::Search::Escape

    def search(query, view_fn="by_fulltext", options={})
      options[:include_docs] = true
      ret = self.database.search(self.to_s, view_fn, query, options)
      ret['rows'].map {|r| self.new(r['doc'])}
    end

    def escaped_search(query, view_fn="by_fulltext", options={})
      self.search escape_special_characters(query), view_fn, options
    end
  end
  
  # example search functions
  #   class Aritlce
  #     search_by :title,
  #       :index => %(
  #         function(doc) {
  #           // ....
  #         }
  #       )
  #
  # now you can make search like
  #   Article.search "apple"   # by default it uses "by_fulltext" search function      
  #   Article.search "apple", :by_title       
  def self.search_by(fn_name, fn)
    design_doc["fulltext"] ||= {}
    design_doc["fulltext"]["by_#{fn_name}"] = fn.stringify_keys!
    req_design_doc_refresh
  end
end


# see http://gist.github.com/566725 on how to use ActiveSupport logging
class CouchRestModelSearchLogger < ActiveSupport::LogSubscriber
  def search(event)
    name = '%s (%.1fms)' % ["Couchdb-lucene Query", event.duration]
    url = event.payload[:query]
    info "  #{color(name, YELLOW, true)}  [ #{url} ]"
  end
end

CouchRestModelSearchLogger.attach_to :lucene
