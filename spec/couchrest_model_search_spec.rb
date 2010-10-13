require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "CouchrestModelSearch" do
  class Article < CouchRest::Model::Base
  end
  
  it "should overwrite default_design_doc" do
    Article.design_doc["fulltext"].should_not be_nil
  end
end

describe "CouchrestModelSearch" do  
  class CustomArticle < CouchRest::Model::Base
    def self.fulltext
      { "by_content" => {"index" => %(function(doc) {})}}
    end
  end
  
  it "should allow class to overwrite fulltext function" do
    CustomArticle.design_doc["fulltext"].should == CustomArticle.fulltext
  end
end
