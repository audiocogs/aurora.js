Test.module 'core/stream', ->
    bytesLE = new Uint8Array([10, 160, 20, 29, 119, 98, 0, 195, 245, 72, 64, 241, 212, 200, 83, 251, 
                              33, 9, 64, 72, 101, 108, 108, 111, 32, 119, 111, 114, 108, 100, 33, 0])

    bytesBE = new Uint8Array([10, 20, 160, 0, 98, 119, 29, 64, 72, 245, 195, 64, 9, 33, 251, 83, 200, 
                              212, 241, 72, 101, 108, 108, 111, 32, 119, 111, 114, 108, 100, 33, 0])
                              
    # TODO: test signed ints, 24 bit values, and 80 bit floats
    
    streamLE = Stream.fromBuffer(new Buffer(bytesLE))
    streamBE = Stream.fromBuffer(new Buffer(bytesBE))
    
    @test 'Stream#uint8', ->
        # big endian
        @assert streamBE.peekUInt8() is 10
        @assert streamBE.readUInt8() is 10
        
        # little endian
        @assert streamLE.peekUInt8(0, true) is 10
        @assert streamLE.readUInt8(true) is 10
        
    @test 'Stream#uint16', ->
        # big endian
        @assert streamBE.peekUInt16() is 5280
        @assert streamBE.readUInt16() is 5280

        # little endian
        @assert streamLE.peekUInt16(0, true) is 5280
        @assert streamLE.readUInt16(true) is 5280
        
    @test 'Stream#uint32', ->
        # big endian
        @assert streamBE.peekUInt32() is 6453021
        @assert streamBE.readUInt32() is 6453021

        # little endian
        @assert streamLE.peekUInt32(0, true) is 6453021
        @assert streamLE.readUInt32(true) is 6453021
        
    @test 'Stream#float32', ->
        # big endian
        @assert streamBE.peekFloat32() is 3.140000104904175
        @assert streamBE.readFloat32() is 3.140000104904175

        # little endian
        @assert streamLE.peekFloat32(0, true) is 3.140000104904175
        @assert streamLE.readFloat32(true) is 3.140000104904175
        
    @test 'Stream#float64', ->
        # big endian
        @assert streamBE.peekFloat64() is 3.14159265
        @assert streamBE.readFloat64() is 3.14159265

        # little endian
        @assert streamLE.peekFloat64(0, true) is 3.14159265
        @assert streamLE.readFloat64(true) is 3.14159265
        
    @test 'Stream#string', ->
        @assert streamBE.peekString(0, 12) is 'Hello world!'
        @assert streamBE.peekString(6, 6) is 'world!'
        @assert streamBE.readString(12) is 'Hello world!'
        @assert streamLE.readString(12) is 'Hello world!'
        
    @test 'Stream#copy', ->
        @assert streamLE.copy() isnt streamLE
        @deepEqual streamLE.copy(), streamLE
        
    @test 'Stream#advance', ->
        streamLE.advance(-12)
        @assert streamLE.peekString(0, 12) is 'Hello world!'
        
    @test 'Stream#available', ->
        @assert streamLE.available(12) is true
        @assert streamLE.available(25) is false
        
    @test 'Stream#remainingBytes', ->
        @assert streamLE.remainingBytes() is 13
        
    @test 'Stream#buffer', ->
        @deepEqual streamLE.peekBuffer(2, 12), new Buffer(bytesLE.subarray(21, 31))
        @deepEqual streamLE.readBuffer(12), new Buffer(bytesLE.subarray(19, 31))
        
    @test 'Stream#singleBuffer', ->
        buf1 = new Buffer(new Uint8Array([0, 1, 2, 3]))
        buf2 = new Buffer(new Uint8Array([4, 5, 6, 7]))
        stream = Stream.fromBuffer(buf1)
        stream.list.push(buf2)
        
        @deepEqual stream.peekSingleBuffer(2, 8), buf1.slice(2)
        @deepEqual stream.readSingleBuffer(6), buf1
        @deepEqual stream.readSingleBuffer(3), buf2.slice(2)