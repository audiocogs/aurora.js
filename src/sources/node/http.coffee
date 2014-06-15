EventEmitter = require '../../core/events'
AVBuffer = require '../../core/buffer'
http = require 'http'

class HTTPSource extends EventEmitter
    constructor: (@url) ->
        @request = null
        @response = null
        
        @loaded = 0
        @size = 0
        
    start: ->
        if @response?
            return @response.resume()
        
        @request = http.get @url
        @request.on 'response', (@response) =>
            if @response.statusCode isnt 200
                return @errorHandler 'Error loading file. HTTP status code ' + @response.statusCode
            
            @size = parseInt @response.headers['content-length']
            @loaded = 0
            
            @response.on 'data', (chunk) =>
                @loaded += chunk.length
                @emit 'progress', @loaded / @size * 100
                @emit 'data', new AVBuffer(new Uint8Array(chunk))
                
            @response.on 'end', =>
                @emit 'end'
                
            @response.on 'error', @errorHandler
            
        @request.on 'error', @errorHandler
        
    pause: ->
        @response?.pause()
        
    reset: ->
        @pause()
        @request.abort()
        @request = null
        @response = null
        
    errorHandler: (err) =>
        @reset()
        @emit 'error', err
        
module.exports = HTTPSource
