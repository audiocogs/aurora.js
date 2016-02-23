#
# The Asset class is responsible for managing all aspects of the 
# decoding pipeline from source to decoder.  You can use the Asset
# class to inspect information about an audio file, such as its 
# format, metadata, and duration, as well as actually decode the
# file to linear PCM raw audio data.
#

EventEmitter = require './core/events'
HTTPSource   = require './sources/node/http'
FileSource   = require './sources/node/file'
BufferSource = require './sources/buffer'
Demuxer      = require './demuxer'
Decoder      = require './decoder'

class Asset extends EventEmitter
    constructor: (@source) ->
        @buffered = 0
        @duration = null
        @format = null
        @metadata = null
        @active = false
        @demuxer = null
        @decoder = null
                
        @source.once 'data', @probe
        @source.on 'error', (err) =>
            @emit 'error', err
            @stop()
            
        @source.on 'progress', (@buffered) =>
            @emit 'buffer', @buffered
            
    @fromURL: (url, opts) ->
        return new Asset new HTTPSource(url, opts)

    @fromFile: (file) ->
        return new Asset new FileSource(file)
        
    @fromBuffer: (buffer) ->
        return new Asset new BufferSource(buffer)
        
    start: (decode) ->
        return if @active
        
        @shouldDecode = decode if decode?
        @shouldDecode ?= true
        
        @active = true
        @source.start()
        
        if @decoder and @shouldDecode
            @_decode()
        
    stop: ->
        return unless @active
        
        @active = false
        @source.pause()
        
    get: (event, callback) ->
        return unless event in ['format', 'duration', 'metadata']
        
        if this[event]?
            callback(this[event])
        else
            @once event, (value) =>
                @stop()
                callback(value)
            
            @start()
            
    decodePacket: ->
        @decoder.decode()
        
    decodeToBuffer: (callback) ->
        length = 0
        chunks = []
        @on 'data', dataHandler = (chunk) ->
            length += chunk.length
            chunks.push chunk
            
        @once 'end', ->
            buf = new Float32Array(length)
            offset = 0
            
            for chunk in chunks
                buf.set(chunk, offset)
                offset += chunk.length
                
            @off 'data', dataHandler
            callback(buf)
            
        @start()
    
    probe: (chunk) =>
        return unless @active
        
        demuxer = Demuxer.find(chunk)
        if not demuxer
            return @emit 'error', 'A demuxer for this container was not found.'
            
        @demuxer = new demuxer(@source, chunk)
        @demuxer.on 'format', @findDecoder
        
        @demuxer.on 'duration', (@duration) =>
            @emit 'duration', @duration
            
        @demuxer.on 'metadata', (@metadata) =>
            @emit 'metadata', @metadata
            
        @demuxer.on 'error', (err) =>
            @emit 'error', err
            @stop()

    findDecoder: (@format) =>
        return unless @active
        
        @emit 'format', @format
        
        decoder = Decoder.find(@format.formatID)
        if not decoder
            return @emit 'error', "A decoder for #{@format.formatID} was not found."

        @decoder = new decoder(@demuxer, @format)
        
        if @format.floatingPoint
            @decoder.on 'data', (buffer) =>
                @emit 'data', buffer
        else
            div = Math.pow(2, @format.bitsPerChannel - 1)
            @decoder.on 'data', (buffer) =>
                buf = new Float32Array(buffer.length)
                for sample, i in buffer
                    buf[i] = sample / div
                    
                @emit 'data', buf
            
        @decoder.on 'error', (err) =>
            @emit 'error', err
            @stop()
            
        @decoder.on 'end', =>
            @emit 'end'
            
        @emit 'decodeStart'
        @_decode() if @shouldDecode
        
    _decode: =>
        continue while @decoder.decode() and @active
        @decoder.once 'data', @_decode if @active
        
    destroy: ->
        @stop()
        @demuxer?.off()
        @decoder?.off()
        @source?.off()
        @off()
        
module.exports = Asset
