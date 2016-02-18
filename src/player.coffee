#
# The Player class plays back audio data from various sources
# as decoded by the Asset class.  In addition, it handles
# common audio filters like panning and volume adjustment,
# and interfacing with AudioDevices to keep track of the 
# playback time.
#

EventEmitter = require './core/events'
Asset = require './asset'
VolumeFilter = require './filters/volume'
BalanceFilter = require './filters/balance'
Queue = require './queue'
AudioDevice = require './device'

class Player extends EventEmitter
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
            @queue = new Queue(@asset)
            @queue.once 'ready', @startPlaying
            
        @asset.on 'format', (@format) =>
            @emit 'format', @format
            
        @asset.on 'metadata', (@metadata) =>
            @emit 'metadata', @metadata
            
        @asset.on 'duration', (@duration) =>
            @emit 'duration', @duration
            
        @asset.on 'error', (error) =>
            @emit 'error', error
                
    @fromURL: (url, opts) ->
        return new Player Asset.fromURL(url, opts)
        
    @fromFile: (file) ->
        return new Player Asset.fromFile(file)
        
    @fromBuffer: (buffer) ->
        return new Player Asset.fromBuffer(buffer)
        
    preload: ->
        return unless @asset
        
        @startedPreloading = true
        @asset.start(false)
        
    play: ->
        return if @playing
        
        unless @startedPreloading
            @preload()
        
        @playing = true
        @device?.start()
        
    pause: ->
        return unless @playing
        
        @playing = false
        @device?.stop()
        
    togglePlayback: ->
        if @playing
            @pause()
        else
            @play()
        
    stop: ->
        @pause()
        @asset.stop()
        @device?.destroy()
        
    seek: (timestamp) ->
        @device?.stop()
        @queue.once 'ready', =>
            @device?.seek @currentTime
            @device?.start() if @playing
            
        # convert timestamp to sample number
        timestamp = (timestamp / 1000) * @format.sampleRate
            
        # the actual timestamp we seeked to may differ 
        # from the requested timestamp due to optimizations
        timestamp = @asset.decoder.seek(timestamp)
        
        # convert back from samples to milliseconds
        @currentTime = timestamp / @format.sampleRate * 1000 | 0
        
        @queue.reset()
        return @currentTime
        
    startPlaying: =>
        frame = @queue.read()
        frameOffset = 0
        
        @device = new AudioDevice(@format.sampleRate, @format.channelsPerFrame)
        @device.on 'timeUpdate', (@currentTime) =>
            @emit 'progress', @currentTime
        
        @refill = (buffer) =>
            return unless @playing
            
            # try reading another frame if one isn't already available
            # happens when we play to the end and then seek back
            if not frame
                frame = @queue.read()
                frameOffset = 0

            bufferOffset = 0
            while frame and bufferOffset < buffer.length
                max = Math.min(frame.length - frameOffset, buffer.length - bufferOffset)
                for i in [0...max] by 1
                    buffer[bufferOffset++] = frame[frameOffset++]
                
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
                if @queue.ended
                    @currentTime = @duration
                    @emit 'progress', @currentTime
                    @emit 'end'
                    @stop()
                else
                    # if we ran out of data in the middle of 
                    # the track, stop the timer but don't change
                    # the playback state
                    @device.stop()
                    
            return
        
        @device.on 'refill', @refill
        @device.start() if @playing
        @emit 'ready'
        
    destroy: ->
        @stop()
        @device?.off()
        @asset?.destroy()
        @off()
        
module.exports = Player
