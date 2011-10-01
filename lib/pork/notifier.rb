# publish / subscribe within EM.
#
# subscribers call Notifier.subscribe with a key specifying the channel
# they're subscribing to, and a callback block. Notifier.subscribe returns a
# Subscription object. Call close on that to unsubscribe. Subscribers only
# receive data pushed subsequent, not prior, to their subscription.
#
# publishers push data to Notifier.notify with a channel key.
#
# channels are created and discarded on an ad hoc basis as needed.
module Pork::Notifier
  @channels = Hash.new { |h,k| h[k] = Channel.new k }

  def self.notify key, data
    if @channels.has_key? key
      @channels[key] << data
    end
  end

  def self.subscribe key, &block
    @channels[key].subscribe &block
  end

  class Subscription
    def initialize channel, id
      @channel = channel
      @id      = id
    end

    def close
      return if @closed
      @closed = true
      @channel.unsubscribe @id
    end
  end

  class Channel
    def initialize key
      @key         = key
      @channel     = EM::Channel.new
      @subscribers = 0
    end

    def subscribe &block
      @subscribers += 1
      id = @channel.subscribe &block
      Subscription.new self, id
    end

    def << data
      @channel << data
    end

    def unsubscribe id
      @channel.unsubscribe id
      @subscribers -= 1
      unless @subscribers > 0
        key = @key
        Pork::Notifier.instance_eval do
          @channels.delete key
        end
      end
    end
  end
end
