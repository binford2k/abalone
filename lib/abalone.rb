require 'json'
require 'logger'
require 'sinatra/base'
require 'sinatra-websocket'

require 'pty'
require 'io/console'
require 'securerandom'

class Abalone < Sinatra::Base
  set :logging, true
  set :strict, true
  set :protection, :except => :frame_options
  set :public_folder, "#{settings.root}/../public"
  set :views, "#{settings.root}/../views"

  enable :sessions

  before {
    env["rack.logger"] = settings.logger if settings.logger

    trap('INT') do
      # this forces all the spawned children to terminate as well
      puts "Caught SIGINT. Terminating active sessions (#{Process.pid}) now."
      exit!
    end

  }

  get '/?:user?' do

    if settings.uuid
      session[:uuid] ||= SecureRandom.uuid
    end

    if !request.websocket?
      #redirect '/index.html'
      @requestUsername = (settings.respond_to?(:ssh) and ! settings.ssh.include?(:user)) rescue false
      @autoconnect     = settings.autoconnect
      erb :index
    else
      request.websocket do |ws|

        ws.onopen do
          warn("websocket opened")
          ENV['TERM'] ||= 'xterm' # make sure we've got a somewhat sane environment

          if settings.respond_to?(:bannerfile)
            ws.send({'data' => File.read(settings.bannerfile).encode(crlf_newline: true)}.to_json)
            ws.send({'data' => "\r\n\r\n"}.to_json)
          end

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
            carry = []
            loop do
              begin
                PTY.check(@pid, true)
                output = reader.read_nonblock(512).unpack('C*') # we read non-blocking to stream data as quickly as we can
                last_low = output.rindex { |x| x < 128 } # find the last low bit
                trailing = last_low +1

                # use inclusive slices here
                data  = (carry + output[0..last_low]).pack('C*').force_encoding('UTF-8') # repack into a string up until the last low bit
                carry = output[trailing..-1]             # save the any remaining high bits and partial chars for next go-round

                ws.send({'data' => data}.to_json)

              rescue IO::WaitReadable
                IO.select([reader])
                retry

              rescue PTY::ChildExited => e
                warn('Terminal has exited!')
                ws.close_connection

                @timer.terminate rescue nil
                @timer.join rescue nil
                Thread.exit
              end

              sleep(0.05)
            end
          end

          if settings.respond_to? :timeout
            @timer = Thread.new do
              expiration = Time.now + settings.timeout
              loop do
                remaining = expiration - Time.now
                stop_term if remaining < 0

                time = {
                  'event' => 'time',
                  'data'  => Time.at(remaining).utc.strftime("%H:%M:%S"),
                }
                ws.send(time.to_json)
                sleep 1
              end
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
      sleep 1
      Process.kill('KILL', @pid) rescue nil
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

        command << "--uuid" << session[:uuid] if settings.uuid

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
