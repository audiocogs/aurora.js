class WebKitAudioDevice extends EventEmitter
    AudioDevice.register(WebKitAudioDevice)
    
    # determine whether this device is supported by the browser
    AudioContext = window.AudioContext or window.webkitAudioContext
    @supported: AudioContext?
    
    # Chrome limits the number of AudioContexts that one can create,
    # so use a lazily created shared context for all playback
    sharedContext = null
    
    constructor: (@sampleRate, @channels) ->
        @context = sharedContext ?= new AudioContext
        @deviceChannels = @context.destination.numberOfChannels
        @deviceSampleRate = @context.sampleRate
        
        @node = @context.createJavaScriptNode(4096, @channels, @channels)
        @node.onaudioprocess = @refill
        @node.connect(@context.destination)
        
    refill: (event) =>
        outputBuffer = event.outputBuffer
        channelCount = outputBuffer.numberOfChannels
        channels = new Array(channelCount)
        
        # TODO: resampling, and down/up mixing
        
        for i in [0...channelCount] by 1
            channels[i] = outputBuffer.getChannelData(i)
            
        data = new Float32Array(outputBuffer.length * channelCount)
        @emit 'refill', data
        
        for i in [0...outputBuffer.length] by 1
            for n in [0...channelCount] by 1
                channels[n][i] = data[i * channelCount + n]
                
        return
        
    destroy: ->
        @node.disconnect(0)
        
    getDeviceTime: ->
        return @context.currentTime * @deviceSampleRate