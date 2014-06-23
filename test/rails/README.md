Playlyfe Rails Demo
===================
This demo shows you how to integrate playlyfe gamification platform into your ruby on rails
application using oauth 2.0

Gems Required
-------------
1. gem 'oauth2'
2. gem 'bootstrap-sass'

Just download or clone the repo and do a ```bundle install```
This installs the necessary gemfiles for running the application

Using
=====
Just add your own client_id and client_secret to the welcome controller and start using
the playlyfe api v1

The demo is hosted at [rails-playlyfe.rhcloud.com](http://rails-playlyfe.rhcloud.com)

The demo uses dummy players (players in your simulator) by including ```?debug=true``` in your queries

Open your server url [localhost:3000](http://localhost:3000)
It displays a login form where you can input the player id and it will login your player and go to the
home page where it displays the player scores, process definitions and active processes.
You can start new processes here and also play the process to get score point.

> Some dummy players you can use are ```johny, khs, calvin, rajan(he noob player don't play him), goku```

> When deploying to openshift change env to development rhc env set RAILS_ENV=development -a app

> If the page displays invalid token just goto [refresh](http://rails-playlyfe.rhcloud.com/welcome/refresh)

Checkout the [Playlyfe Api](http://dev.playlyfe.com/docs/api) for more information
