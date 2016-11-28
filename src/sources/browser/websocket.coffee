EventEmitter = require '../../core/events'
AVBuffer = require '../../core/buffer'

class WebSocketSource extends EventEmitter
  constructor: (@url, @file) ->
    if not WebSocket?
      return @emit 'error', 'This browser does not have WebSocket support.'

    @socket = new WebSocket(@url)

    if not @socket.binaryType?
      @socket.close()
      return @emit 'error', 'This browser does not have binary WebSocket support.'

    @bytesLoaded = 0
    @_bufferMessage = []
    @wsBuffer = new AVBuffer(new Uint8Array())
    @bufCount = 0
    @ack = false
    @paused = false
    @_setupSocket()

  start: ->
    if (@paused)
        @_send { resume: true }
        @paused = false
    else
        @_send { play: true }

  pause: ->
    @_send { pause: true }
    @pause = true

  reset: ->
    @_send { reset: true }

  _send: (msg) ->
    if not @open
      # only the latest message is relevant
      # so an array is not used to buffer
      @_bufferMessage.push(msg)
    else
      @socket.send JSON.stringify msg

  _syn: ->
    if not @ack
        @_send { syn: true }
        setTimeout =>
            @_syn()
        , 100

  _setupSocket: ->
    @socket.binaryType = 'arraybuffer'

    @socket.onopen = =>
      @open = true
      # send any buffered message
      setTimeout => 
        @_syn()
      , 100

    @socket.onmessage = (e) =>
      data = e.data
      if typeof data is 'string'
        data = JSON.parse data
        if data.ack?
            @ack = true
            if @file
              @_send { @file }
            while @_bufferMessage.length > 0
              @_send @_bufferMessage.shift()
        if data.fileSize?
          @length = data.fileSize
        if data.error?
          @emit 'error', data.error
        if data.end
          @socket.close()
      else
        @bytesLoaded += data.byteLength

        # Need to buffer the first few blocks of data so demuxer has enough data
        if @bufCount < 5
          @wsBuffer.append(data)
          if @bufCount == 4
            if @length
              @emit 'progress', @bytesLoaded / @length * 100
            @emit 'data', @wsBuffer
            @wsBuffer = new AVBuffer(new Uint8Array())
          @bufCount++
        else
          buf = new AVBuffer(new Uint8Array(data))
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

module.exports = WebSocketSource