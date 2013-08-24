class AV.WebSocketSource extends AV.EventEmitter
  constructor: (@serverUrl, @fileName) ->
    if not WebSocket?
      return @emit 'error', 'This browser does not have WebSocket support.'

    @socket = new WebSocket(@serverUrl)

    if not @socket.binaryType?
      @socket.close()
      return @emit 'error', 'This browser does not have binary WebSocket support.'

    @bytesLoaded = 0

    @_setupSocket()

  start: ->
    @_send 'resume'

  pause: ->
    @_send 'pause'

  reset: ->
    @_send 'reset'

  _send: (msg) ->
    if not @open
      # only the latest message is relevant
      # so an array is not used
      @_bufferMessage = msg
    else
      @socket.send msg

  _setupSocket: ->
    @socket.binaryType = 'arraybuffer'

    @socket.onopen = =>
      @open = true
      @socket.send JSON.stringify { @fileName }
      if @_bufferMessage
        @socket.send @_bufferMessage
        @_bufferMessage = null

    @socket.onmessage = (e) =>
      data = e.data

      if typeof data is 'string'
        data = JSON.parse data
        if data.fileSize?
          @length = data.fileSize
        else if data.error?
          @emit 'error', data.error
        else if data.end
          @socket.close()
      else
        buf = new AV.Buffer(new Uint8Array(data))
        @bytesLoaded += buf.length
        if @length
          @emit 'progress', @bytesLoaded / @length * 100
        @emit 'data', buf

    @socket.onclose = (e) =>
      @open = false

      if e.wasClean
        @emit 'end'
      else
        @emit 'error', 'WebSocket closed uncleanly with code ' + e.code + '.'

    @socket.onerror = (err) =>
      @emit 'error', err