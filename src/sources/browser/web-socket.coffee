class AV.WebSocketSource extends AV.EventEmitter
  constructor: (@serverUrl, @fileName) ->
    if not WebSocket?
      return @emit 'error', 'This browser does not have WebSocket support.'

    @socket = new WebSocket(@url)

    if not @socket.binaryType?
      return @emit 'error', 'This browser does not have binary WebSocket support.'

    @_setupSocket(@socket)

  start: ->
    @socket.send 'resume'

  pause: ->
    @socket.send 'pause'

  reset: ->
    @socket.send 'reset'

  _setupSocket: (socket) ->
    @socket.binaryType = 'arraybuffer'

    socket.onmessage = (e) =>
      data = e.data
      if typeof data is 'string'
        if data is 'end'
          @socket.close()
      else
        buf = new AV.Buffer(new Uint8Array(data))
        @emit 'data', buf

    socket.onclose = (e) =>
      if e.wasClean
        @emit 'end'
      else
        @emit 'error', e.reason

    socket.onerror = (err) =>
      @emit 'error', err
