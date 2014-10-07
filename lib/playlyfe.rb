require 'uri'
require 'json'
require 'rest_client'

class PlaylyfeError < StandardError
  attr_accessor :name, :message
  def initialize(res)
    message = []
    begin
      res = JSON.parse(res)
      @name = res['error']
      @message = res['error_description']
      message << "#{@code}: #{@description}"
    rescue => e
    end
    super(message.join("\n"))
  end
end

class Playlyfe
  @@api = 'https://api.playlyfe.com/v1'

  # You can initiate a client by giving the client_id and client_secret params
  # This will authorize a client and get the token
  #
  # @param [Hash] options the options to make the request with
  # @param options
  #    [Boolean] :type where where type can be 'code', 'client' for
  #       for the oauth2 auth code flow and client credentials flow
  #    [lambda] :store a method that persists the access_token into
  #       a database
  #    [lambda] :retrieve a method that is used by the sdk internally
  #       to read the access_token and use it in all your requests
  def self.init(options = {})
    puts 'Playlyfe Initializing...............................................'
    if options[:type].nil?
      err = PlaylyfeError.new("")
      err.name = 'init_failed'
      err.message = "You must pass in a type whether 'client' for client credentials flow or 'code' for auth code flow"
      raise err
    end
    @@type = options[:type]
    @@id = options[:client_id]
    @@secret = options[:client_secret]
    @@store = options[:store]
    @@retrieve = options[:retrieve]
    if @@store.nil?
      @@store = lambda { |token| puts 'Storing Token' }
    end
    if @@type == 'client'
      self.get_access_token()
    else
      if options[:redirect_uri].nil?
        err = PlaylyfeError.new("")
        err.name = 'init_failed'
        err.message = 'You must pass in a redirect_uri for the auth code flow'
        raise err
      else
        puts 'CLIENT'
        #RestClient.get("https://playlyfe.com/auth?redirect_uri=#{options[:redirect_uri]}&response_type=code&client_id=#{@@id}")
        #:authorize_url =>
        #'response_type' => 'code', 'client_id' => @@id
        #auth_url = @@client.auth_code.authorize_url(:redirect_uri => 'http://localhost:8080/oauth2/callback')
        #@@client.auth_code.get_token('code_value', :redirect_uri => 'http://localhost:8080/oauth2/callback') #check query.code then make post request
      end
    end
    #RestClient.log = Logger.new(STDOUT)
  end

  def self.get_access_token
    puts 'Getting Access Token'
    begin
      access_token = RestClient.post('https://playlyfe.com/auth/token',
        {
          :client_id => @@id,
          :client_secret => @@secret,
          :grant_type => 'client_credentials'
        }.to_json,
        :content_type => :json,
        :accept => :json
      )
      access_token = JSON.parse(access_token)
      expires_at ||= Time.now.to_i + access_token['expires_in']
      access_token.delete('expires_in')
      access_token['expires_at'] = expires_at
      @@store.call access_token
      if @@retrieve.nil?
        @@retrieve = lambda { return access_token }
      end
    rescue => e
      raise PlaylyfeError.new(e.response)
    end
  end

  def self.check_expired(access_token)
    if access_token['expires_at'] < Time.now.to_i
      puts 'Access Token Expired'
      self.get_access_token()
    end
  end

  # def refresh!(params = {})
  #   params.merge!(:client_id => @client.id,
  #                 :client_secret => @client.secret,
  #                 :grant_type => 'refresh_token',
  #                 :refresh_token => refresh_token)
  #   new_token = @client.get_token(params)
  #   new_token.options = options
  #   new_token.refresh_token = refresh_token unless new_token.refresh_token
  #   new_token
  # end

  def self.login
  end

  def self.get(options = {})
    options[:route] ||= ''
    options[:query] ||= {}
    options[:raw] ||= false

    access_token = @@retrieve.call
    self.check_expired(access_token)
    options[:query][:access_token] = access_token['access_token']

    begin
      res = RestClient.get("#{@@api}#{options[:route]}",
        {:params => options[:query] }
      )
      if options[:raw] == true
        return res.body
      else
        return JSON.parse(res.body)
      end
    rescue => e
      raise PlaylyfeError.new(e.response)
    end
  end

  def self.post(options = {})
    options[:route] ||= ''
    options[:query] ||= {}
    options[:body] ||= {}

    access_token = @@retrieve.call
    self.check_expired(access_token)
    options[:query][:access_token] = access_token['access_token']

    begin
      res = RestClient.post("#{@@api}#{options[:route]}?#{self.hash_to_query(options[:query])}",
        options[:body].to_json,
        :content_type => :json,
        :accept => :json
      )
      return JSON.parse(res.body)
    rescue => e
      raise PlaylyfeError.new(e.response)
    end
  end

  def self.patch(options = {})
    options[:route] ||= ''
    options[:query] ||= {}
    options[:body] ||= {}

    access_token = @@retrieve.call
    self.check_expired(access_token)
    options[:query][:access_token] = access_token['access_token']

    begin
      res = RestClient.patch("#{@@api}#{options[:route]}?#{self.hash_to_query(options[:query])}",
        options[:body].to_json,
        :content_type => :json,
        :accept => :json
      )
      return JSON.parse(res.body)
    rescue => e
      raise PlaylyfeError.new(e.response)
    end
  end

  def self.delete(options = {})
    options[:route] ||= ''
    options[:query] ||= {}

    access_token = @@retrieve.call
    self.check_expired(access_token)
    options[:query][:access_token] = access_token['access_token']

    begin
      res = RestClient.delete("#{@@api}#{options[:route]}",
        {:params => options[:query] }
      )
      JSON.parse(res.body)
    rescue => e
      raise PlaylyfeError.new(e.response)
    end
  end

  def self.hash_to_query(hash)
    return URI.encode(hash.map{|k,v| "#{k}=#{v}"}.join("&"))
  end
end
