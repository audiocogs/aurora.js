module 'core/bufferlist', ->
    test 'append', ->
        list = new AV.BufferList
        buffer = new AV.Buffer(new Uint8Array([1, 2, 3]))
        list.append buffer
        
        assert.equal 1, list.availableBuffers
        assert.equal 3, list.availableBytes
        assert.equal buffer, list.first
        assert.equal buffer, list.last
        assert.equal null, buffer.prev
        assert.equal null, buffer.next
        
        buffer2 = new AV.Buffer(new Uint8Array([4, 5, 6]))
        list.append buffer2
        
        assert.equal 2, list.availableBuffers
        assert.equal 6, list.availableBytes
        assert.equal buffer, list.first
        assert.equal buffer2, list.last
        
        assert.equal null, buffer.prev
        assert.equal buffer2, buffer.next
        assert.equal buffer, buffer2.prev
        assert.equal null, buffer2.next
        
    test 'advance', ->
        list = new AV.BufferList
        buffer1 = AV.Buffer.allocate(3)
        buffer2 = AV.Buffer.allocate(3)
        list.append buffer1
        list.append buffer2
        
        assert.equal 2, list.availableBuffers
        assert.equal 6, list.availableBytes
        assert.equal buffer1, list.first
        
        list.advance()
        assert.equal 1, list.availableBuffers
        assert.equal 3, list.availableBytes
        assert.equal buffer2, list.first
        
        list.advance()
        assert.equal 0, list.availableBuffers
        assert.equal 0, list.availableBytes
        assert.equal null, list.first
        
        assert.equal null, list.advance()
        
    test 'rewind', ->
        list = new AV.BufferList
        buffer1 = AV.Buffer.allocate(3)
        buffer2 = AV.Buffer.allocate(3)
        list.append buffer1
        list.append buffer2
        
        assert.equal 2, list.availableBuffers
        assert.equal 6, list.availableBytes
        
        list.advance()
        assert.equal buffer2, list.first
        
        list.rewind()
        assert.equal buffer1, list.first
        
        list.rewind()
        assert.equal null, list.first
        
    test 'copy', ->
        list = new AV.BufferList
        buffer = AV.Buffer.allocate(3)
        list.append buffer

        copy = list.copy()

        assert.equal list.availableBuffers, copy.availableBuffers
        assert.equal list.availableBytes, copy.availableBytes
        assert.equal list.first, copy.first