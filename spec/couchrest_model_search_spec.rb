require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

class Article < CouchRest::Model::Base
  use_database DB
end

describe "CouchrestModelSearch" do  
  before :each do
    if doc = Article.stored_design_doc
      doc.database = Article.database
      doc.destroy
    end
  end
  
  it "should overwrite default_design_doc" do
    Article.design_doc["fulltext"].should_not be_nil
  end  
end

describe "CouchRest::Model::Base##escaped_search" do
  it "should escape the first parameter, then pass all args off to the search method" do
    Article.should_receive(:search).with('hello\:there', "by_fulltext", {}).and_return nil
    Article.escaped_search "hello:there"
  end
end

describe "CouchRest::Database##escaped_search" do
  it "should escape the third parameter, then pass all args off to the search method" do
    Article.database.should_receive(:search).with(Article, "by_fulltext", 'hello\:there', {}).and_return nil
    Article.database.escaped_search Article, "by_fulltext", "hello:there"
  end
end
  
describe "overwrite design doc" do  
  class CustomArticle < CouchRest::Model::Base
    use_database DB
    search_by :fulltext,
              {:index => %(function(doc) {})}
  end
   
  before :each do
    if doc = CustomArticle.stored_design_doc
      doc.database = CustomArticle.database
      doc.destroy
    end
  end
  
  it "should allow class to overwrite fulltext function" do
    CustomArticle.update_search_doc
    CustomArticle.stored_design_doc["fulltext"]["by_fulltext"]["index"].should ==  %(function(doc) {})
  end
  
  it "should update search doc" do
    CustomArticle.update_search_doc
    CustomArticle.stored_design_doc["fulltext"]["by_fulltext"]["index"].should ==  %(function(doc) {})
    
    class CustomArticle < CouchRest::Model::Base
      use_database DB
      search_by :fulltext,
                {:index => %(function(doc) {// hello})}
    end
    
    CustomArticle.update_search_doc
    CustomArticle.stored_design_doc["fulltext"]["by_fulltext"]["index"].should == %(function(doc) {// hello})
  end
end
