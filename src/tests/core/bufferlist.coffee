Test.module 'core/bufferlist', ->
    list = new BufferList
    
    @test 'BufferList#push', ->
        buffer = new Buffer(new Uint8Array([1, 2, 3]))
        list.push buffer
        
        @assert list.availableBuffers is 1
        @assert list.availableBytes is 3
        @assert list.first is buffer
        
        buffer = new Buffer(new Uint8Array([4, 5, 6]))
        list.push buffer
        
        @assert list.availableBuffers is 2
        @assert list.availableBytes is 6
        @assert list.first isnt buffer
        
    @test 'BufferList#unshift', ->
        buffer = Buffer.allocate(3)
        list.unshift buffer
        
        @assert list.availableBytes is 9
        @assert list.availableBuffers is 3
        @assert list.first is buffer
        
    @test 'BufferList#shift', ->
        result = list.shift()
        
        @deepEqual result, Buffer.allocate(3)
        @assert list.availableBytes is 6
        @assert list.availableBuffers is 2
        @deepEqual list.first, new Buffer(new Uint8Array([4, 5, 6]))
        
    @test 'BufferList#copy', ->
        other = list.copy()
        
        @assert other.availableBuffers is list.availableBuffers
        @assert other.availableBytes is list.availableBytes
        @assert other.first is list.first
        @assert other.buffers isnt list.buffers
        @deepEqual other.buffers, list.buffers