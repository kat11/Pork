#!/usr/bin/env ruby

# https://github.com/igrigorik/em-synchrony
require 'em-synchrony'

# https://github.com/igrigorik/em-websocket/tree/master/examples
require 'em-websocket'

# https://github.com/igrigorik/em-synchrony/blob/master/spec/em-mongo_spec.rb
# https://github.com/bcg/em-mongo/tree/master/spec/integration
require 'em-synchrony/em-mongo'

require 'monkey'

module Pork
  DB_NAME = 'pork'

  provides :WebSocket, :Notifier, :Chat, :Character, :Island, :Waker

  # start the pork server
  def self.start
    EM.set_max_timers 20_000
    EM.synchrony do
      Island.init_cache
      Waker.start
      WebSocket.start
    end
  end

  # Pooled db connections
  def self.db
    @db ||= EM::Synchrony::ConnectionPool.new(size: 10) do
      EM::Mongo::Connection.new.db DB_NAME
    end
  end
end

if $0 == __FILE__
  Pork.start
end