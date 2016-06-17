AV = require '../../'
assert = require 'assert'

describe 'core/buffer', ->
    bytes = new Uint8Array([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
    buffer = new AV.Buffer(bytes)
    
    it 'length', ->
        assert.equal 10, buffer.length
        
    it 'allocate', ->
        buf = AV.Buffer.allocate(10)
        assert.equal 10, buf.length
        assert.ok buf.data instanceof Uint8Array
        assert.equal 10, buf.data.length
        
    it 'copy', ->
        copy = buffer.copy()
        
        assert.equal buffer.length, copy.length
        assert.notEqual buffer.data, copy.data
        assert.equal buffer.data.length, copy.data.length
        
    it 'slice', ->
        assert.equal 4, buffer.slice(0, 4).length
        assert.equal bytes, buffer.slice(0, 100).data
        assert.deepEqual new AV.Buffer(bytes.subarray(3, 6)), buffer.slice(3, 3)
        assert.equal 5, buffer.slice(5).length
        
    it 'create from ArrayBuffer', ->
        buf = new AV.Buffer(new ArrayBuffer(9))
        assert.equal 9, buf.length
        assert.ok buf.data instanceof Uint8Array
        assert.equal 9, buf.data.length
        assert.deepEqual buf, new AV.Buffer(new Uint8Array(9))
        
    it 'create from typed array', ->
        buf = new AV.Buffer(new Uint32Array(9))
        assert.equal 36, buf.length
        assert.ok buf.data instanceof Uint8Array
        assert.equal 36, buf.data.length
        assert.deepEqual buf, new AV.Buffer(new Uint8Array(36))
        
    it 'create from sliced typed array', ->
        buf = new AV.Buffer(new Uint32Array(9).subarray(2, 6))
        assert.equal 16, buf.length
        assert.ok buf.data instanceof Uint8Array
        assert.equal 16, buf.data.length
        assert.deepEqual buf, new AV.Buffer(new Uint8Array(new ArrayBuffer(36), 8, 16))
    
    it 'create from array', ->
        buf = new AV.Buffer([1,2,3,4,5,6,7,8,9])
        assert.equal 9, buf.length
        assert.ok buf.data instanceof Uint8Array
        assert.equal 9, buf.data.length
        assert.deepEqual buf, new AV.Buffer(new Uint8Array([1,2,3,4,5,6,7,8,9]))
        
    it 'create from number', ->
        buf = new AV.Buffer(9)
        assert.equal 9, buf.length
        assert.ok buf.data instanceof Uint8Array
        assert.equal 9, buf.data.length
        assert.deepEqual buf, new AV.Buffer(new Uint8Array(9))
        
    it 'create from another AV.Buffer', ->
        buf = new AV.Buffer(new AV.Buffer(9))
        assert.equal 9, buf.length
        assert.ok buf.data instanceof Uint8Array
        assert.equal 9, buf.data.length
        assert.deepEqual buf, new AV.Buffer(new Uint8Array(9))

    if global.Buffer?
        it 'create from node buffer', ->
            buf = new AV.Buffer(new Buffer([1,2,3,4,5,6,7,8,9]))
            assert.equal 9, buf.length
            assert.ok buf.data instanceof Uint8Array
            assert.equal 9, buf.data.length
            # assert.deepEqual buf, new AV.Buffer(new Uint8Array([1,2,3,4,5,6,7,8,9]))
            
    it 'error constructing', ->
        assert.throws ->
            new AV.Buffer('some string')
            
        assert.throws ->
            new AV.Buffer(true)
        
    if Blob?
        it 'makeBlob', ->
            assert.ok AV.Buffer.makeBlob(bytes) instanceof Blob
        
        it 'makeBlobURL', ->
            assert.equal 'string', typeof AV.Buffer.makeBlobURL(bytes)
        
        it 'toBlob', ->
            assert.ok buffer.toBlob() instanceof Blob
        
        it 'toBlobURL', ->
            assert.equal 'string', typeof buffer.toBlobURL()