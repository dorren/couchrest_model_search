require 'couchrest_model'

module CouchRest
  module Model
    module DesignDoc
      module ClassMethods
        # the default search function
        def fulltext
          { "by_content" => {
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
    
        alias_method :orig_default_design_doc, :default_design_doc
        def default_design_doc          
          orig_default_design_doc.merge "fulltext" => fulltext
        end
      end
    end
  end
end

class CouchRest::Database
  def search(klass, view_fn, query, options={})
    CouchRest.get CouchRest.paramify_url("#{@root}/_fti/_design/#{klass}/#{view_fn}", options.merge(:q => query))
  end
end

class CouchRest::Model::Base
  def self.search(view_fn, query, options={})
    options[:include_docs] = true
    ret = self.database.search(self.to_s, view_fn, query, options)
    ret['rows'].map {|r| self.new(r['doc'])}
  end
  
  def self.update_search_doc
    dbdoc = database.get '_design/#{self.to_s}'
    dbdoc.update design_doc
    dbdoc.save
  end
end

