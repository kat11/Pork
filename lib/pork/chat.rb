# individual chat message
class Pork::Chat
  def self.collection
    Pork.db.collection('chats')
  end

  # 'limit' chats in reverse order
  # most recent or before 'from' chat
  def self.more limit, from
    query = {}
    opts = {limit: limit}
    if from
      query[:_id] = {'$lt' => from.id}
      opts[:order] = [:_id, :desc]
    else
      opts[:order] = ['$natural', :desc]
    end
    collection.find(query, opts).map do |e|
      new e['name'], e['content'], e['_id']
    end
  end

  attr_reader :id, :name, :content

  def initialize name, content, id=BSON::ObjectId.new
    @name    = name
    @content = content
    @id      = id
  end

  # save to db
  def save
    self.class.collection.insert name: name, content: content, _id: @id
    self
  end

  # integer seconds unix timestamp
  def timestamp
    @id.generation_time.to_i
  end

  # these are in insertion order, thanks BSON.
  def id_string
    @id.as_json['$oid']
  end
end
