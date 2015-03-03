require 'excon'
require 'json'
require 'socket'
require 'facter'


module MCollective
    module Agent
      class Docker<RPC::Agent
      
        action "info" do
	    logger.debug "docker/info"
            begin
               reply[:info] = _request(:get, 'info')
    	    rescue => e
               reply.fail! "Error querying docker api (GET /info), #{e}"
               logger.error e
	    end
	    logger.debug "docker/info done."
        end
        
	action "version" do
            logger.debug "docker/version"
            begin
               reply[:version] = _request(:get, 'version') 
            rescue => e
               reply.fail! "Error querying docker api (GET /version), #{e}"
               logger.error e
            end
            logger.debug "docker/version done."
        end
	
      # there are a few parameters to add like: size and filters(status)
        action "containers" do
            logger.debug "docker/containers"
            options = {}
            [:all, :limit, :sinceId, :beforeId].each {|o|
               options[o] = request[o] if request[o]
            }
            logger.debug "docker/containers options=#{options}"
            begin
               reply[:containers] = _request(:get, 'containers/json?', {}, options)
            rescue => e
               reply.fail! "Error querying docker api (GET containers/json), #{e}"
               logger.error e
            end
            logger.debug "docker/containers done."
        end

        action "createcontainer" do
            logger.debug "docker/createcontainer" 
            options = {}
            options[:name] = request[:name] if request[:name]
	
            begin
               _validateconfig(request[:config])
               info = JSON.parse(_request(:post, "containers/create", options, request[:config]))
               reply[:warnings] = info[:warnings] if info[:warnings]
               reply[:id] = info[:id] if info[:id]
               reply[:id] = _request(:post, 'containers/create')
            rescue => e
               reply.fail! "Error: querying docker api (POST containers/create), #{e}"
               logger.error e
            end
            logger.debug "docker/createcontainer done."
        end

        action "inspectcontainer" do
            logger.debug "docker/inspectcontainer"
            begin
                reply[:details] = _request(:get, "containers/#{request[:id]}/json")
            rescue => e
                reply.fail! "Error querying docker api (GET containers/#{request[:id]}/json), #{e}"
                logger.error e
            end
            logger.debug "docker/inspectcontainer done."
        end

        action "top" do
            logger.debug "docker/top"
            options = {}
            options[:ps_args] = request[:psargs] if request[:psargs]

            begin
               reply[:processes] = _request(:get, "containers/#{request[:id]}/top?", options)
            rescue => e
               reply.fail! "Error querying docker api (GET containers/#{request[:id]}/top), #{e}"
               logger.error e
            end
            logger.debug "docker/top done."
        end

        action "changes" do
            logger.debug "docker/changes"

            begin
               reply[:processes] = _request(:get, "containers/#{request[:id]}/changes")
            rescue => e
               reply.fail! "Error querying docker api (GET containers/#{request[:id]}/changes), #{e}"
               logger.error e
            end
            logger.debug "docker/changes done."
        end

        action "start" do
        logger.debug "docker/start" 

        begin
          reply[:exitcode] = _request(:post, "containers/#{request[:id]}/start")
        rescue => e
          reply.fail! "Error querying docker api (POST containers/#{request[:id]}/start), #{e}"
          logger.error e
        end
        logger.debug "docker/start done."
      end

        action "stop" do
        logger.debug "docker/stop" 
        options = {}
        options[:t] = request[:timeout] if request[:timeout]

        begin
          reply[:exitcode] = _request(:post, "containers/#{request[:id]}/stop?", options)
        rescue => e
          reply.fail! "Error querying docker api (POST containers/#{request[:id]}/stop), #{e}"
          logger.error e
        end
        logger.debug "docker/stop done."
      end

        action "restart" do
        logger.debug "docker/restart" 
        options = {}
        options[:t] = request[:timeout] if request[:timeout]

        begin
          reply[:exitcode] = _request(:post, "containers/#{request[:id]}/restart?", options)
        rescue => e
          reply.fail! "Error querying docker api (POST containers/#{request[:id]}/restart), #{e}"
          logger.error e
        end
        logger.debug "docker/restart done."
      end
      
	action "kill" do
        logger.debug "docker/kill" 
        options = {}
        options[:signal] = request[:signal] if request[:signal]

        begin
          reply[:exitcode] = _request(:post, "containers/#{request[:id]}/kill?", options)
        rescue => e
          reply.fail! "Error querying docker api (POST containers/#{request[:id]}/kill), #{e}"
          logger.error e
        end
        logger.debug "docker/kill done."
      end
      	
	action "pause" do
        logger.debug "docker/pause" 

        begin
          reply[:exitcode] = _request(:post, "containers/#{request[:id]}/pause")
        rescue => e
          reply.fail! "Error querying docker api (POST containers/#{request[:id]}/pause), #{e}"
          logger.error e
        end
        logger.debug "docker/pause done."
      end
      	
	action "unpause" do
        logger.debug "docker/unpause" 

        begin
          reply[:exitcode] = _request(:post, "containers/#{request[:id]}/unpause")
        rescue => e
          reply.fail! "Error querying docker api (POST containers/#{request[:id]}/unpause), #{e}"
          logger.error e
        end
        logger.debug "docker/unpause done."
      end
     	
	action "deletecontainer" do
        logger.debug "docker/deletecontainer" 
        options = {}
        options[:v] = request[:rmvolumes] if request[:rmvolumes]
        options[:force] = request[:force] if request[:force]

        begin
          reply[:exitcode] = _request(:delete, "containers/#{request[:id]}?", options)
        rescue => e
          reply.fail! "Error querying docker api (DELETE containers/#{request[:id]}), #{e}"
          logger.error e
        end
        logger.debug "docker/deletecontainer done."
      end

      	action "images" do
        logger.debug "docker/images"

        options = {}
        [:all, :filters].each {|o|
          options[o] = request[o] if request[o]
        }
        logger.debug "docker/images options=#{options}"
        begin
          reply[:images] = _request(:get, 'images/json?', options)
        rescue => e
          reply.fail! "Error querying docker api (GET images/json), #{e}"
          logger.error e
        end
        logger.debug "docker/images done."
      end
      
	action "createimage" do
        logger.debug "docker/createimage" 
        options = {}
        [:repo, :tag, :registry].each {|o|
          options[o] = request[o] if request[o]
        }
        options[:fromImage] = request[:fromimage] if request[:fromimage]
        
        begin
          reply[:exitcode] = _request(:post, "images/create?", options)
        rescue => e
          reply.fail! "Error querying docker api (POST images/create), #{e}"
          logger.error e
        end
        logger.debug "docker/createimage done."
      end
      
	action "inspectimage" do
        logger.debug "docker/inspectimage"

        begin
          reply[:details] = _request(:get, "images/#{request[:name]}/json")
        rescue => e
          reply.fail! "Error querying docker api (GET images/#{request[:name]}/json), #{e}"
          logger.error e
        end
        logger.debug "docker/inspectimage done."
      end
      
	action "history" do
        logger.debug "docker/history"

        begin
          reply[:history] = _request(:get, "images/#{request[:name]}/history")
        rescue => e
          reply.fail! "Error querying docker api (GET images/#{request[:name]}/history), #{e}"
          logger.error e
        end
        logger.debug "docker/history done."
      end
      
	action "push" do
        logger.debug "docker/push" 
        options = {}
        options[:tag] = request[:tag] if request[:tag]

        begin
          if request[:registry]
            reply[:exitcode] = _request(:post, "images/#{request[:registry]}/#{request[:name]}/push?", 
                                        options)
          else
            reply[:exitcode] = _request(:post, "images/#{request[:name]}/push?", options)
          end
        rescue => e
          reply.fail! "Error querying docker api (POST images/#{request[:name]}/push), #{e}"
          logger.error e
        end
        logger.debug "docker/push done."
      end
      
	action "tag" do
        logger.debug "docker/tag" 
        options = {}
        [:repo, :tag, :force].each {|o|
          options[o] = request[o] if request[o]
        }

        begin
          reply[:exitcode] = _request(:post, "images/#{request[:name]}/tag?", options)
        rescue => e
          reply.fail! "Error querying docker api (POST images/#{request[:name]}/tag), #{e}"
          logger.error e
        end
        logger.debug "docker/tag done."
      end
      
	action "deleteimage" do
        logger.debug "docker/deleteimage" 
        options = {}
        [:noprune, :force].each {|o|
          options[o] = request[o] if request[o]
        }
        reply[:exitcode] = _request(:delete, "images/#{request[:id]}?", options)
        logger.debug "docker/deleteimage done."
      end

      #TODO 
      action "ping" do
        logger.debug "docker/_ping"
        begin
          reply[:ping] = _request(:get, '_ping')
        rescue => e
          reply.fail! "Error querying docker api (GET _ping), #{e}"
          logger.error e
        end
        logger.debug "docker/ping done."
      end
      
	#TODO
      	action "events" do
        logger.debug "docker/events"
        options = {}
        [:since, :until].each {|o|
          options[o] = request[o] if request[o]
        }
        #logger.debug "docker/events options=#{options}"
        begin
          reply[:events] = _request(:get, "events?", options)
        rescue => e
          reply.fail! "Error querying docker api (GET events), #{e}"
          logger.error e
        end
        logger.debug "docker/events done."
      end
	
	# TODO
	action "commit" do
	end
	action "build" do
	end
	
      private
      def _request(htmethod, endpoint, options = {}, body = "")
        rs = endpoint
        unless options.nil?
          options.each {|r| rs += "&" + URI.escape(r[0].to_s) + "=" + URI.escape(r[1].to_s) }
        end
        logger.debug "docker/_request htmethod=#{htmethod} endpoint=#{endpoint}, request=unix:///#{rs}, body=#{body}"
        case htmethod
        when :get
          response = Excon.get("unix:///#{rs}", :socket => '/var/run/docker.sock')
        when :post
          response = Excon.post("unix:///#{rs}", :socket => '/var/run/docker.sock',
                                :body => body, :headers => {'Content-Type' => 'application/json'})
        when :delete
          response = Excon.delete("unix:///#{rs}", :socket => '/var/run/docker.sock',
                                  :body => body, :headers => {'Content-Type' => 'application/json'})
        else
          raise "Internal error"
        end

        logger.debug "docker/_request status=#{response.status}"
        case response.status
        when 200
          return response.body
        when 201
          return response.body
        when 204
          return 204
        else
          raise "Unable to fulfill request. HTTP status #{response.status}"
        end
      end
      
      def _validateconfig(config)
        c = JSON.parse(config)
        c[:ExposedPorts].each {|pc|
          port = pc[0].gsub(/^(tcp|udp)\//, '').to_i
          server = TCPServer.new(pc[:HostIp], port)
          server.close
        }
	extloader = Facter::Util::DirectoryLoader.loader_for(factsdir)
        intloader = Facter::Util::Loader.new
        collection = Facter::Util::Collection.new(intloader, extloader)
        dockerexports = collection.fact("dockerexports").value.split(':')

        return true
      end
      factsdir = '/etc/facter/facts.d'
    end
  end
end
