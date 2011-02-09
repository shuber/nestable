require 'date'
require 'lib/nestable/version'

Gem::Specification.new do |s| 
  s.name    = 'nestable'
  s.version = Nestable::Version.string
  s.date    = Date.today.to_s

  s.summary     = 'Allows you to nest ActiveRecord records with various strategies like tree, set, path, etc.'
  s.description = 'Allows you to nest ActiveRecord records with various strategies like tree, set, path, etc.'

  s.author   = 'Sean Huber'
  s.email    = 'shuber@huberry.com'
  s.homepage = 'http://github.com/shuber/nestable'

  s.has_rdoc = false
  s.rdoc_options = ['--line-numbers', '--inline-source', '--main', 'README.rdoc']

  s.require_paths = ['lib']

  s.files = %w(
    lib/nestable.rb
    lib/nestable/interface.rb
    lib/nestable/strategy.rb
    lib/nestable/strategy/path.rb
    lib/nestable/strategy/tree.rb
    lib/nestable/version.rb
    lib/shuber-interface.rb
    MIT-LICENSE
    Rakefile
    README.rdoc
    test/nestable_test.rb
    test/path_test.rb
    test/test_helper.rb
    test/tree_test.rb
  )

  s.test_files = %w(
    test/nestable_test.rb
    test/path_test.rb
    test/test_helper.rb
    test/tree_test.rb
  )
end