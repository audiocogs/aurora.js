class HTTPSource extends EventEmitter
    constructor: (@url) ->
        @chunkSize = 1 << 20
        @inflight = false
        @reset()
        
    start: ->
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
            console.log("HTTP Aborted: Paused?")
            @inflight = false
        
        @xhr.open("HEAD", @url, true)
        @xhr.send(null)
        
    loop: ->
        if @inflight or not @length
            return @emit 'error', 'Something is wrong in HTTPSource.loop'
            
        if @offset is @length
            @inflight = false
            @emit 'end'
            return
            
        @inflight = true
        @xhr = new XMLHttpRequest()
        
        @xhr.onprogress = (event) =>
            @emit 'progress', (@offset + event.loaded) / @length * 100

        @xhr.onload = (event) =>
            if @xhr.response
                buf = new Uint8Array(@xhr.response)
            else
                txt = @xhr.responseText
                buf = new Uint8Array(txt.length)
                for i in [0...txt.length]
                    buf[i] = txt.charCodeAt(i) & 0xff

            buffer = new Buffer(buf)
            @offset += buffer.length
            
            @emit 'data', buffer, @offset is @length

            @inflight = false
            @loop()

        @xhr.onerror = (err) =>
            @emit 'error', err
            @pause()

        @xhr.onabort = (event) =>
            console.log("HTTP Aborted: Paused?")
            @inflight = false

        @xhr.open("GET", @url, true)
        @xhr.responseType = "arraybuffer"

        endPos = Math.min(@offset + @chunkSize, @length)
        @xhr.setRequestHeader("Range", "bytes=#{@offset}-#{endPos}")
        @xhr.overrideMimeType('text/plain; charset=x-user-defined')
        @xhr.send(null)
        
    pause: ->
        @inflight = false
        @xhr.abort() if @xhr
        
    reset: ->
        @pause()
        @offset = 0