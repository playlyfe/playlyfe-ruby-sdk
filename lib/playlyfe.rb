require 'json'
require 'rest_client'

class Playlyfe
  @@client = nil
  @@token = nil
  @@api = 'https://api.playlyfe.com/v1'
  @@debug = true
  @@type = 'client'
  @@test = false

  # You can initiate a client by giving the client_id and client_secret params
  # This will authorize a client and get the token
  #
  # @param [Hash] options the options to make the request with
  # @options opts [Boolean] :type where where type can be 'code', 'client' for
  #    for the oauth flows auth code flow and client credentials flow
  def self.init(options = {})
    puts 'Playlyfe Initializing...............................................'
    @@type = options[:type] || 'client'
    @@id = options[:client_id]
    @@secret = options[:client_secret]
    @@store = options[:store]
    @@retrieve = options[:retrieve]
    @@test = options[:test]
    if @@test
      #RestClient.log = Logger.new(STDOUT)
    end
    self.get_access_token()
    # case options[:type]
    #   when 'code'
    #     if options[:redirect_uri].nil?
    #       puts 'You must provide a redirect_uri in the Auth Code Flow'
    #       #raise Error.new()
    #     else
    #       auth_url = @@client.auth_code.authorize_url(:redirect_uri => 'http://localhost:8080/oauth2/callback')
    #       @@client.auth_code.get_token('code_value', :redirect_uri => 'http://localhost:8080/oauth2/callback') #check query.code then make post request
    #     end
    #   else
    #     puts 'This flow does not exist'
    #     #raise Error.new()
    # end
    # access_token = @@client.client_credentials.get_token({}, {'auth_scheme' => 'request_body', 'mode' => 'query'})
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
      if @@test == true
        @@retrieve = lambda { return access_token }
      else
        @@store.call access_token
      end
    rescue => e
      puts e
      puts 'Could not get Access token. Please check if you client_id and client_secret are correct'
      puts e.response
      raise e
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

  # Makes a get request to the Playlyfe api
  #
  # @param [String] url the url of the api request
  # @param [Hash] query the options to make the request with
  # @yield [json] The response json
  def self.get(url, query = {})
    access_token = @@retrieve.call
    self.check_expired(access_token)
    query[:access_token] = access_token['access_token']
    begin
      res = RestClient.get("#{@@api}#{url}",
        {:params => query, :accept => :json } #Bearer %s #:headers => {'Authorization'
      )
      JSON.parse(res.body)
    rescue => e
      puts e.response
    end
  end

  # Makes a post request to the Playlyfe api
  #
  # @param [String] url the url of the api request
  # @param [Hash] body the body to make the request with
  # @yield [json] The response json
  def self.post(url, body = {})
    access_token = @@retrieve.call
    self.check_expired(access_token)
    if body['player_id'].nil?
      player_id = body[:player_id]
      body.delete('player_id')
      begin
        res = RestClient.post("#{@@api}#{url}?player_id=#{player_id}&access_token=#{access_token['access_token']}",
          body.to_json,
          :content_type => :json,
          :accept => :json
        )
        return JSON.parse(res.body)
      rescue => e
        puts e.response
      end
    else
      begin
        res = RestClient.post("#{@@api}#{url}?access_token=#{access_token['access_token']}",
          body.to_json,
          :content_type => :json,
          :accept => :json
        )
        return JSON.parse(res.body)
      rescue => e
        puts e.response
      end
    end
  end
end
