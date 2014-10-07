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
    @@redirect_uri = options[:redirect_uri]
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
      end
    end
  end

  def self.get_access_token
    puts 'Getting Access Token'
    begin
      if @@type == 'client'
        access_token = RestClient.post('https://playlyfe.com/auth/token',
          {
            :client_id => @@id,
            :client_secret => @@secret,
            :grant_type => 'client_credentials'
          }.to_json,
          :content_type => :json,
          :accept => :json
        )
      else
        access_token = RestClient.post("https://playlyfe.com/auth/token",
          {
            :client_id => @@id,
            :client_secret => @@secret,
            :grant_type => 'authorization_code',
            :code => @@code,
            :redirect_uri => @@redirect_uri
          }.to_json,
          :content_type => :json,
          :accept => :json
        )
      end
      access_token = JSON.parse(access_token)
      expires_at ||= Time.now.to_i + access_token['expires_in']
      access_token.delete('expires_in')
      access_token['expires_at'] = expires_at
      @@store.call access_token
      if @@retrieve.nil?
        @@retrieve = lambda { return access_token }
      else
        old_token = @@retrieve.call
        if access_token != old_token
          @@retrieve = lambda { return access_token }
        end
      end
    rescue => e
      raise PlaylyfeError.new(e.response)
    end
  end

  def self.exchange_code(code)
    if code.nil?
      err = PlaylyfeError.new("")
      err.name = 'init_failed'
      err.message = 'You must pass in a code in exchange_code for the auth code flow'
      raise err
    else
      @@code = code
      self.get_access_token()
    end
  end

  def self.check_token(options)
    puts 'Checking Token'
    if @@retrieve.nil?
      err = PlaylyfeError.new("")
      err.name = 'api_request_failed'
      err.message = 'You must pass in a code in exchange_code for the auth code flow'
      raise err
    end
    access_token = @@retrieve.call
    if access_token['expires_at'] < Time.now.to_i
      puts 'Access Token Expired'
      access_token = self.get_access_token()
    end
    options[:query][:access_token] = access_token['access_token']
  end

  def self.get(options = {})
    options[:route] ||= ''
    options[:query] ||= {}
    options[:raw] ||= false
    self.check_token(options)

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
    self.check_token(options)

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
    self.check_token(options)

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
    self.check_token(options)

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
