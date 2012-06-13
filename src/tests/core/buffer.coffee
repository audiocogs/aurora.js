Test.module 'core/buffer', ->
    bytes = new Uint8Array([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
    buffer = new Buffer(bytes)
    
    @test 'Buffer#length', ->
        @assert buffer.length is bytes.length
        
    @test 'Buffer#allocate', ->
        @assert Buffer.allocate(10).length is 10
        @assert Buffer.allocate(10).data.length is 10
        
    @test 'Buffer#copy', ->
        @assert buffer.copy().length is bytes.length
        @assert buffer.copy().data isnt bytes
        @deepEqual buffer.copy().data, bytes
    
    @test 'Buffer#slice', ->
        @assert buffer.slice(0, bytes.length + 10).data is bytes
        @assert buffer.slice(0, 4).length is 4
        @deepEqual buffer.slice(3, 6), [3, 4, 5]