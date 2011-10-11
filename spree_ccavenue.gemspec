Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_ccavenue'
  s.version     = '1.0.1'
  s.summary     = 'CCAvenue payment gateway support'
  s.description = 'CCAvenue payment gateway support, this code is mostly based on spree_ebsin'
  s.required_ruby_version = '>= 1.8.7'

  s.author            = 'Chandramohan Rangaswamy'
  s.email             = 'chandru@simplelife.in'
  s.homepage          = 'https://github.com/five18pm/spree_ccavenue'
  # s.rubyforge_project = 'actionmailer'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency('spree_core', '>= 0.60.0')
end
