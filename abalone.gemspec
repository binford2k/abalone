require 'date'

Gem::Specification.new do |s|
  s.name              = "abalone"
  s.version           = '0.4.2'
  s.date              = Date.today.to_s
  s.summary           = "Simple Sinatra based web terminal."
  s.homepage          = "https://github.com/binford2k/abalone/"
  s.email             = "binford2k@gmail.com"
  s.authors           = ["Ben Ford"]
  s.license           = "Apache-2.0"
  s.has_rdoc          = false
  s.require_path      = "lib"
  s.executables       = %w( abalone )
  s.files             = %w( README.md LICENSE )
  s.files            += Dir.glob("lib/**/*")
  s.files            += Dir.glob("bin/**/*")
  s.files            += Dir.glob("doc/**/*")
  s.files            += Dir.glob("views/**/*")
  s.files            += Dir.glob("public/**/*")
  s.add_dependency      "sinatra",      "~> 1.3"
  s.add_dependency      "sinatra-websocket"

  s.description       = <<-desc
    Simply exposes a login shell to a web browser. This is currently
    nowhere near to production quality, so don't actually use it.

    This uses https://github.com/chromium/hterm for the terminal emulator.
  desc
end
