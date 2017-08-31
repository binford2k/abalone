require 'json'
require 'logger'
require 'sinatra/base'
require 'em/pure_ruby' if Gem.win_platform?
require 'sinatra-websocket'

class Abalone < Sinatra::Base
  set :logging, true
  set :strict, true
  set :protection, :except => :frame_options
  set :public_folder, "#{settings.root}/../public"
  set :views, "#{settings.root}/../views"
  set :active, {}

  enable :sessions

  before {
    env["rack.logger"] = settings.logger if settings.logger

    trap('INT') do
      # this forces all the spawned children to terminate as well
      puts "Caught SIGINT. Terminating active sessions (#{Process.pid}) now."
      exit!
    end
  }

  # super low cost heartbeat response.
  # Add this first to ensure that the user route doesn't take precedence.
  get '/heartbeat/ping' do
    'alive'
  end

  get '/api/reset' do
    if @terminal = settings.active[session.id]
      @terminal.terminate!
    end
    redirect to('/')
  end

  get '/?:user?' do
    if !request.websocket?
      @requestUsername = (settings.respond_to?(:ssh) and ! settings.ssh.include?(:user)) rescue false
      @autoconnect     = settings.autoconnect
      if settings.respond_to?(:welcome)
        begin
          @welcome = File.file?(settings.welcome) ? File.read(settings.welcome) : settings.welcome
        rescue => e
          warn e.message
        end
      end
      erb :index
    else
      request.websocket do |ws|
        uid = session.id
        ws.onopen do
          warn("websocket opened")
          # expire all dead terminals
          settings.active.delete_if {|uid, term| ! term.alive? }

          if @terminal = settings.active[uid]
            @terminal.reconnect(ws)
          else
            warn "Starting a new session for #{uid}."
            @terminal = Abalone::Terminal.new(settings, ws, sanitized(params))

            if settings.respond_to? :ttl
              settings.active[uid] = @terminal
              logger.debug "Saving session #{uid}."
              logger.debug "Active sessions: #{settings.active.keys.inspect}"
            end
          end
        end

        ws.onclose do
          warn('websocket closed')
          @terminal.stop! if @terminal
        end

        ws.onmessage do |message|
          message = JSON.parse(message)

          begin
            case message['event']
            when 'input'
              @terminal.write(message['data'])

            when 'modes'
              @terminal.modes = message['data']

            when 'resize'
              row = message['row']
              col = message['col']
              @terminal.resize(row, col)

            when 'logout', 'disconnect'
              warn("Client exited.")
              @terminal.stop!

            else
              warn("Unrecognized message: #{message.inspect}")
            end
          rescue Errno::EIO => e
            warn "Remote terminal closed."
            warn e.message
            @terminal.stop!

          end

        end
      end
    end
  end

  not_found do
    halt 404, "You shall not pass! (page not found)\n"
  end

  helpers do

    def sanitized(params)
      params.reject do |key,val|
        ['captures','splat'].include?(key) or not allowed(key, val)
      end
    end

    def allowed(param, value)
      return false unless settings.params.include? param
      return true if settings.params.is_a? Array

      config = settings.params[param]
      return true if config.nil?
      return true unless config.include? :values

      config[:values].each do |pattern|
        case pattern
        when String
          return true if value == pattern
        when Regexp
          return true if pattern.match(value)
        end
      end

      false
    end

  end
end
