require 'json'

module Pork
  class WebSocket
    PORT = 37881

    # Listen for connections.
    # Create a new instance for each connection
    def self.start
      EM::WebSocket.start host: '0.0.0.0', port: PORT do |ws|
        ws.onopen { new ws }
      end
    end

    def initialize ws
      @ws = ws
      @subscriptions = []

      # Wrap message handlers in a Fibers per EM::Synchrony
      # Incoming messages are JSON arrays. The first element is the type of
      # message, the remaining element are the args to the handler.
      # Define a handle_XXX method for each message type to handle.
      ws.onmessage do |data|
        Fiber.new do
          begin
            data = JSON.parse data
            send "handle_#{data[0]}", *data[1..-1]
          rescue => e
            p e
            puts e.backtrace
          end
        end.resume
      end

      ws.onclose do
        @subscriptions.each { |s| s.close }
      end
    end

    # Outgoing messages use the same basic JSON protocol as incoming.
    def emit *data
      @ws.send JSON[data]
    end

    def emit_chat chat
      emit :chat, chat.id_string, chat.timestamp, chat.name, chat.content
    end

    # Sent in reply to the handshake, and whenever the character notifies of
    # a change.
    def emit_character c
      emit :character, c.name, c.money, c.cargo, c.island,
        c.arrival && c.arrival.until.to_i
    end

    # Receive new chat message.
    def handle_chat message
      return unless @name
      chat = Chat.new(@name, message).save
      Notifier.notify :chat, chat
    end

    # Request for previous chats.
    def handle_more_chats
      more_chats 50
    end

    # Expected to be the first message received, providing name of character.
    # Reply with character info, a short chat history, and all island info.
    # Set up subscriptions for new chats, price changes and character changes.
    def handle_handshake name
      @name = name

      more_chats 8
      subscribe(:chat) do |chat|
        emit_chat chat
      end

      Island.each do |island|
        emit :island, island.name, island.price
      end
      subscribe(:price) do |island|
        emit :price, island.name, island.price
      end

      character = Character[name]
      emit_character character
      subscribe([:character, character.name]) do |char|
        emit_character char
      end
    end

    def handle_fly_to island
      Character[@name].fly_to island
    end

    def handle_buy
      Character[@name].buy
    end

    def handle_sell
      Character[@name].sell
    end

    def subscribe key, &blk
      sub = Notifier.subscribe(key, &blk)
      # save subscription objects so they can be closed later
      @subscriptions << sub
    end

    def more_chats limit
      chats = Chat.more limit, @min_chat
      chats.each { |chat| emit_chat chat }
      # Track the earliest chat sent so far in @min_chat
      @min_chat = chats.last if chats.length > 0
    end

  end
end