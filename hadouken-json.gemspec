Gem::Specification.new do |s|
  s.name        = 'hadouken-json'
  s.version     = '0.0.1'
  s.summary     = "A tool to create a JSON response right inside of PostgreSQL 9.3+"
  s.description = ""
  s.authors     = ["Roman Zaytsev"]
  s.email       = 'gnemot@gmail.com'
  s.files       = Dir['lib/**/*.rb']
  s.homepage    = 'https://github.com/nemot/hadouken-json'
  s.license     = 'MIT'
  s.add_dependency 'virtus', '~> 1.0.5'
  s.add_runtime_dependency 'activerecord', ['~> 4.0.0', '~> 5.0.0', '~> 6.0.0']
end
