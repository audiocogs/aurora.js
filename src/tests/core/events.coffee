Test.module 'core/events', ->
    emitter = new Aurora.EventEmitter
    fn = null
    times = 0
    
    @test 'Aurora.EventEmitter#on', ->
        emitter.on 'hello', fn = (a, b) =>
            times++
            @assert a is 'a'
            @assert b is 'b'
            
        emitter.emit 'hello', 'a', 'b'
        emitter.emit 'hello', 'a', 'b'
        
        @assert times is 2
        
    @test 'Aurora.EventEmitter#off', ->
        emitter.off 'hello', fn
        emitter.emit 'hello', 'a', 'b'
        
        @assert times is 2
        
    @test 'Aurora.EventEmitter#once', ->
        times = 0
        emitter.once 'hello', ->
            times++
            
        emitter.emit 'hello'
        emitter.emit 'hello'
        emitter.emit 'hello'
        
        @assert times is 1
        
    @test 'Aurora.EventEmitter#emit', ->
        times = 0
        emitter.on 'foo', ->
            times++
            
        emitter.on 'foo', ->
            times++
            
        emitter.emit 'foo'
        @assert times is 2