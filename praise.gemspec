Gem::Specification.new do |s|

  s.name             = 'praise'
  s.version          = '0.0.2'
  s.date             = '2013-05-14'
  s.summary          = 'Intercepts raise calls'
  s.description      = 'A small gem for intercepting raise calls to dig up hidden and buried exceptions.'
  s.authors          = ['Petr Chalupa']
  s.email            = 'git@pitr.ch'
  s.homepage         = 'https://github.com/pitr-ch/praise'
  s.extra_rdoc_files = %w(MIT-LICENSE README.md README_FULL.md)
  s.files            = Dir['lib/praise.rb']
  s.require_paths    = %w(lib)
  s.license          = 'MIT'
  s.test_files       = Dir['spec/praise.rb']

  { 'pry'                => nil,
    'pry-stack_explorer' => nil
  }.each do |gem, version|
    s.add_runtime_dependency(gem, [version || '>= 0'])
  end

  { 'minitest' => nil,
    'pry'      => nil,
    'yard'     => nil,
    'kramdown' => nil,
  }.each do |gem, version|
    s.add_development_dependency(gem, [version || '>= 0'])
  end
end

