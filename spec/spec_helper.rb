$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'couchrest_model_search'
require 'rspec'
require 'rspec/autorun'

COUCHDB_SERVER  = CouchRest.new "http://admin:password@localhost:5984"
DB         = COUCHDB_SERVER.database!('couchrest_model_search_test')

RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec
end
