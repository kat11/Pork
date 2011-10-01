Pork is a quick demo prototype server and web client for a sporadic trading game. It's ... silly.

## Requirements

The versions in parentheses are what I had installed the day I made this, not necessarily hard requirements.

* Ruby (1.9.2p290)
* MongoDB (2.0.0)
* Node (0.4.10)

### Ruby Gems

* em-mongo (0.4.1)
* em-synchrony (1.0.0)
* em-websocket (0.3.1)
* eventmachine (1.0.0.beta.4)
* rack (1.3.3)
* rake (0.9.2)

### Node NPMs

* coffee-script (1.1.2)
* jade (0.15.4)
* less (1.1.4)

## Server

Make sure that Mongo is running on port 27017. You're not using the `pork` db for anything else, are you?

    $ rake db:init

to prep the database, then

    $ rake start

to start the server. The websocket listen port is 37881.

## Client

Compile the web client with

    $ rake web:compile

Drop the contents of the `public` directory somewhere on your web server, or serve directly with

    $ rake web:serve

at

    http://localhost:37880
