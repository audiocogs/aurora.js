describe 'core/buffer', ->
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
        assert.equal 5, buffer.slice(5).length
        
    test 'create from ArrayBuffer', ->
        buf = new AV.Buffer(new ArrayBuffer(9))
        assert.equal 9, buf.length
        assert.ok buf.data instanceof Uint8Array
        assert.equal 9, buf.data.length
        assert.deepEqual buf, new AV.Buffer(new Uint8Array(9))
        
    test 'create from typed array', ->
        buf = new AV.Buffer(new Uint32Array(9))
        assert.equal 36, buf.length
        assert.ok buf.data instanceof Uint8Array
        assert.equal 36, buf.data.length
        assert.deepEqual buf, new AV.Buffer(new Uint8Array(36))
        
    test 'create from sliced typed array', ->
        buf = new AV.Buffer(new Uint32Array(9).subarray(2, 6))
        assert.equal 16, buf.length
        assert.ok buf.data instanceof Uint8Array
        assert.equal 16, buf.data.length
        assert.deepEqual buf, new AV.Buffer(new Uint8Array(new ArrayBuffer(36), 8, 16))
    
    test 'create from array', ->
        buf = new AV.Buffer([1,2,3,4,5,6,7,8,9])
        assert.equal 9, buf.length
        assert.ok buf.data instanceof Uint8Array
        assert.equal 9, buf.data.length
        assert.deepEqual buf, new AV.Buffer(new Uint8Array([1,2,3,4,5,6,7,8,9]))
        
    test 'create from number', ->
        buf = new AV.Buffer(9)
        assert.equal 9, buf.length
        assert.ok buf.data instanceof Uint8Array
        assert.equal 9, buf.data.length
        assert.deepEqual buf, new AV.Buffer(new Uint8Array(9))
        
    test 'create from another AV.Buffer', ->
        buf = new AV.Buffer(new AV.Buffer(9))
        assert.equal 9, buf.length
        assert.ok buf.data instanceof Uint8Array
        assert.equal 9, buf.data.length
        assert.deepEqual buf, new AV.Buffer(new Uint8Array(9))

    if global.Buffer?
        test 'create from node buffer', ->
            buf = new AV.Buffer(new Buffer([1,2,3,4,5,6,7,8,9]))
            assert.equal 9, buf.length
            assert.ok buf.data instanceof Uint8Array
            assert.equal 9, buf.data.length
            assert.deepEqual buf, new AV.Buffer(new Uint8Array([1,2,3,4,5,6,7,8,9]))
            
    test 'error constructing', ->
        assert.throws ->
            new AV.Buffer('some string')
            
        assert.throws ->
            new AV.Buffer(true)
        
    if Blob?
        test 'makeBlob', ->
            assert.ok AV.Buffer.makeBlob(bytes) instanceof Blob
        
        test 'makeBlobURL', ->
            assert.equal 'string', typeof AV.Buffer.makeBlobURL(bytes)
        
        test 'toBlob', ->
            assert.ok buffer.toBlob() instanceof Blob
        
        test 'toBlobURL', ->
            assert.equal 'string', typeof buffer.toBlobURL()