class WelcomeController < ApplicationController

  # This is the Webserver oauth client Initialization Route
  # It first authorizes the playlyfe api and gets the auth token
  # The username is field is required and is stored in the session
  # If the session contains the player_id/username then
  # it redirects to the player home page
  def index
    Playlyfe.get(url: '/players')
  end

  # This is to login a new user and store the player_id/username
  # into the session
  # post: @param [username]
  def login
    session[:username] = params['username']
    redirect_to url_for(:controller => "welcome", :action => "home")
  end

  # This is the player's home page route
  # A new player is created with the token
  # The players profile information, process definition_nameions and joined processes
  # requested and are displayed
  def home
    @response = []
    @player = Player.new(session[:username])
    session[:player_id] = @player.id
  end

  # This is to start a new process
  # => @param
  # => definition_id
  # => definition_name
  def start
    @definition_id = params["definition_id"]
    @definition_name = params["definition_name"]
    #opts[:body] =
    #response = $token.post("#{$api}/definitions/processes/#{@definition_id}?debug=true&player_id=#{session[:username]}", opts)
    process =  Playlyfe.post(
      url: "/definitions/processes/#{@definition_id}",
      player: session[:username],
      body: { :name => "#{@definition_name}" }
    )
    @process_id =  process["id"]
    @process_name =  process["name"]
    @triggers = Playlyfe.get(
      url: "/processes/#{@process_id}/triggers",
      player: session[:username]
    )
  end

  #Lists all the triggers of the process
  # => @param
  # => process_id
  # => process_name
  def trigger
    @process_id =  params["process_id"]
    @process_name =  params["process_name"]
    @triggers = Playlyfe.get(
      url: "/processes/#{@process_id}/triggers",
      player: session[:username]
    )
  end

  # Play's a processes's trigger
  # => @param
  # => process_id
  # => trigger
  def play
    @process_id =  params["process_id"]
    @trigger = params["trigger_id"]
    Playlyfe.post(
      url: "/processes/#{@process_id}/play",
      player: session[:username],
      body: { :trigger => "#{@trigger}" }
    )
    redirect_to url_for(:controller => "welcome", :action => "home")
  end

  #Logs out of the current session and redirects to index page
  def logout
    session[:username] = nil
    redirect_to url_for(:controller => "welcome", :action => "index")
  end

  def image
    response = Playlyfe.get(
      url: "/assets/players/#{session[:player_id]}",
      player: session[:player_id],
      raw: true
    )
    send_data response.body, :type =>'image/png', :disposition => 'iniline'
  end
end
