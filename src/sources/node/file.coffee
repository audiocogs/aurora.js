EventEmitter = require '../../core/events'
AVBuffer = require '../../core/buffer'
fs = require 'fs'

class FileSource extends EventEmitter
    constructor: (@filename) ->
        @stream = null
        @loaded = 0
        @size = null
        
    getSize: ->
        fs.stat @filename, (err, stat) =>
            return @emit 'error', err if err
            
            @size = stat.size
            @start()
        
    start: ->
        if not @size?
            return @getSize()
        
        if @stream
            return @stream.resume()
            
        @stream = fs.createReadStream @filename
        
        b = new Buffer(1 << 20)
        blen = 0
        @stream.on 'data', (buf) =>
            @loaded += buf.length
            buf.copy(b, blen)
            blen = blen + buf.length
            
            @emit 'progress', @loaded / @size * 100
            
            if blen >= b.length or @loaded >= @size
              if blen < b.length
                b = b.slice(0, blen)
                
              @emit 'data', new AVBuffer(new Uint8Array(b))
              blen -= b.length
              buf.copy(b, 0, blen)
    
        @stream.on 'end', =>
            @emit 'end'
            
        @stream.on 'error', (err) =>
            @pause()
            @emit 'error', err
    
    pause: ->
        @stream.pause()
        
module.exports = FileSource
