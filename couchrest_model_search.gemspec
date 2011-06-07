Gem::Specification.new do |s|
  s.name = %q{couchrest_model_search}
  s.version = File.read "VERSION"

  s.authors = ["Dorren Chen", "Matt Parker"]
  s.date = %q{2010-10-18}
  s.description = %q{Add couchdb-lucene search support to CouchRest Model}
  s.email = %q{dorrenchen@gmail.com}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.markdown"
  ]
  
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  #s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  
  s.homepage = %q{http://github.com/dorren/couchrest_model_search}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.summary = %q{Add couchdb-lucene search support to CouchRest Model}

  s.add_dependency "couchrest_model", ["~> 1.0.0"]
  s.add_development_dependency "rspec", ["~> 2.0"]
  s.add_development_dependency "cucumber", ["~> 0.0"]
end

