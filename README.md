playlyfe-ruby-sdk
=================

The playlyfe ruby sdk gem
You can get the gem at RubyGems [Playlyfe](https://rubygems.org/gems/playlyfe)

Using
------
Just add it to your Gemfile
```gem 'playlyfe'```
and do a bundle install

Documentation
--------------
You can initiate a client by giving the client_id and client_secret params
This will authorize a client and get the token
```ruby
Playlyfe.start(
  client_id: 'Your Playlyfe client id',
  client_secret: 'Your Playlyfe client secret'
)
```
If you haven't created a client for your game yet just head over to
[Playlyfe](playlyfe.com) and login, and go to config and create one

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

To understard how the complete api works
Checkout the [Playlyfe Api](http://dev.playlyfe.com/docs/api) for more information
