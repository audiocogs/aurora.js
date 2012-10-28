module 'core/bufferlist', ->
    test 'push', ->
        list = new AV.BufferList
        buffer = new AV.Buffer(new Uint8Array([1, 2, 3]))
        list.push buffer
        
        assert.equal 1, list.availableBuffers
        assert.equal 3, list.availableBytes
        assert.equal buffer, list.first
        
        buffer = new AV.Buffer(new Uint8Array([4, 5, 6]))
        list.push buffer
        
        assert.equal 2, list.availableBuffers
        assert.equal 6, list.availableBytes
        assert.notEqual buffer, list.first
        
    test 'unshift', ->
        list = new AV.BufferList
        buffer = AV.Buffer.allocate(3)
        list.unshift buffer
        
        assert.equal 1, list.availableBuffers
        assert.equal 3, list.availableBytes
        assert.equal buffer, list.first
        
        buffer2 = AV.Buffer.allocate(3)
        list.unshift buffer2
        
        assert.equal 2, list.availableBuffers
        assert.equal 6, list.availableBytes
        assert.equal buffer2, list.first
        
    test 'shift', ->
        list = new AV.BufferList
        buffer1 = AV.Buffer.allocate(3)
        buffer2 = AV.Buffer.allocate(3)
        list.push buffer1
        list.push buffer2
        
        assert.equal 2, list.availableBuffers
        assert.equal 6, list.availableBytes
        
        assert.equal buffer1, list.shift()
        assert.equal 1, list.availableBuffers
        assert.equal 3, list.availableBytes
        assert.equal buffer2, list.first
        
        assert.equal buffer2, list.shift()
        assert.equal 0, list.availableBuffers
        assert.equal 0, list.availableBytes
        assert.equal null, list.first
        
    test 'copy', ->
        list = new AV.BufferList
        buffer = AV.Buffer.allocate(3)
        list.push buffer
        
        copy = list.copy()
        
        assert.equal list.availableBuffers, copy.availableBuffers
        assert.equal list.availableBytes, copy.availableBytes
        assert.equal list.first, copy.first
        assert.notEqual list.buffers, copy.buffers
        assert.deepEqual list.buffers, copy.buffers