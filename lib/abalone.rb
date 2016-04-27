require 'json'
require 'logger'
require 'sinatra/base'
require 'sinatra-websocket'

require 'pty'
require 'io/console'

class Abalone < Sinatra::Base
  set :logging, true
  set :strict, true
  set :public_folder, "#{settings.root}/../public"
  set :views, "#{settings.root}/../views"

  before {
    env["rack.logger"] = settings.logger if settings.logger
  }

  get '/?:user?' do
    if !request.websocket?
      #redirect '/index.html'
      @requestUsername = (settings.respond_to?(:ssh) and ! settings.ssh.include?(:user)) rescue false
      erb :index
    else
      request.websocket do |ws|

        ws.onopen do
          warn("websocket opened")
          reader, @writer, @pid = PTY.spawn(*shell_command)
          @writer.winsize = [24,80]

#           reader.sync = true
#           EM.add_periodic_timer(0.05) do
#             begin
#               PTY.check(@pid, true)
#               data = reader.read_nonblock(512) # we read non-blocking to stream data as quickly as we can
#               ws.send({'event' => 'output', 'data' => data}.to_json)
#             rescue IO::WaitReadable
#               # nop
#             rescue PTY::ChildExited => e
#               puts "Terminal has exited!"
#               ws.send({'event' => 'logout'}.to_json)
#             end
#           end

          # there must be some form of event driven pty interaction, EM or some gem maybe?
          reader.sync = true
          @term = Thread.new do
            loop do
              begin
                PTY.check(@pid, true)
                data = reader.read_nonblock(512) # we read non-blocking to stream data as quickly as we can
                ws.send(data)

              rescue IO::WaitReadable
                IO.select([reader])
                retry
              rescue PTY::ChildExited => e
                warn('Terminal has exited!')
                ws.close_connection

                Thread.exit
              end
              sleep(0.05)
            end
          end

        end

        ws.onclose do
          warn('websocket closed')
          stop_term()
        end

        ws.onmessage do |message|
          message = JSON.parse(message)

          begin
            case message['event']
            when 'input'
              @writer.write message['data']

            when 'resize'
              row = message['row']
              col = message['col']
              @writer.winsize = [row, col]

            when 'logout', 'disconnect'
              warn("Client exited.")
              stop_term()

            else
              warn("Unrecognized message: #{message.inspect}")
            end
          rescue Errno::EIO => e
            puts "Remote terminal closed."
            puts e.message
            stop_term()

          end

        end
      end
    end
  end

  not_found do
    halt 404, "You shall not pass! (page not found)\n"
  end

  helpers do
    def stop_term()
      Process.kill('TERM', @pid) rescue nil
      @term.join rescue nil
    end

    def sanitized(params)
      params.reject do |key,val|
        ['captures','splat'].include? key
      end
    end

    def allowed(param, value)
      return false unless settings.params.include? param

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

    def shell_command()
      if settings.respond_to? :command
        return settings.command unless settings.respond_to? :params

        command = settings.command
        command = command.split if command.class == String

        sanitized(params).each do |param, value|
          next unless allowed(param, value)

          config = settings.params[param]
          case config
          when nil
            command << "--#{param}" << value
          when Hash
            command << (config[:map] || "--#{param}")
            command << value
          end
        end

        return command
      end

      if settings.respond_to? :ssh
        config = settings.ssh.dup
        config[:user] ||= params['user'] # if not in the config file, it must come from the user

        if config[:user].nil?
          warn "SSH configuration must include the user"
          return ['echo', 'no username provided']
        end

        command = ['ssh', config[:host] ]
        command << '-l' << config[:user] if config.include? :user
        command << '-p' << config[:port] if config.include? :port
        command << '-i' << config[:cert] if config.include? :cert

        return command
      end

      # default just to running login
      'login'
    end
  end
end
