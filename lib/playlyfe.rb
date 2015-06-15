require 'uri'
require 'json'
require 'rest_client'
require 'jwt'

class PlaylyfeError < StandardError
  attr_accessor :name, :message
  def initialize(res)
    message = []
    begin
      @raw = res
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
  attr_reader :sdk_version

  def self.createJWT(options)
    options[:scopes] ||= []
    options[:expires] ||= 3600
    expires = Time.now.to_i + options[:expires]
    token = JWT.encode({:player_id => options[:player_id], :scopes => options[:scopes], :exp => expires}, options[:client_secret], 'HS256')
    token = "#{options[:client_id]}:#{token}"
    return token
  end

  def initialize(options = {})
    if options[:type].nil?
      err = PlaylyfeError.new("")
      err.name = 'init_failed'
      err.message = "You must pass in a type whether 'client' for client credentials flow or 'code' for auth code flow"
      raise err
    end
    @version = options[:version] ||= 'v2'
    @type = options[:type]
    @id = options[:client_id]
    @secret = options[:client_secret]
    @store = options[:store]
    @load = options[:load]
    @redirect_uri = options[:redirect_uri]
    if @store.nil?
      @store = lambda { |token| puts 'Storing Token' }
    end
    if @type == 'client'
      get_access_token()
    else
      if options[:redirect_uri].nil?
        err = PlaylyfeError.new("")
        err.name = 'init_failed'
        err.message = 'You must pass in a redirect_uri for the auth code flow'
        raise err
      end
    end
  end

  def get_access_token
    begin
      if @type == 'client'
        access_token = RestClient.post('https://playlyfe.com/auth/token',
          {
            :client_id => @id,
            :client_secret => @secret,
            :grant_type => 'client_credentials'
          }.to_json,
          :content_type => :json,
          :accept => :json
        )
      else
        access_token = RestClient.post("https://playlyfe.com/auth/token",
          {
            :client_id => @id,
            :client_secret => @secret,
            :grant_type => 'authorization_code',
            :code => @code,
            :redirect_uri => @redirect_uri
          }.to_json,
          :content_type => :json,
          :accept => :json
        )
      end
      access_token = JSON.parse(access_token)
      expires_at ||= Time.now.to_i + access_token['expires_in']
      access_token.delete('expires_in')
      access_token['expires_at'] = expires_at
      @store.call access_token
      if @load.nil?
        @load = lambda { return access_token }
      else
        old_token = @load.call
        if access_token != old_token
          @load = lambda { return access_token }
        end
      end
    rescue => e
      raise PlaylyfeError.new(e.response)
    end
  end

  def check_token(query)
    access_token = @load.call
    if access_token['expires_at'] < Time.now.to_i
      puts 'Access Token Expired'
      get_access_token()
      access_token = @load.call
    end
    query[:access_token] = access_token['access_token']
  end

  def api(method, route, query = {}, body = {}, raw = false)
    check_token(query)
    begin
      case method
        when 'GET'
          res = RestClient.get("https://api.playlyfe.com/#{@version}#{route}",
            {:params => query }
          )
        when 'POST'
          res = RestClient.post("https://api.playlyfe.com/#{@version}#{route}?#{hash_to_query(query)}",
            body.to_json,
            :content_type => :json,
            :accept => :json
          )
        when 'PUT'
          res = RestClient.put("https://api.playlyfe.com/#{@version}#{route}?#{hash_to_query(query)}",
            body.to_json,
            :content_type => :json,
            :accept => :json
          )
        when 'PATCH'
          res = RestClient.patch("https://api.playlyfe.com/#{@version}#{route}?#{hash_to_query(query)}",
            body.to_json,
            :content_type => :json,
            :accept => :json
          )
        when 'DELETE'
          res = RestClient.delete("https://api.playlyfe.com/#{@version}#{route}",
            {:params => query }
          )
      end
      if raw == true
        return res.body
      else
        if res.body == 'null'
          return nil
        else
          return JSON.parse(res.body)
        end
      end
    rescue => e
      raise PlaylyfeError.new(e.response)
    end
  end

  def get(route, query = {})
    api("GET", route, query, {}, false)
  end

  def get_raw(route, query = {})
    api("GET", route, query, {}, true)
  end

  def post(route, query = {}, body = {})
    api("POST", route, query, body, false)
  end

  def put(route, query = {}, body = {})
    api("PUT", route, query, body, false)
  end

  def patch(route, query = {}, body = {})
    api("PATCH", route, query, body, false)
  end

  def delete(route, query = {})
    api("DELETE", route, query, {}, false)
  end

  def hash_to_query(hash)
    return URI.encode(hash.map{|k,v| "#{k}=#{v}"}.join("&"))
  end

  def get_login_url
    query = { response_type: 'code', redirect_uri: @redirect_uri, client_id: @id }
    "https://playlyfe.com/auth?#{hash_to_query(query)}"
  end

  def get_logout_url
    ""
  end

  def exchange_code(code)
    if code.nil?
      err = PlaylyfeError.new("")
      err.name = 'init_failed'
      err.message = 'You must pass in a code in exchange_code for the auth code flow'
      raise err
    else
      @code = code
      get_access_token()
    end
  end
end
