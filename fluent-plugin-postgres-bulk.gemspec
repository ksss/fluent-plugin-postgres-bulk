Gem::Specification.new do |gem|
  gem.name          = "fluent-plugin-postgres-bulk"
  gem.version       = "0.0.1"
  gem.authors       = ["ksss"]
  gem.email         = ["co000ri@gmail.com"]
  gem.description   = %q{fluent plugin for bulk insert to postgres}
  gem.summary       = %q{fluent plugin for bulk insert to postgres}
  gem.homepage      = "https://github.com/ksss/fluent-plugin-postgres-bulk"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency "fluentd", ['>= 0.14.8', '< 2']
  gem.add_runtime_dependency "pg"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "test-unit"
end
