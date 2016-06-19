EventEmitter = require '../../core/events'
AVBuffer = require '../../core/buffer'

class HTTPSource extends EventEmitter
    constructor: (@url, @opts = {}) ->
        @chunkSize = 1 << 20
        @inflight = false
        if @opts.length
            @length = @opts.length
        @reset()
        
    start: ->
        if @length
            return @loop() unless @inflight
        
        @inflight = true
        @xhr = new XMLHttpRequest()
        
        @xhr.onload = (event) =>
            @length = parseInt @xhr.getResponseHeader("Content-Length")                
            @inflight = false
            @loop()
        
        @xhr.onerror = (err) =>
            @pause()
            @emit 'error', err
            
        @xhr.onabort = (event) =>
            @inflight = false
        
        @xhr.open("HEAD", @url, true)
        @xhr.send(null)
        
    loop: ->
        if @inflight or not @length
            return @emit 'error', 'Something is wrong in HTTPSource.loop'
            
        @inflight = true
        @xhr = new XMLHttpRequest()
        
        @xhr.onload = (event) =>
            if @xhr.response
                buf = new Uint8Array(@xhr.response)
            else
                txt = @xhr.responseText
                buf = new Uint8Array(txt.length)
                for i in [0...txt.length]
                    buf[i] = txt.charCodeAt(i) & 0xff

            buffer = new AVBuffer(buf)
            @offset += buffer.length
            
            @emit 'data', buffer
            @emit 'end' if @offset >= @length

            @inflight = false
            @loop() unless @offset >= @length
            
        @xhr.onprogress = (event) =>
            @emit 'progress', (@offset + event.loaded) / @length * 100

        @xhr.onerror = (err) =>
            @emit 'error', err
            @pause()

        @xhr.onabort = (event) =>
            @inflight = false

        @xhr.open("GET", @url, true)
        @xhr.responseType = "arraybuffer"

        endPos = Math.min(@offset + @chunkSize, @length - 1)
        @xhr.setRequestHeader("If-None-Match", "webkit-no-cache")
        @xhr.setRequestHeader("Range", "bytes=#{@offset}-#{endPos}")
        @xhr.overrideMimeType('text/plain; charset=x-user-defined')
        @xhr.send(null)
        
    pause: ->
        @inflight = false
        @xhr?.abort()
        
    reset: ->
        @pause()
        @offset = 0
        
module.exports = HTTPSource
