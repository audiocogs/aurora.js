#import "resampler.js"

class WebKitAudioDevice extends AV.EventEmitter
    AV.AudioDevice.register(WebKitAudioDevice)
    
    # determine whether this device is supported by the browser
    AudioContext = global.AudioContext or global.webkitAudioContext
    @supported = false
    if AudioContext
      @supported = typeof AudioContext::createScriptProcessor is 'function' or
        typeof AudioContext::createJavaScriptNode is 'function'
    
    # Chrome limits the number of AudioContexts that one can create,
    # so use a lazily created shared context for all playback
    sharedContext = null
    
    constructor: (@sampleRate, @channels) ->
        @context = sharedContext ?= new AudioContext
        @deviceSampleRate = @context.sampleRate
        
        # calculate the buffer size to read
        @bufferSize = Math.ceil(4096 / (@deviceSampleRate / @sampleRate) * @channels)
        @bufferSize += @bufferSize % @channels
        
        # if the sample rate doesn't match the hardware sample rate, create a resampler
        if @deviceSampleRate isnt @sampleRate
            @resampler = new Resampler(@sampleRate, @deviceSampleRate, @channels, 4096 * @channels)

        @context[processor = 'createScriptProcessor'] or @context[processor = 'createJavaScriptNode']
        @node = @context[processor](4096, @channels, @channels)
        @node.onaudioprocess = @refill
        @node.connect(@context.destination)
        
    refill: (event) =>
        outputBuffer = event.outputBuffer
        channelCount = outputBuffer.numberOfChannels
        channels = new Array(channelCount)
        
        # get output channels
        for i in [0...channelCount] by 1
            channels[i] = outputBuffer.getChannelData(i)
        
        # get audio data    
        data = new Float32Array(@bufferSize)
        @emit 'refill', data
        
        # resample if necessary    
        if @resampler
            data = @resampler.resampler(data)
        
        # write data to output
        for i in [0...outputBuffer.length] by 1
            for n in [0...channelCount] by 1
                channels[n][i] = data[i * channelCount + n]
                
        return
        
    destroy: ->
        @node.disconnect(0)
        
    getDeviceTime: ->
        return @context.currentTime * @sampleRate