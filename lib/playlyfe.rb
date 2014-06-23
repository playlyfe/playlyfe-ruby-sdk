require 'json'
require 'faraday'
require 'logger'
require 'jwt'
require 'base64'

class Player
  attr_accessor :username
  attr_accessor :id
  attr_accessor :scores
  attr_accessor :processes
  attr_accessor :definitions

  def initialize(username)
    @username = username
    initScores
    initProcesses
    initDefinitions
  end

  def initScores
    player = Playlyfe.get(url: "/player", player: @username)
    @id = player["id"]
    @scores = player["scores"]
  end

  def initDefinitions
    @definitions = []
    @definition_ids = []
    json = Playlyfe.get(url: "/definitions/processes", player: @username)
    json.each do |definition|
      @definition_ids << definition["id"]
    end
    @processes.each do |process|
      if @definition_ids.include? process["definition"]
        @definition_ids.delete(process["definition"])
      end
    end
    json.each do |definition|
      if @definition_ids.include? definition["id"]
        @definitions << definition
      end
    end
  end

  def initProcesses
    #state=ACTIVE,COMPLETED
    json = Playlyfe.get(url: "/processes", player: @username, query: "")
    @data = json["data"]
    @processes = []
    @data.each do |process|
      performers = process["performers"]
      performers.each do |player|
        # It will display only the processes he is performing
        if @id == player["id"]
          @processes << process
          break
        end
      end
    end
  end
end

class Playlyfe
  @@client = nil
  @@token = nil
  @@api = 'http://api.playlyfe.com/v1'
  @@player = ""
  @@debug = true

  # @yield [Token] The Oauth2.0 token
  def self.token
    @@token
  end

  # You can initiate a client by giving the client_id and client_secret params
  # This will authorize a client and get the token
  def self.init(options = {})
    puts 'Playlyfe Initializing...............................................'
    begin
      @@client = OAuth2::Client.new(
          options[:client_id],
          options[:client_secret],
          :authorize_url => "/auth",
          :token_url => "/auth/token",
          :site => "http://playlyfe.com"
      )
    rescue OAuth2::Error => e
      puts 'OAuth2 Error---------------------------------------'
      puts
      puts e
    end
    create_token()
  end

  # Gets a new Oauth2.0 token from playlyfe api
  def self.create_token
    @@token = @@client.client_credentials.get_token({}, {'auth_scheme' => 'request_body', 'mode' => 'query'})
  end

  # Makes a get request to the Playlyfe api
  #
  # @param [Hash] opts the options to make the request with
  # @option opts [String] :player the id of the player
  # @option opts [Hash, String] :query the query params
  # @option opts [Hash] :raw whether the data should not be parsed
  # @yield [json] The response json
  def self.get(options = {})
    options[:player] ||= ''
    options[:query] ||= ''
    options[:raw] ||= false
    begin
      response = @@token.get("#{@@api}#{options[:url]}?debug=true&player_id=#{options[:player]}&#{options[:query]}")
      if options[:raw] == true
        return response
      end
      json = JSON.parse(response.body)
      if @@debug
        puts "Playlyfe: GET #{@@api}#{options[:url]}?debug=true&player_id=#{options[:player]}&#{options[:query]}"
        puts
        puts json
      end
      return json
    rescue OAuth2::Error => e
      puts 'OAuth2 Error'
      puts e.code
      puts e.description
      if e.code == 'invalid_token'
        create_token()
        get()
      end
    end
  end

  # Makes a post request to the Playlyfe api
  #
  # @param [Hash] opts the options to make the request with
  # @option opts [String] :player the id of the player
  # @option opts [Hash, String] body the json body content
  # @yield [json] The response json
  def self.post(options = {})
    options[:player] ||= ''
    opts = {}
    opts[:headers] ||= {'Content-Type' => 'application/json'}
    opts[:body] = JSON.generate(options[:body])
    response = @@token.post("#{@@api}#{options[:url]}?debug=true&player_id=#{options[:player]}", opts)
    json = JSON.parse(response.body)
    if @@debug
      puts "Playlyfe: POST #{@@api}#{options[:url]}?debug=true&player_id=#{options[:player]}"
      puts
      puts json
    end
    return json
  end
end


module OAuth2
  module Strategy
    class Base
      def initialize(client)
        @client = client
      end

      # The OAuth client_id and client_secret
      #
      # @return [Hash]
      def client_params
        {'client_id' => @client.id, 'client_secret' => @client.secret}
      end
    end

    # The Client Credentials Strategy
    #
    # @see http://tools.ietf.org/html/draft-ietf-oauth-v2-15#section-4.4
    class ClientCredentials < Base
      # Not used for this strategy
      #
      # @raise [NotImplementedError]
      def authorize_url
        fail(NotImplementedError, 'The authorization endpoint is not used in this strategy')
      end

      # Retrieve an access token given the specified client.
      #
      # @param [Hash] params additional params
      # @param [Hash] opts options
      def get_token(params = {}, opts = {})
        request_body = opts.delete('auth_scheme') == 'request_body'
        params.merge!('grant_type' => 'client_credentials')
        params.merge!(request_body ? client_params : {:headers => {'Authorization' => authorization(client_params['client_id'], client_params['client_secret'])}})
        @client.get_token(params, opts.merge('refresh_token' => nil))
      end

      # Returns the Authorization header value for Basic Authentication
      #
      # @param [String] The client ID
      # @param [String] the client secret
      def authorization(client_id, client_secret)
        'Basic ' + Base64.encode64(client_id + ':' + client_secret).gsub("\n", '')
      end
    end
  end

  class Error < StandardError
    attr_reader :response, :code, :description

    # standard error values include:
    # :invalid_request, :invalid_client, :invalid_token, :invalid_grant, :unsupported_grant_type, :invalid_scope
    def initialize(response)
      response.error = self
      @response = response

      message = []

      if response.parsed.is_a?(Hash)
        @code = response.parsed['error']
        @description = response.parsed['error_description']
        message << "#{@code}: #{@description}"
      end

      message << response.body

      super(message.join("\n"))
    end
  end

  class Response
    attr_reader :response
    attr_accessor :error, :options

    # Adds a new content type parser.
    #
    # @param [Symbol] key A descriptive symbol key such as :json or :query.
    # @param [Array] One or more mime types to which this parser applies.
    # @yield [String] A block returning parsed content.
    def self.register_parser(key, mime_types, &block)
      key = key.to_sym
      PARSERS[key] = block
      Array(mime_types).each do |mime_type|
        CONTENT_TYPES[mime_type] = key
      end
    end

    # Initializes a Response instance
    #
    # @param [Faraday::Response] response The Faraday response instance
    # @param [Hash] opts options in which to initialize the instance
    # @option opts [Symbol] :parse (:automatic) how to parse the response body. one of :query (for x-www-form-urlencoded),
    # :json, or :automatic (determined by Content-Type response header)
    def initialize(response, opts = {})
      @response = response
      @options = {:parse => :automatic}.merge(opts)
    end

    # The HTTP response headers
    def headers
      response.headers
    end

    # The HTTP response status code
    def status
      response.status
    end

    # The HTTP response body
    def body
      response.body || ''
    end

    # Procs that, when called, will parse a response body according
    # to the specified format.
    PARSERS = {
      :json => lambda { |body| JSON.parse(body) rescue body }, # rubocop:disable RescueModifier
      #:query => lambda { |body| Rack::Utils.parse_query(body) },
      :text => lambda { |body| body }
    }

    # Content type assignments for various potential HTTP content types.
    CONTENT_TYPES = {
      'application/json' => :json,
      'text/javascript' => :json,
      'application/x-www-form-urlencoded' => :query,
      'text/plain' => :text
    }

    # The parsed response body.
    # Will attempt to parse application/x-www-form-urlencoded and
    # application/json Content-Type response bodies
    def parsed
      return nil unless PARSERS.key?(parser)
      @parsed ||= PARSERS[parser].call(body)
    end

    # Attempts to determine the content type of the response.
    def content_type
      ((response.headers.values_at('content-type', 'Content-Type').compact.first || '').split(';').first || '').strip
    end

    # Determines the parser that will be used to supply the content of #parsed
    def parser
      return options[:parse].to_sym if PARSERS.key?(options[:parse])
      CONTENT_TYPES[content_type]
    end
  end

  # The OAuth2::Client class
  class Client
    attr_reader :id, :secret, :site
    attr_accessor :options
    attr_writer :connection

    # Instantiate a new OAuth 2.0 client using the
    # Client ID and Client Secret registered to your
    # application.
    #
    # @param [String] client_id the client_id value
    # @param [String] client_secret the client_secret value
    # @param [Hash] opts the options to create the client with
    # @option opts [String] :site the OAuth2 provider site host
    # @option opts [String] :authorize_url ('/oauth/authorize') absolute or relative URL path to the Authorization endpoint
    # @option opts [String] :token_url ('/oauth/token') absolute or relative URL path to the Token endpoint
    # @option opts [Symbol] :token_method (:post) HTTP method to use to request token (:get or :post)
    # @option opts [Hash] :connection_opts ({}) Hash of connection options to pass to initialize Faraday with
    # @option opts [FixNum] :max_redirects (5) maximum number of redirects to follow
    # @option opts [Boolean] :raise_errors (true) whether or not to raise an OAuth2::Error
    # on responses with 400+ status codes
    # @yield [builder] The Faraday connection builder
    def initialize(client_id, client_secret, options = {}, &block)
      opts = options.dup
      @id = client_id
      @secret = client_secret
      @site = opts.delete(:site)
      ssl = opts.delete(:ssl)
      @options = {:authorize_url => '/oauth/authorize',
                  :token_url => '/oauth/token',
                  :token_method => :post,
                  :connection_opts => {},
                  :connection_build => block,
                  :max_redirects => 5,
                  :raise_errors => true}.merge(opts)
      @options[:connection_opts][:ssl] = ssl if ssl
    end

    # Set the site host
    #
    # @param [String] the OAuth2 provider site host
    def site=(value)
      @connection = nil
      @site = value
    end

    # The Faraday connection object
    def connection
      @connection ||= begin
        conn = Faraday.new(site, options[:connection_opts])
        conn.build do |b|
          options[:connection_build].call(b)
        end if options[:connection_build]
        conn
      end
    end

    # The authorize endpoint URL of the OAuth2 provider
    #
    # @param [Hash] params additional query parameters
    def authorize_url(params = nil)
      connection.build_url(options[:authorize_url], params).to_s
    end

    # The token endpoint URL of the OAuth2 provider
    #
    # @param [Hash] params additional query parameters
    def token_url(params = nil)
      connection.build_url(options[:token_url], params).to_s
    end

    # Makes a request relative to the specified site root.
    #
    # @param [Symbol] verb one of :get, :post, :put, :delete
    # @param [String] url URL path of request
    # @param [Hash] opts the options to make the request with
    # @option opts [Hash] :params additional query parameters for the URL of the request
    # @option opts [Hash, String] :body the body of the request
    # @option opts [Hash] :headers http request headers
    # @option opts [Boolean] :raise_errors whether or not to raise an OAuth2::Error on 400+ status
    # code response for this request. Will default to client option
    # @option opts [Symbol] :parse @see Response::initialize
    # @yield [req] The Faraday request
    def request(verb, url, opts = {}) # rubocop:disable CyclomaticComplexity, MethodLength
      connection.response :logger, ::Logger.new($stdout) if ENV['OAUTH_DEBUG'] == 'true'

      url = connection.build_url(url, opts[:params]).to_s

      response = connection.run_request(verb, url, opts[:body], opts[:headers]) do |req|
        yield(req) if block_given?
      end
      response = Response.new(response, :parse => opts[:parse])

      case response.status
      when 301, 302, 303, 307
        opts[:redirect_count] ||= 0
        opts[:redirect_count] += 1
        return response if opts[:redirect_count] > options[:max_redirects]
        if response.status == 303
          verb = :get
          opts.delete(:body)
        end
        request(verb, response.headers['location'], opts)
      when 200..299, 300..399
        # on non-redirecting 3xx statuses, just return the response
        response
      when 400..599
        error = Error.new(response)
        fail(error) if opts.fetch(:raise_errors, options[:raise_errors])
        response.error = error
        response
      else
        error = Error.new(response)
        fail(error, "Unhandled status code value of #{response.status}")
      end
    end

    # Initializes an AccessToken by making a request to the token endpoint
    #
    # @param [Hash] params a Hash of params for the token endpoint
    # @param [Hash] access token options, to pass to the AccessToken object
    # @param [Class] class of access token for easier subclassing OAuth2::AccessToken
    # @return [AccessToken] the initalized AccessToken
    def get_token(params, access_token_opts = {}, access_token_class = AccessToken)
      opts = {:raise_errors => options[:raise_errors], :parse => params.delete(:parse)}
      if options[:token_method] == :post
        headers = params.delete(:headers)
        opts[:body] = params
        opts[:headers] = {'Content-Type' => 'application/x-www-form-urlencoded'}
        opts[:headers].merge!(headers) if headers
      else
        opts[:params] = params
      end
      response = request(options[:token_method], token_url, opts)
      error = Error.new(response)
      fail(error) if options[:raise_errors] && !(response.parsed.is_a?(Hash) && response.parsed['access_token'])
      hash = response.parsed.merge(access_token_opts)
      AccessToken.new(self, hash.delete('access_token') || hash.delete(:access_token), hash)
      #AccessToken.from_hash(self, response.parsed.merge(access_token_opts))
      #access_token_class.from_hash(self, response.parsed.merge(access_token_opts))
    end

    # The Client Credentials strategy
    #
    # @see http://tools.ietf.org/html/draft-ietf-oauth-v2-15#section-4.4
    def client_credentials
      @client_credentials ||= OAuth2::Strategy::ClientCredentials.new(self)
    end
  end

  class AccessToken
    attr_reader :client, :token, :expires_in, :expires_at, :params
    attr_accessor :options, :refresh_token

    def self.from_hash(client, hash)
      new(client, hash.delete('access_token') || hash.delete(:access_token), hash)
    end

    class << self
      # Initializes an AccessToken from a Hash
      #
      # @param [Client] the OAuth2::Client instance
      # @param [Hash] a hash of AccessToken property values
      # @return [AccessToken] the initalized AccessToken
      def from_hash(client, hash)
        new(client, hash.delete('access_token') || hash.delete(:access_token), hash)
      end

      # Initializes an AccessToken from a key/value application/x-www-form-urlencoded string
      #
      # @param [Client] client the OAuth2::Client instance
      # @param [String] kvform the application/x-www-form-urlencoded string
      # @return [AccessToken] the initalized AccessToken
      def from_kvform(client, kvform)
        from_hash(client, Rack::Utils.parse_query(kvform))
      end
    end

    # Initalize an AccessToken
    #
    # @param [Client] client the OAuth2::Client instance
    # @param [String] token the Access Token value
    # @param [Hash] opts the options to create the Access Token with
    # @option opts [String] :refresh_token (nil) the refresh_token value
    # @option opts [FixNum, String] :expires_in (nil) the number of seconds in which the AccessToken will expire
    # @option opts [FixNum, String] :expires_at (nil) the epoch time in seconds in which AccessToken will expire
    # @option opts [Symbol] :mode (:header) the transmission mode of the Access Token parameter value
    # one of :header, :body or :query
    # @option opts [String] :header_format ('Bearer %s') the string format to use for the Authorization header
    # @option opts [String] :param_name ('access_token') the parameter name to use for transmission of the
    # Access Token value in :body or :query transmission mode
    def initialize(client, token, opts = {})
      @client = client
      @token = token.to_s
      [:refresh_token, :expires_in, :expires_at].each do |arg|
        instance_variable_set("@#{arg}", opts.delete(arg) || opts.delete(arg.to_s))
      end
      @expires_in ||= opts.delete('expires')
      @expires_in &&= @expires_in.to_i
      @expires_at &&= @expires_at.to_i
      @expires_at ||= Time.now.to_i + @expires_in if @expires_in
      @options = {:mode => opts.delete(:mode) || :header,
                  :header_format => opts.delete(:header_format) || 'Bearer %s',
                  :param_name => opts.delete(:param_name) || 'access_token'}
      @params = opts
    end

    # Indexer to additional params present in token response
    #
    # @param [String] key entry key to Hash
    def [](key)
      @params[key]
    end

    # Whether or not the token expires
    #
    # @return [Boolean]
    def expires?
      !!@expires_at # rubocop:disable DoubleNegation
    end

    # Whether or not the token is expired
    #
    # @return [Boolean]
    def expired?
      expires? && (expires_at < Time.now.to_i)
    end

    # Refreshes the current Access Token
    #
    # @return [AccessToken] a new AccessToken
    # @note options should be carried over to the new AccessToken
    def refresh!(params = {})
      fail('A refresh_token is not available') unless refresh_token
      params.merge!(:client_id => @client.id,
                    :client_secret => @client.secret,
                    :grant_type => 'refresh_token',
                    :refresh_token => refresh_token)
      new_token = @client.get_token(params)
      new_token.options = options
      new_token.refresh_token = refresh_token unless new_token.refresh_token
      new_token
    end

    # Convert AccessToken to a hash which can be used to rebuild itself with AccessToken.from_hash
    #
    # @return [Hash] a hash of AccessToken property values
    def to_hash
      params.merge(:access_token => token, :refresh_token => refresh_token, :expires_at => expires_at)
    end

    # Make a request with the Access Token
    #
    # @param [Symbol] verb the HTTP request method
    # @param [String] path the HTTP URL path of the request
    # @param [Hash] opts the options to make the request with
    # @see Client#request
    def request(verb, path, opts = {}, &block)
      self.token = opts
      @client.request(verb, path, opts, &block)
    end

    # Make a GET request with the Access Token
    #
    # @see AccessToken#request
    def get(path, opts = {}, &block)
      request(:get, path, opts, &block)
    end

    # Make a POST request with the Access Token
    #
    # @see AccessToken#request
    def post(path, opts = {}, &block)
      request(:post, path, opts, &block)
    end

    # Make a PUT request with the Access Token
    #
    # @see AccessToken#request
    def put(path, opts = {}, &block)
      request(:put, path, opts, &block)
    end

    # Make a PATCH request with the Access Token
    #
    # @see AccessToken#request
    def patch(path, opts = {}, &block)
      request(:patch, path, opts, &block)
    end

    # Make a DELETE request with the Access Token
    #
    # @see AccessToken#request
    def delete(path, opts = {}, &block)
      request(:delete, path, opts, &block)
    end

    # Get the headers hash (includes Authorization token)
    def headers
      {'Authorization' => options[:header_format] % token}
    end

  private

    def token=(opts) # rubocop:disable MethodLength
      case options[:mode]
      when :header
        opts[:headers] ||= {}
        opts[:headers].merge!(headers)
      when :query
        opts[:params] ||= {}
        opts[:params][options[:param_name]] = token
      when :body
        opts[:body] ||= {}
        if opts[:body].is_a?(Hash)
          opts[:body][options[:param_name]] = token
        else
          opts[:body] << "&#{options[:param_name]}=#{token}"
        end
        # @todo support for multi-part (file uploads)
      else
        fail("invalid :mode option of #{options[:mode]}")
      end
    end
  end
end

