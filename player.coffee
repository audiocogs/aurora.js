class Player extends EventEmitter
    constructor: (@source) ->
        @playing = false
        @buffered = 0
        @currentTime = 0
        @duration = 0
        @volume = 100
        @metadata = {}
        
        @demuxer = null
        @decoder = null
        @queue = null
        @_pausedTime = @_timePaused = 0
        
        @source.once 'data', @probe
        @source.on 'error', (err) =>
            @pause()
            @emit 'error', err
            
        @source.on 'progress', (@buffered) =>
            @emit 'buffer', @buffered
        
    @fromURL: (url) ->
        source = new HTTPSource(url)
        return new Player(source)
        
    @fromFile: (file) ->
        source = new FileSource(file)
        return new Player(source)
        
    preload: ->
        return unless @source
        @source.start()
        
    play: ->
        return if @playing
        
        @playing = true
        @_timer = setInterval =>
            return unless @sink and @playing
            
            time = @sink.getPlaybackTime()
            if @_timePaused > 0
                @_pausedTime += time - @_timePaused
                @_timePaused = 0
            
            @currentTime = (time - @_pausedTime) / 44100 * 1000 | 0
            @emit 'progress', @currentTime if @currentTime > 0
        , 200
        
    pause: ->
        return unless @playing
        
        @playing = false
        clearInterval @_timer
        @_timePaused = @sink?.getPlaybackTime() or 0
        
    stop: ->
        @pause()
        @source.pause()
        @sink?.off 'audioprocess', @refill
        
    probe: (chunk) =>
        demuxer = Demuxer.find(chunk)
        
        if not demuxer
            return @emit 'error', 'A demuxer for this container was not found.'
            
        @demuxer = new demuxer(@source, chunk)
        @demuxer.on 'format', @findDecoder
        @demuxer.on 'duration', (@duration) =>
        @demuxer.on 'metadata', (@metadata) =>
            @emit 'metadata', @metadata
            
        @demuxer.on 'error', (err) =>
            @emit 'error', err
        
    findDecoder: (format) =>
        console.log format
        decoder = Decoder.find(format.formatID)
        
        if not decoder
            return @emit 'error', "A decoder for #{format.formatID} was not found."
            
        @decoder = new decoder(@demuxer, format)
        @decoder.on 'error', (err) =>
            @emit 'error', err
            
        @queue = new Queue(@decoder)
        @queue.on 'ready', @startPlaying
        
    startPlaying: =>
        frame = @queue.read()
        frameOffset = 0
        div = if @decoder.floatingPoint then 1 else Math.pow(2, @decoder.format.bitsPerChannel - 1)
        
        Sink.sinks.moz.prototype.interval = 100
        
        @sink = Sink.singleton()
        @_pausedTime = @sink.getPlaybackTime() # since we're reusing the sink, store the start time
        
        @refill = (buffer, channelCount) =>
            return unless @playing

            bufferOffset = 0
            vol = @volume / 100
            
            while frame and bufferOffset < buffer.length
                max = Math.min(frame.length - frameOffset, buffer.length - bufferOffset)
                for i in [0...max] by 1
                    buffer[bufferOffset + i] = (frame[frameOffset + i] / div) * vol
                    
                bufferOffset += i
                frameOffset += i
                
                if frameOffset is frame.length
                    frame = @queue.read()
                    frameOffset = 0
                    
            return
        
        @sink.on 'audioprocess', @refill    
        @emit 'ready'