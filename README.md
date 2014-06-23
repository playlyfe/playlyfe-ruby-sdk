playlyfe-ruby-sdk
=================
The playlyfe ruby gem
You can get the gem at RubyGems [Get Playlyfe Gem](https://rubygems.org/gems/playlyfe)
To understand how the complete api works
Checkout [The Playlyfe Api](http://dev.playlyfe.com/docs/api) for more information

Using
------
Just add it to your Gemfile
```ruby
gem 'playlyfe'
```
and do a bundle install

Documentation
--------------
You can initiate a client by giving the client_id and client_secret params
This will authorize a client and get the token
```ruby
Playlyfe.start(
  client_id: 'Your Playlyfe game client id',
  client_secret: 'Your Playlyfe game client secret'
)
```
> If you haven't created a client for your game yet just head over to
[Playlyfe](http://playlyfe.com) and login into your account, and go to config and create one

The Playlyfe Singleton class allows you to make rest api calls like GET, POST, .. etc
Example: GET
```ruby
# To get infomation of the player johny
player = Playlyfe.get(
  url: '/player',
  player: 'johny'
)
puts player['id']
puts player['scores']

# To get all available processes with query
processes = Playlyfe.get(
  url: '/processes',
  player: 'johny',
  query: 'state=ACTIVE,COMPLETED'
)
puts processes
```

Example: POST
```ruby
# To start a process
process =  Playlyfe.post(
  url: "/definitions/processes/collect",
  player: 'johny',
  body: { :name => "My First Process" }
)

#To play a process
Playlyfe.post(
  url: "/processes/#{@process_id}/play",
  player: 'johny'
  body: { :trigger => "#{@trigger}" }
)
```

Using it in Rails (any version)
-------------------------------
Add playlyfe gem to your Gemfile
and just at the end of your ApplicationController class add this
```ruby
Playlyfe.start(
  client_id: 'Your Playlyfe game client id',
  client_secret: 'Your Playlyfe game client secret'
)
```
Now you should be able to access the Playlyfe api across all your
controllers.
For Images create a proxy route which can be used to get the images
and you can directly refer to the urls of the image
```ruby
def image
    puts params
    response = Playlyfe.get(
      url: "/assets/players/#{session[:player_id]}",
      player: session[:player_id],
      raw: true
    )
    send_data response.body, :type =>'image/png', :disposition => 'iniline'
end

# In routes.rb add
get 'image/:filename' => 'welcome#image'

# Use it in your views like
<%= image_tag "/image/user", :align => "left" %>
```
