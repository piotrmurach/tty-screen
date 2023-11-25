# frozen_string_literal: true

require_relative "lib/tty/screen/version"

Gem::Specification.new do |spec|
  spec.name = "tty-screen"
  spec.version = TTY::Screen::VERSION
  spec.authors = ["Piotr Murach"]
  spec.email = ["piotr@piotrmurach.com"]
  spec.summary = "Terminal screen size detection."
  spec.description = "Terminal screen size detection that works on Linux, " \
                     "OS X and Windows/Cygwin platforms and supports MRI, " \
                     "JRuby, TruffleRuby and Rubinius interpreters."
  spec.homepage = "https://ttytoolkit.org"
  spec.license = "MIT"
  spec.metadata = {
    "allowed_push_host" => "https://rubygems.org",
    "bug_tracker_uri" => "https://github.com/piotrmurach/tty-screen/issues",
    "changelog_uri" =>
      "https://github.com/piotrmurach/tty-screen/blob/master/CHANGELOG.md",
    "documentation_uri" => "https://www.rubydoc.info/gems/tty-screen",
    "funding_uri" => "https://github.com/sponsors/piotrmurach",
    "homepage_uri" => spec.homepage,
    "rubygems_mfa_required" => "true",
    "source_code_uri" => "https://github.com/piotrmurach/tty-screen"
  }
  spec.files = Dir["lib/**/*"]
  spec.extra_rdoc_files = ["README.md", "CHANGELOG.md", "LICENSE.txt"]
  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 2.0.0"

  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", ">= 3.0"
end
