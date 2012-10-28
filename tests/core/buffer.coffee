module 'core/buffer', ->
    bytes = new Uint8Array([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
    buffer = new AV.Buffer(bytes)
    
    test 'length', ->
        assert.equal 10, buffer.length
        
    test 'allocate', ->
        buf = AV.Buffer.allocate(10)
        assert.equal 10, buf.length
        assert.ok buf.data instanceof Uint8Array
        assert.equal 10, buf.data.length
        
    test 'copy', ->
        copy = buffer.copy()
        
        assert.equal buffer.length, copy.length
        assert.notEqual buffer.data, copy.data
        assert.equal buffer.data.length, copy.data.length
        
    test 'slice', ->
        assert.equal 4, buffer.slice(0, 4).length
        assert.equal bytes, buffer.slice(0, 100).data
        assert.deepEqual new AV.Buffer(bytes.subarray(3, 6)), buffer.slice(3, 3)
        
    if Blob?
        test 'makeBlob', ->
            assert.ok AV.Buffer.makeBlob(bytes) instanceof Blob
        
        test 'makeBlobURL', ->
            assert.equal 'string', typeof AV.Buffer.makeBlobURL(bytes)
        
        test 'toBlob', ->
            assert.ok buffer.toBlob() instanceof Blob
        
        test 'toBlobURL', ->
            assert.equal 'string', typeof buffer.toBlobURL()