# name: unique id
# money:
# cargo: true/false for character is carrying stuff
# island: name of current location or destination
# arrival: time of arrival or nil if not in flight
#   stored in db as integer seconds unix timestamp
class Pork::Character
  def self.collection
    Pork.db.collection('characters')
  end

  # find or create a character by name
  def self.[] name
    doc = collection.first _id: name
    unless doc
      doc = {
        _id: name,
        'money'   => 50,
        'cargo'   => false,
        'island'  => Pork::Island.random.id,
        'arrival' => nil
      }
      collection.insert doc
    end
    new doc
  end

  include Pork::Waker

  # schedule a wake for all characters in flight
  def self.wake_start
    collection.find(arrival: {'$ne' => nil}).each do |doc|
      char = new(doc)
      char.wake_at char.arrival
    end
  end

  attr_reader :id, :money, :cargo, :island, :arrival
  alias_method :name, :id

  def initialize doc
    @id      = doc[:_id] || doc['_id']
    @money   = doc['money']
    @cargo   = doc['cargo']
    @island  = doc['island']
    @arrival = doc['arrival'] && Time.at(doc['arrival'])
  end

  def collection
    self.class.collection
  end

  def fly_to island
    unless arrival || Pork::Island[island].nil?
      @island = island
      @arrival = Time.now + 5.minutes

      # save to db
      collection.update({:_id => id}, {'$set' => {
        island: island,
        arrival: arrival.to_i
      }})

      notify
      wake_at arrival
    end
  end

  def buy
    return if arrival
    return if cargo
    @cargo = true
    @money -= Pork::Island[island].price
    collection.update({:_id => id}, {'$set' => {
      cargo: cargo,
      money: money
    }})
    notify
  end

  def sell
    return if arrival
    return unless cargo
    @cargo = false
    @money += Pork::Island[island].price
    collection.update({:_id => id}, {'$set' => {
      cargo: cargo,
      money: money
    }})
    notify
  end

  # alert observers of change
  def notify
    Pork::Notifier.notify [:character, id], self
  end

  # resolve scheduled wake, which can only be an arrival
  def wake time
    return unless arrival
    if arrival <= time
      @arrival = nil
      collection.update({:_id => id}, {'$set' => {arrival: arrival}})
      notify
    else
      wake_at arrival
    end
  end

end
