require 'forwardable'

# A location
# name: unique id
# price: price of stuff at this island
#
# Be sure to call init_cache before anything else
#
# While the server is running, every PRICE_CHANGE_INTERVAL one random island
# gets a price change. Changes are one unit at a time. Prices stay within
# [PRICE_MIN, PRICE_MAX]. Normally distributed?
class Pork::Island
  PRICE_CHANGE_INTERVAL = 30.seconds
  PRICE_MIN = 1
  PRICE_MAX = 50

  def self.collection
    Pork.db.collection('islands')
  end

  @cache = {}

  # let's just keep all the islands in memory
  def self.init_cache
    collection.find.each do |doc|
      island = new doc
      @cache[island.name] = island
    end
  end

  def self.random
    @cache.values.random
  end

  extend SingleForwardable

  def_delegators :@cache, :[]
  def_delegator :@cache, :each_value, :each

  extend Pork::Waker

  def self.wake_start
    wake Time.now
  end

  def self.wake time
    random.price_change
    wake_at PRICE_CHANGE_INTERVAL.ahead(time)
  end

  attr_reader :id, :price
  alias_method :name, :id

  def initialize doc
    @id    = doc[:_id] || doc['_id']
    @price = doc['price']
  end

  def collection
    self.class.collection
  end

  # change price, save to db, and notify self to :price observers
  def price_change
    price_heading = PRICE_MIN + (PRICE_MAX - PRICE_MIN) * rand
    @price += price_heading < price ? -1 : 1

    # save to db
    collection.update({:_id => id}, {'$set' => {price: price}})

    # notify
    Pork::Notifier.notify :price, self
  end
end
