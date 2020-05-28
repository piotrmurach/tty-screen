# frozen_string_literal: true

require_relative "lib/tty/screen/version"

Gem::Specification.new do |spec|
  spec.name          = "tty-screen"
  spec.version       = TTY::Screen::VERSION
  spec.authors       = ["Piotr Murach"]
  spec.email         = ["piotr@piotrmurach.com"]
  spec.summary       = %q{Terminal screen size detection which works on Linux, OS X and Windows/Cygwin platforms and supports MRI, JRuby, TruffleRuby and Rubinius interpreters.}
  spec.description   = %q{Terminal screen size detection which works on Linux, OS X and Windows/Cygwin platforms and supports MRI, JRuby, TruffleRuby and Rubinius interpreters.}
  spec.homepage      = "https://ttytoolkit.org"
  spec.license       = "MIT"
  if spec.respond_to?(:metadata=)
    spec.metadata = {
      "allowed_push_host" => "https://rubygems.org",
      "bug_tracker_uri"   => "https://github.com/piotrmurach/tty-screen/issues",
      "changelog_uri"     => "https://github.com/piotrmurach/tty-screen/blob/master/CHANGELOG.md",
      "documentation_uri" => "https://www.rubydoc.info/gems/tty-screen",
      "homepage_uri"      => spec.homepage,
      "source_code_uri"   => "https://github.com/piotrmurach/tty-screen"
    }
  end
  spec.files         = Dir["lib/**/*"]
  spec.extra_rdoc_files = ["README.md", "CHANGELOG.md", "LICENSE.txt"]
  spec.require_paths = ["lib"]
  spec.required_ruby_version = Gem::Requirement.new(">= 2.0.0")

  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", ">= 3.0"
end
