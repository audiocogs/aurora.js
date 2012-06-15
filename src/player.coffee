#
# The Player class plays back audio data from various sources
# as decoded by the Asset class.  In addition, it handles
# common audio filters like panning and volume adjustment,
# and interfacing with AudioDevices to keep track of the 
# playback time.
#

class Player extends EventEmitter
    window.Player = Player
    
    constructor: (@asset) ->
        @playing = false
        @buffered = 0
        @currentTime = 0
        @duration = 0
        @volume = 100
        @pan = 0 # -50 for left, 50 for right, 0 for center
        @metadata = {}
        
        @filters = [
            new VolumeFilter(this, 'volume')
            new BalanceFilter(this, 'pan')
        ]
        
        @asset.on 'buffer', (@buffered) =>
            @emit 'buffer', @buffered
        
        @asset.on 'decodeStart', =>
            @queue = new Queue(@asset.decoder)
            @queue.once 'ready', @startPlaying
            
        @asset.on 'format', (@format) =>
            @emit 'format', @format
            
        @asset.on 'metadata', (@metadata) =>
            @emit 'metadata', @metadata
            
        @asset.on 'duration', (@duration) =>
            @emit 'duration', @duration
            
        @asset.on 'error', (error) =>
            @emit 'error', error
                
    @fromURL: (url) ->
        asset = Asset.fromURL(url)
        return new Player(asset)
        
    @fromFile: (file) ->
        asset = Asset.fromFile(file)
        return new Player(asset)
        
    preload: ->
        return unless @asset
        
        @startedPreloading = true
        @asset.start()
        
    play: ->
        return if @playing
        
        unless @startedPreloading
            @preload()
        
        @playing = true
        @device?.start()
        
    pause: ->
        return unless @playing
        
        @playing = false
        @device.stop()
        
    togglePlayback: ->
        if @playing
            @pause()
        else
            @play()
        
    stop: ->
        @pause()
        @asset.stop()
        @device?.destroy()
        
    startPlaying: =>
        frame = @queue.read()
        frameOffset = 0
        {format, decoder} = @asset
        div = if decoder.floatingPoint then 1 else Math.pow(2, format.bitsPerChannel - 1)
        
        @device = new AudioDevice(format.sampleRate, format.channelsPerFrame)
        @device.on 'timeUpdate', (@currentTime) =>
            @emit 'progress', @currentTime
        
        @refill = (buffer) =>
            return unless @playing

            bufferOffset = 0
            while frame and bufferOffset < buffer.length
                max = Math.min(frame.length - frameOffset, buffer.length - bufferOffset)
                
                for i in [0...max] by 1
                    buffer[bufferOffset++] = (frame[frameOffset++] / div)
                
                if frameOffset is frame.length
                    frame = @queue.read()
                    frameOffset = 0
            
            # run any applied filters        
            for filter in @filters
                filter.process(buffer)
                
            # if we've run out of data, pause the player
            unless frame
                # if this was the end of the track, make
                # sure the currentTime reflects that
                if decoder.receivedFinalBuffer
                    @currentTime = @duration
                    @emit 'progress', @currentTime
                    @pause()
                else
                    # if we ran out of data in the middle of 
                    # the track, stop the timer but don't change
                    # the playback state
                    @device.stop()
                    
            return
        
        @device.on 'refill', @refill
        @device.start() if @playing
        @emit 'ready'