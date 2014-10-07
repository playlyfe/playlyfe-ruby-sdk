playlyfe-ruby-sdk [![Gem Version](https://badge.fury.io/rb/playlyfe.svg)](http://badge.fury.io/rb/playlyfe)
=================
You can get the gem at [RubyGems](https://rubygems.org/gems/playlyfe)  
To understand how the complete api works checkout [The Playlyfe Api](http://dev.playlyfe.com/docs/api) for more information

Requires
--------
Ruby >= 1.9.3

Install
----------
```ruby
gem install playlyfe
```
or if you are using rails  
Just add it to your Gemfile
```ruby
gem 'playlyfe'
```
and do a bundle install

Using
-----
### Create a client
  There are 2 kinds of oauth flows you can use in the sdk i.e. the client credentials flow and the authorization code flow.  
  If you haven't created a client for your game yet just head over to [Playlyfe](http://playlyfe.com) and login into your account, and go to the game settings and click on client  
  **1.Client Credentials Flow**  
    In the client page click on whitelabel client  
    ![alt text](https://github.com/pyros2097/playlyfe-ruby-sdk/raw/master/images/client.png "")

  **2.Authorization Code Flow**  
    In the client page click on backend client and specify the redirect uri this will be the url where you will be redirected to get the token
    ![alt text](https://github.com/pyros2097/playlyfe-ruby-sdk/raw/master/images/auth.png "")

> Note: If you want to test the sdk in staging you can click the Test Client button. You need to pass the player_id in the query in every request also.

  And then note down the client id and client secret you will need it later for using it in the sdk

The Playlyfe class allows you to make rest api calls like GET, POST, .. etc
Example: GET
```ruby
# To get infomation of the player johny
player = Playlyfe.get(
  route: '/player',
  query: { player_id: 'johny' }
)
puts player['id']
puts player['scores']

# To get all available processes with query
processes = Playlyfe.get(
  route: '/processes',
  query: { player_id: 'johny' }
)
puts processes
```

Example: POST
```ruby
# To start a process
process =  Playlyfe.post(
  route: "/definitions/processes/collect",
  query: { player_id: 'johny' },
  body: { name: "My First Process" }
)

#To play a process
Playlyfe.post(
  route: "/processes/#{@process_id}/play",
  query: { player_id: 'johny' },
  body: { trigger: "#{@trigger}" }
)
```

Using it in Rails (any version)
-------------------------------
Add playlyfe gem to your Gemfile
In your Application class add this so the Playlyfe SDK will be initialized at the start of your app.
### 1.Client Credentials Flow

```ruby
Playlyfe.start(
  client_id: 'Your Playlyfe game client id',
  client_secret: 'Your Playlyfe game client secret'
  type: 'client'
)
```
### 2.Authorization Code Flow
```ruby
Playlyfe.start(
  client_id: 'Your Playlyfe game client id',
  client_secret: 'Your Playlyfe game client secret'
  type: 'code'
  redirect_uri: 'https://example.com/oauth/callback'
)
```
In this flow then you need a view which will allow your user to redirect to the login using the playlyfe platform. In that route you will get the authorization code so that the sdk can get the access token
```ruby
Playlyfe.exchange_code(code)
```

Now you should be able to access the Playlyfe api across all your
controllers.
For Images create a proxy route which can be used to get the images
and you can directly refer to the urls of the image
```ruby
def image
    response = Playlyfe.get(
      route: "/assets/players/#{session[:player_id]}",
      query: { player_id: session[:player_id] }
      raw: true
    )
    send_data response, :type =>'image/png', :disposition => 'iniline'
end

# In routes.rb add
get 'image/:filename' => 'welcome#image'

# Use it in your views like
<%= image_tag "/image/user", :align => "left" %//>
```
Documentation
-------------------------------
## Init
You can initiate a client by giving the client_id and client_secret params
```ruby
Playlyfe.init(
    client_id: ''
    client_secret: ''
    type: 'client' or 'code'
    redirect_uri: 'The url to redirect to' #only for auth code flow
    store: lambda { |token| } # The lambda which will persist the access token to a database. You have to persist the token to a database if you want the access token to remain the same in every request
    retrieve: lambda { return token } # The lambda which will retrieve the access token. This is called internally by the sdk on every request so the 
    #the access token can be persisted between requests
)
```
In development the sdk caches the access token in memory so you dont need to provide the store and retrieve lambdas. But in production it is highly recommended to persist the token to a database. It is very simple and easy to do it with redis. You can see the test cases for more examples.
```ruby
    require 'redis'
    require 'playlyfe'
    require 'json'

    redis = Redis.new
    Playlyfe.init(
      client_id: "",
      client_secret: "",
      type: 'client',
      store: lambda { |token| redis.set('token', JSON.generate(token)) },
      retrieve: lambda { return JSON.parse(redis.get('token')) }
    )
```


## Get
```ruby
Playlyfe.get(
    route: '' # The api route to get data from
    query: {} # The query params that you want to send to the route
    raw: false # Whether you want the response to be in raw string form or json
)
```
## Post
```ruby
Playlyfe.post(
    route: '' # The api route to post data to
    query: {} # The query params that you want to send to the route
    body: {} # The data you want to post to the api this will be automagically converted to json
)
```
## Patch
```ruby
Playlyfe.patch(
    route: '' # The api route to patch data
    query: {} # The query params that you want to send to the route
    body: {} # The data you want to update in the api this will be automagically converted to json
)
```
## Delete
```ruby
Playlyfe.delete(
    route: '' # The api route to delete the component
    query: {} # The query params that you want to send to the route
    body: {} # The data which will specify which component you will want to delete in the route
)
```
## Get Login Url
```ruby
Playlyfe.get_login_url()
#This will return the url to which the user needs to be redirected for the user to login. You can use this directly in your views.
```

## Exchange Code
```ruby
Playlyfe.exchange_code(code)
#This is used in the auth code flow so that the sdk can get the access token.
#Before any request to the playlyfe api is made this has to be called atleast once. 
#This should be called in the the route/controller which you specified in your redirect_uri
```

## Errors
A ```PlaylyfeError``` is thrown whenever an error occurs in each call. The error contains a name and message field which can be used to determine the type of error that occurred.

Rails code demostrating using the authorization code flow
---------------------------------------------------------
A typical rails app would look something like this
```ruby
class Application < Rails::Application
    Playlyfe.init(
      client_id: "",
      client_secret: "",
      type: 'code',
      redirect_uri: 'http://localhost:3000/welcome/index'
    )
end
```
### controllers/welcome_controller.rb
```ruby
class WelcomeController < ApplicationController

  def index
    if params['code'].nil?
      puts 'login again'
      # here you need to add some logic if the user is logged in and
      # you need to redirect to the playlyfe login page if needed
    else
      Playlyfe.exchange_code(params['code'])
      redirect_to :action => 'home'
    end
  end

  def home
    @players = Playlyfe.get(route: '/players', query: { player_id: 'johny' })
  end
end
```
### views/welcome/index.html.erb
```ruby
<div class="container">
<div class="form-signin">
Please sign in using the Playlyfe Platform
<a href=<%= Playlyfe.get_auth_url() %>> Login </a>
</div>
</div>
```
### views/welcome/home.html.erb
```ruby
<div class="container">
<div class="panel panel-default">
<% @players["data"].each do |player| %>
    <li class="list-group-item">
      <p>
        <%= player["id"] %>
        <%= player["alias"] %>
      </p>
    </li>
<% end %>
</div>
</div>
```
### config/routes.rb
```ruby
Rails.application.routes.draw do
  root 'welcome#index'
  get 'welcome/index'
  get 'welcome/home'
end
```

License
=======
Playlyfe Ruby SDK v0.5.2  
http://dev.playlyfe.com/  
Copyright(c) 2013-2014, Playlyfe Technologies, developers@playlyfe.com  

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:  

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.  

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
