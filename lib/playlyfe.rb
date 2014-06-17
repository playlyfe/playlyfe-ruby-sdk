require 'oauth2'
require 'json'

class Playlyfe
  @@client = nil
  @@token = nil
  @@api = 'http://api.playlyfe.com/v1'
  @@player = ""
  @@debug = true

  def self.token
    @@token
  end

  # You can initiate a client by giving the client_id and client_secret params
  # This will authorize a client and get the token
  def self.start(options = {})
    puts 'Getting Token'
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

  def self.create_token
    @@token = @@client.client_credentials.get_token({}, {'auth_scheme' => 'request_body', 'mode' => 'query'})
  end

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

  def self.post(options = {})
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
