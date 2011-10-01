Number.prototype.pad = (n,p) ->
  p = p || '0'
  s = '' + this
  while s.length < n
    s = p + s
  s

$ ->

  #
  # MODEL
  #

  # Chat model representing an individual chat message. Attributes:
  # id - unique and chronologically ordered
  # timestamp - unix style timestamp, resolution is seconds
  # name - of sender
  # content - of message
  class Chat extends Backbone.Model



  # Character model attributes:
  # id - name of character
  # money
  # cargo - boolean. Are they carrying stuff or not.
  # island - name of current or destination island
  # arrival - time of arrival or null
  class Character extends Backbone.Model



  # Island model attributes:
  # id - name of island
  # price = of stuff
  class Island extends Backbone.Model



  #
  # COLLECTION
  #

  # Collection of chats received over the socket
  class ChatCollection extends Backbone.Collection
    model: Chat

    # Chats are kept in id order.
    comparator: (chat) -> chat.id



  # Collection of all islands, filled on handshake
  class IslandCollection extends Backbone.Collection
    model: Island



  #
  # VIEW
  #

  # The DOM element for a chat.
  class ChatView extends Backbone.View
    tagName: 'li'

    # defined in index.html
    template: _.template $('#chat-template').html()

    # Render the chat.
    render: ->
      $(@el).html @template timestamp: @formatted_timestamp()

      # Do these with the text function instead of template for XSS
      @$('.name').text @model.get('name')
      @$('.content').text @model.get('content')

      @

    # eg 2000-06-13 14:30
    formatted_timestamp: ->
      d = new Date(@model.get('timestamp') * 1000)
      "#{d.getFullYear()}-#{(d.getMonth() + 1).pad(2)}-#{d.getDate().pad(2)}" +
      " #{d.getHours().pad(2)}:#{d.getMinutes().pad(2)}"



  class ChatCollectionView extends Backbone.View
    el: '#chats'

    events:
      "keypress input" : "emit"
      "click .more"    : "more"

    initialize: ->
      @input = @$ "input"
      @collection.bind 'add', @add

    add: (chat) =>
      view = new ChatView(model: chat).render()
      list = @$("ul")

      # assume new chats come in order and old chats come in reverse order
      if chat == @collection.first()
        list.find('.more').after view.el
      else if chat == @collection.last()
        el = $ view.el
        list.append el
        list.scrollTop el.position().top
        audio.oink()

    # If you hit return in the chat input field, send the message over the
    # socket
    emit: (e) ->
      return unless e.keyCode == 13 # enter/return
      val = @input.val().replace(/^\s*|\s*$/g, '') # strip
      socket.emit('chat', val) if val.length > 0
      @input.val('')

    # fetch earlier chats
    more: -> socket.emit 'more_chats'



  # The DOM element for a character.
  class CharacterView extends Backbone.View
    el: '#character'

    initialize: ->
      @model.bind 'change', @change

    change: =>
      clearTimeout @timeout
      @timeout = null
      arrival = @arrival()
      if arrival? && arrival > 60000
        @timeout = setTimeout =>
          @change()
        , arrival % 60000 || 60000
      @render()

    # Render the character.
    render: =>
      @$('.name').text @model.id
      @$('.money').text "has #{@model.get 'money'} clams,"
      cargo = if @model.get 'cargo'
        'is carrying some stuff,'
      else
        'is not carrying any stuff,'
      @$('.cargo').text cargo

      arrival = @arrival()
      island  = @model.get 'island'
      @flying arrival?
      location = if arrival?
        arrival = Math.ceil(arrival / 60000)
        arrival = if arrival > 1
          "#{arrival} minutes"
        else
          "1 minute"

        "going to #{island} (#{arrival})"
      else
        "at #{island}"

      @$('.location').text "and is #{location}."
      @

    # seconds from now, or null if not in flight
    arrival: ->
      arrival = @model.get 'arrival'
      arrival && arrival - Date.now()

    flying: (flying) ->  $('html').toggleClass 'flying', flying



  # The DOM element for an Island.
  class IslandView extends Backbone.View
    tagName: 'tr'

    events:
      "click button" : "action"

    # defined in index.html
    template: _.template $('#island-template').html()

    initialize: ->
      @model.bind 'change', @fill
      @character = @options.character
      @character.bind 'change', @fill

    # Render the island.
    render: ->
      $(@el).html @template name: @model.id
      @$('img').attr src: "img/#{@model.id}.jpeg"
      @fill()
      @

    fill: =>
      button = if @character.get('island') == @model.id
        if @character.get 'cargo'
          'Sell Stuff'
        else
          'Buy Stuff'
      else
        'Go There'
      @$('button').text(button).attr disabled: @character.get('arrival')?
      @$('.price span').text @model.get 'price'

    action: ->
      if @character.get('island') == @model.id
        if @character.get 'cargo'
          socket.emit 'sell'
        else
          socket.emit 'buy'
        audio.grunt()
      else
        socket.emit 'fly_to', @model.id
        audio.squeal()



  # table of islands
  class IslandCollectionView extends Backbone.View
    el: '#islands'

    initialize: ->
      @collection.bind 'add', @add

    # add an island to the table
    add: (island) =>
      view =
        new IslandView(model: island, character: @options.character).render()
      $(@el).append view.el



  class LoginView extends Backbone.View
    el: '#login'

    events:
      "keypress input" : "login"

    initialize: ->
      @input = @$ "input"
      $(@el).show()

    # If you hit return in the chat input field, send the message over the
    # socket
    login: (e) ->
      return unless e.keyCode == 13
      val = @input.val().replace(/^\s*|\s*$/g, '')
      return unless val.length
      @trigger 'login', val

    hide: ->
      @input.attr disabled: true
      $(@el).fadeOut()



  #
  # SOCKET
  #

  # encapsulates a WebSocket connection
  class Socket
    constructor: (host, port) ->
      _.extend @, Backbone.Events
      @url = "ws://#{host}:#{port}"
      @name = "Socket(#{@url})"
      @ws = new (window.MozWebSocket || window.WebSocket) @url
      @ws.onopen    = @onopen
      @ws.onclose   = @onclose
      @ws.onmessage = @onmessage

    onopen: =>
      @opened = true
      @trigger 'open'

    onclose: => @trigger 'closed'

    # receive JSON array, trigger event called data[0], with remaining data
    # as args on the triggered event
    onmessage: (event) =>
      data = JSON.parse event.data
      console.log ["#{@name} receive #{data[0]}", data]
      @trigger data...

    # send args as JSON array
    emit: (data...) =>
      console.log ["#{@name} emit #{data[0]}", data]
      @ws.send JSON.stringify data



  socket = null
  do ->
    socket = new Socket location.hostname, 37881
    socket.bind 'closed', -> alert "#{@name} failed"

    chats = new ChatCollection
    chats_view = new ChatCollectionView collection: chats
    socket.bind 'chat', (id, timestamp, name, content) ->
      chat = new Chat({id, timestamp, name, content})
      chats.add chat

    character = new Character
    new CharacterView model: character
    socket.bind 'character', (id, money, cargo, island, arrival) ->
      arrival = arrival && Date.now() + arrival * 1000
      character.set {id, money, cargo, island, arrival}
      $('#main').fadeIn()

    islands = new IslandCollection
    islands_view = new IslandCollectionView {collection: islands, character}
    socket.bind 'island', (id, price) ->
      island = new Island({id, price})
      islands.add island
    socket.bind 'price', (id, price) ->
      island = islands.get id
      island.set {price}

    login = new LoginView
    login.bind 'login', (name) ->
      @hide()
      handshake = -> socket.emit 'handshake', name
      if socket.opened then handshake() else socket.bind 'open', handshake


  # audio.oink() to play the oink sound. Also grunt and squeal.
  audio = do ->
    o = {}
    for key in 'oink grunt squeal'.split(' ')
      do (key) ->
        wav = new Audio "audio/#{key}.wav"
        o[key] = ->
          try
            wav.play()
          catch error
            null
    o
