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
      end
    end
  end
end

class CouchRest::Database
  def search(klass, view_fn, query, options={})
    url = CouchRest.paramify_url("#{@root}/_fti/_design/#{klass}/#{view_fn}", options.merge(:q => query))
    ActiveSupport::Notifications.instrument("search.lucene",
                                                :query => url) do
      CouchRest.get url
    end
  end
end

class CouchRest::Model::Base
  def self.search(query, view_fn="by_fulltext", options={})
    options[:include_docs] = true
    ret = self.database.search(self.to_s, view_fn, query, options)
    ret['rows'].map {|r| self.new(r['doc'])}
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
  end
  
  def self.update_search_doc
    saved = stored_design_doc
    if saved
      saved["fulltext"] = design_doc["fulltext"]
      saved.save
      saved
    else
      design_doc.delete("_rev")
      design_doc.database = database
      design_doc.save
      design_doc
    end
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
