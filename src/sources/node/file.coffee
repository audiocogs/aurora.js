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
        
        @stream.on 'data', (buf) =>
            @loaded += buf.length
            @emit 'progress', @loaded / @size * 100
            @emit 'data', new AVBuffer(new Uint8Array(buf))
    
        @stream.on 'end', =>
            @emit 'end'
            
        @stream.on 'error', (err) =>
            @pause()
            @emit 'error', err
    
    pause: ->
        @stream.pause()
        
module.exports = FileSource
