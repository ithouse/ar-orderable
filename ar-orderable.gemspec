# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "ar-orderable"
  s.version     = '1.0.4'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["ITHouse (Latvia)", "Gatis Tomsons"]
  s.email       = "support@ithouse.lv"
  s.homepage    = "http://github.com/ithouse/ar-orderable"
  s.summary = %q{You can order AR records and skip callbacks}

  s.extra_rdoc_files = [
    "README.md"
  ]
  s.licenses = ["MIT"]

  s.add_runtime_dependency(%q<activerecord>, [">= 3.0", "< 4.0"])
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]
end
