EventEmitter = require '../core/events'
AudioDevice = require '../device'
Resampler = require './resampler'

class WebAudioDevice extends EventEmitter
    AudioDevice.register(WebAudioDevice)
    
    # determine whether this device is supported by the browser
    AudioContext = global.AudioContext or global.webkitAudioContext
    @supported = AudioContext and 
      (typeof AudioContext::[createProcessor = 'createScriptProcessor'] is 'function' or
      typeof AudioContext::[createProcessor = 'createJavaScriptNode']  is 'function')
    
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
            @resampler = new Resampler(@sampleRate, @deviceSampleRate, @channels, @bufferSize)

        @node = @context[createProcessor](4096, @channels, @channels)
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