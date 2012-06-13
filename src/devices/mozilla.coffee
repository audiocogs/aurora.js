class MozillaAudioDevice extends EventEmitter
    AudioDevice.register(MozillaAudioDevice)
    
    # determine whether this device is supported by the browser
    @supported: 'mozWriteAudio' of new Audio
    
    constructor: (@sampleRate, @channels) ->        
        @audio = new Audio
        @audio.mozSetup(@channels, @sampleRate)
        
        @writePosition = 0
        @prebufferSize = @sampleRate / 2
        @tail = null
        
        @timer = createTimer @refill, 100
        
    refill: =>
        if @tail
            written = @audio.mozWriteAudio(@tail)
            @writePosition += written
            
            if @tailPosition < @tail.length
                @tail = @tail.subarray(written)
            else    
                @tail = null
            
        currentPosition = @audio.mozCurrentSampleOffset()
        available = currentPosition + @prebufferSize - @writePosition
        if available > 0
            buffer = new Float32Array(available)
            @emit 'refill', buffer
            
            written = @audio.mozWriteAudio(buffer)
            if written < buffer.length
                @tail = buffer.subarray(written)
                
            @writePosition += written
            
        return
        
    destroy: ->
        destroyTimer @timer
        
    getDeviceTime: ->
        return @audio.mozCurrentSampleOffset() / @channels
    
    # Use an inline worker to get setInterval
    # without being clamped in background tabs
    createTimer = (fn, interval) ->
        BlobBuilder = window.BlobBuilder or window.MozBlobBuilder
        unless BlobBuilder and URL and Worker
            return setInterval fn, interval
            
        bb = new BlobBuilder
        bb.append("setInterval(function() { postMessage('ping'); }, #{interval});");
        url	= URL.createObjectURL bb.getBlob()
        
        worker = new Worker(url)
        worker.onmessage = fn
        worker.url = url
        
        return worker
        
    destroyTimer = (timer) ->
        if timer.terminate
            timer.terminate()
            URL.revokeObjectURL(timer.url)
        else
            clearInterval timer