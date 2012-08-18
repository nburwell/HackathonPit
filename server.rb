#! /usr/bin/ruby
# redis server command
# /usr/local/bin/redis-server ~/.redis_conf &

# EM server command
# ./server.rb

require 'rubygems'
require "bundler/setup"

require 'eventmachine'
require 'em-websocket'
require 'em-hiredis'
require 'sinatra/base'
require 'thin'
require 'json'
require "app/model/game"

@sockets = []
@game = Game.new

class ServerApp < Sinatra::Base
  get '/' do
    send_file File.join(settings.public_folder, 'index.html')
  end
end

EventMachine.run do
  EventMachine::WebSocket.start(:host => '0.0.0.0', :port => 8080) do |socket|
    socket.onopen do
      puts "new socket"
      @game.add_player socket
      puts "sending updates"
      @game.send_updates
    end
    
    socket.onmessage do |mess|
      # Process message
      puts "Received message #{mess.inspect}"
      # Sends to every other player.
      @game.send_updates
    end
    
    socket.onclose do
      @game.remove_player_for_socket socket
      
      # Sends to every other player.
      @game.send_updates
    end
  end
  Thin::Server.start ServerApp, '0.0.0.0', 4000
end