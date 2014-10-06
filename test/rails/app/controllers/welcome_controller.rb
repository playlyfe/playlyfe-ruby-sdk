class WelcomeController < ApplicationController

  # This is the Webserver oauth client Initialization Route
  # It first authorizes the playlyfe api and gets the auth token
  # The username is field is required and is stored in the session
  # If the session contains the player_id/username then
  # it redirects to the player home page
  def index
    puts Playlyfe.get('/players', player_id: 'student1')
  end

  # This is to login a new user and store the player_id/username
  # into the session
  # post: @param [username]
  def login
    session[:username] = params['username']
    #redirect_to url_for(:controller => "welcome", :action => "home")
  end

  # This is the player's home page route
  # A new player is created with the token
  # The players profile information, process definition_nameions and joined processes
  # requested and are displayed
  def home
    @response = []
    #@player = Player.new(session[:username])
    #session[:player_id] = @player.id
  end
end
