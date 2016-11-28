EventEmitter = require '../../core/events'
AVBuffer = require '../../core/buffer'

class WSWorkerSource extends EventEmitter
  constructor: (@url, @file) ->
    @wsBuffer = new AVBuffer(new Uint8Array())
    @bufCount = 0
    @wsWorker = new Worker '/public/js/websocketWorker.js'
    @wsWorker.onmessage = (e) =>
      switch e.data.cmd
        when "data"
          data = e.data.data
          @bytesLoaded += data.byteLength

          # Need to buffer the first four data blocks so demuxer has enough data
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
          
        when "fileSize"
            @length = e.data.value

        when "error"
            @emit "error", e.data.error

        when "end"
            @emit "end"

    @wsWorker.onerror = (e) =>
      @emit "error", e
    
    @wsWorker.postMessage { cmd: "init", config: { host: @url, path: @file } }

  start: ->
    if (@paused)
        @wsWorker.postMessage { cmd: "resume" }
        @paused = false
    else
        @wsWorker.postMessage { cmd: "play" }

  pause: ->
    @wsWorker.postMessage { cmd: "pause" }
    @pause = true

  reset: ->
    @wsWorker.postMessage { cmd: "reset" }


module.exports = WSWorkerSource