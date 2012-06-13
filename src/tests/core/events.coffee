Test.module 'core/events', ->
    emitter = new EventEmitter
    fn = null
    times = 0
    
    @test 'EventEmitter#on', ->
        emitter.on 'hello', fn = (a, b) =>
            times++
            @assert a is 'a'
            @assert b is 'b'
            
        emitter.emit 'hello', 'a', 'b'
        emitter.emit 'hello', 'a', 'b'
        
        @assert times is 2
        
    @test 'EventEmitter#off', ->
        emitter.off 'hello', fn
        emitter.emit 'hello', 'a', 'b'
        
        @assert times is 2
        
    @test 'EventEmitter#once', ->
        times = 0
        emitter.once 'hello', ->
            times++
            
        emitter.emit 'hello'
        emitter.emit 'hello'
        emitter.emit 'hello'
        
        @assert times is 1
        
    @test 'EventEmitter#emit', ->
        times = 0
        emitter.on 'foo', ->
            times++
            
        emitter.on 'foo', ->
            times++
            
        emitter.emit 'foo'
        @assert times is 2