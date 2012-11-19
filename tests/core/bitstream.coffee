module 'core/bitstream', ->
    makeBitstream = (bytes) ->
        bytes = new Uint8Array(bytes)
        stream = AV.Stream.fromBuffer(new AV.Buffer(bytes))
        return new AV.Bitstream(stream)
        
    test 'copy', ->
        bitstream = makeBitstream [10, 160], [20, 29, 119]
        copy = bitstream.copy()
        
        assert.notEqual copy, bitstream
        assert.deepEqual copy, bitstream
        
    test 'advance', ->
        bitstream = makeBitstream [10, 160]
        
        assert.equal 0, bitstream.bitPosition
        assert.equal 0, bitstream.offset()
        
        bitstream.advance(2)
        assert.equal 2, bitstream.bitPosition
        assert.equal 2, bitstream.offset()
        
        bitstream.advance(7)
        assert.equal 1, bitstream.bitPosition
        assert.equal 9, bitstream.offset()
        
        assert.throws ->
            bitstream.advance(40)
        , AV.UnderflowError
        
    test 'rewind', ->
        bitstream = makeBitstream [10, 160]
        
        assert.equal 0, bitstream.bitPosition
        assert.equal 0, bitstream.offset()
        
        bitstream.advance(2)
        assert.equal 2, bitstream.bitPosition
        assert.equal 2, bitstream.offset()
        
        bitstream.rewind(2)
        assert.equal 0, bitstream.bitPosition
        assert.equal 0, bitstream.offset()
        
        bitstream.advance(10)
        assert.equal 2, bitstream.bitPosition
        assert.equal 10, bitstream.offset()
        
        bitstream.rewind(4)
        assert.equal 6, bitstream.bitPosition
        assert.equal 6, bitstream.offset()
        
        assert.throws ->
            bitstream.rewind(10)
        , AV.UnderflowError
        
    test 'seek', ->
        bitstream = makeBitstream [10, 160]
        
        assert.equal 0, bitstream.bitPosition
        assert.equal 0, bitstream.offset()
        
        bitstream.seek(3)
        assert.equal 3, bitstream.bitPosition
        assert.equal 3, bitstream.offset()
        
        bitstream.seek(10)
        assert.equal 2, bitstream.bitPosition
        assert.equal 10, bitstream.offset()
        
        bitstream.seek(4)
        assert.equal 4, bitstream.bitPosition
        assert.equal 4, bitstream.offset()
        
        assert.throws ->
            bitstream.seek(100)
        , AV.UnderflowError
        
        assert.throws ->
            bitstream.seek(-10)
        , AV.UnderflowError
        
    test 'align', ->
        bitstream = makeBitstream [10, 160]
        
        assert.equal 0, bitstream.bitPosition
        assert.equal 0, bitstream.offset()
        
        bitstream.align()
        assert.equal 0, bitstream.bitPosition
        assert.equal 0, bitstream.offset()
        
        bitstream.seek(2)
        bitstream.align()
        assert.equal 0, bitstream.bitPosition
        assert.equal 8, bitstream.offset()
        
    test 'read/peek unsigned', ->
        # 0101 1101 0110 1111 1010 1110 1100 1000 -> 0x5d6faec8
        # 0111 0000 1001 1010 0010 0101 1111 0011 -> 0x709a25f3
        bitstream = makeBitstream [0x5d, 0x6f, 0xae, 0xc8, 0x70, 0x9a, 0x25, 0xf3]

        assert.equal 1, bitstream.peek(2)
        assert.equal 1, bitstream.read(2)

        assert.equal 7, bitstream.peek(4)
        assert.equal 7, bitstream.read(4)

        assert.equal 0x16f, bitstream.peek(10)
        assert.equal 0x16f, bitstream.read(10)

        assert.equal 0xaec8, bitstream.peek(16)
        assert.equal 0xaec8, bitstream.read(16)

        assert.equal 0x709a25f3, bitstream.peek(32)
        assert.equal 0x384d12f9, bitstream.peek(31)
        assert.equal 0x384d12f9, bitstream.read(31)

        assert.equal 1, bitstream.peek(1)
        assert.equal 1, bitstream.read(1)

        bitstream = makeBitstream [0x5d, 0x6f, 0xae, 0xc8, 0x70]
        assert.equal 0x5d6faec870, bitstream.peek(40)
        assert.equal 0x5d6faec870, bitstream.read(40)

        bitstream = makeBitstream [0x5d, 0x6f, 0xae, 0xc8, 0x70]
        assert.equal 1, bitstream.read(2)
        assert.equal 0xeb7d7643, bitstream.peek(33)
        assert.equal 0xeb7d7643, bitstream.read(33)
        
        bitstream = makeBitstream [0xff, 0xff, 0xff, 0xff, 0xff]
        assert.equal 0xf, bitstream.peek(4)
        assert.equal 0xff, bitstream.peek(8)
        assert.equal 0xfff, bitstream.peek(12)
        assert.equal 0xffff, bitstream.peek(16)
        assert.equal 0xfffff, bitstream.peek(20)
        assert.equal 0xffffff, bitstream.peek(24)
        assert.equal 0xfffffff, bitstream.peek(28)
        assert.equal 0xffffffff, bitstream.peek(32)
        assert.equal 0xfffffffff, bitstream.peek(36)
        assert.equal 0xffffffffff, bitstream.peek(40)
        
    test 'read/peek signed', ->
        bitstream = makeBitstream [0x5d, 0x6f, 0xae, 0xc8, 0x70, 0x9a, 0x25, 0xf3]

        assert.equal 5, bitstream.peek(4, true)
        assert.equal 5, bitstream.read(4, true)

        assert.equal -3, bitstream.peek(4, true)
        assert.equal -3, bitstream.read(4, true)

        assert.equal 6, bitstream.peek(4, true)
        assert.equal 6, bitstream.read(4, true)

        assert.equal -1, bitstream.peek(4, true)
        assert.equal -1, bitstream.read(4, true)

        assert.equal -82, bitstream.peek(8, true)
        assert.equal -82, bitstream.read(8, true)

        assert.equal -889, bitstream.peek(12, true)
        assert.equal -889, bitstream.read(12, true)

        assert.equal 9, bitstream.peek(8, true)
        assert.equal 9, bitstream.read(8, true)

        assert.equal -191751, bitstream.peek(19, true)
        assert.equal -191751, bitstream.read(19, true)

        assert.equal -1, bitstream.peek(1, true)
        assert.equal -1, bitstream.read(1, true)

        bitstream = makeBitstream [0x5d, 0x6f, 0xae, 0xc8, 0x70, 0x9a, 0x25, 0xf3]
        bitstream.advance(1)

        assert.equal -9278133113, bitstream.peek(35, true)
        assert.equal -9278133113, bitstream.read(35, true)

        bitstream = makeBitstream [0xff, 0xff, 0xff, 0xff, 0xff]
        assert.equal -1, bitstream.peek(4, true)
        assert.equal -1, bitstream.peek(8, true)
        assert.equal -1, bitstream.peek(12, true)
        assert.equal -1, bitstream.peek(16, true)
        assert.equal -1, bitstream.peek(20, true)
        assert.equal -1, bitstream.peek(24, true)
        assert.equal -1, bitstream.peek(28, true)
        assert.equal -1, bitstream.peek(31, true)
        assert.equal -1, bitstream.peek(32, true)
        assert.equal -1, bitstream.peek(36, true)
        assert.equal -1, bitstream.peek(40, true)
        
    test 'readLSB unsigned', ->
        # {     byte 1     }{    byte 2  }
        # { 3   2      1   }{       3    }
        # { 1][111] [1100] }{ [0000 1000 } -> 0xfc08
        bitstream = makeBitstream [0xfc, 0x08]

        assert.equal 12, bitstream.peekLSB(4)
        assert.equal 12, bitstream.readLSB(4)

        assert.equal 7, bitstream.peekLSB(3)
        assert.equal 7, bitstream.readLSB(3)

        assert.equal 0x11, bitstream.peekLSB(9)
        assert.equal 0x11, bitstream.readLSB(9)

        #      4            3           2           1
        # [0111 0000] [1001 1010] [0010 0101] 1[111 0011] -> 0x709a25f3
        bitstream = makeBitstream [0x70, 0x9a, 0x25, 0xf3]
        assert.equal 0xf3259a70, bitstream.peekLSB(32)
        assert.equal 0x73259a70, bitstream.peekLSB(31)
        assert.equal 0x73259a70, bitstream.readLSB(31)

        assert.equal 1, bitstream.peekLSB(1)
        assert.equal 1, bitstream.readLSB(1)

        bitstream = makeBitstream [0xc8, 0x70, 0x9a, 0x25, 0xf3]
        assert.equal 0xf3259a70c8, bitstream.peekLSB(40)
        assert.equal 0xf3259a70c8, bitstream.readLSB(40)

        bitstream = makeBitstream [0x70, 0x9a, 0x25, 0xff, 0xf3]
        assert.equal 0xf3ff259a70, bitstream.peekLSB(40)
        assert.equal 0xf3ff259a70, bitstream.readLSB(40)

        bitstream = makeBitstream [0xff, 0xff, 0xff, 0xff, 0xff]
        assert.equal 0xf, bitstream.peekLSB(4)
        assert.equal 0xff, bitstream.peekLSB(8)
        assert.equal 0xfff, bitstream.peekLSB(12)
        assert.equal 0xffff, bitstream.peekLSB(16)
        assert.equal 0xfffff, bitstream.peekLSB(20)
        assert.equal 0xffffff, bitstream.peekLSB(24)
        assert.equal 0xfffffff, bitstream.peekLSB(28)
        assert.equal 0xffffffff, bitstream.peekLSB(32)
        assert.equal 0xfffffffff, bitstream.peekLSB(36)
        assert.equal 0xffffffffff, bitstream.peekLSB(40)
        
    test 'readLSB signed', ->
        bitstream = makeBitstream [0xfc, 0x08]
        assert.equal -4, bitstream.peekLSB(4, true)
        assert.equal -4, bitstream.readLSB(4, true)

        assert.equal -1, bitstream.peekLSB(3, true)
        assert.equal -1, bitstream.readLSB(3, true)

        assert.equal 0x11, bitstream.peekLSB(9, true)
        assert.equal 0x11, bitstream.readLSB(9, true)

        bitstream = makeBitstream [0x70, 0x9a, 0x25, 0xf3]
        assert.equal -215639440, bitstream.peekLSB(32, true)
        assert.equal -215639440, bitstream.peekLSB(31, true)
        assert.equal -215639440, bitstream.readLSB(31, true)

        assert.equal -1, bitstream.peekLSB(1, true)
        assert.equal -1, bitstream.readLSB(1, true)

        bitstream = makeBitstream [0xc8, 0x70, 0x9a, 0x25, 0xf3]
        assert.equal -55203696440, bitstream.peekLSB(40, true)
        assert.equal -55203696440, bitstream.readLSB(40, true)

        bitstream = makeBitstream [0x70, 0x9a, 0x25, 0xff, 0xf3]
        assert.equal -51553920400, bitstream.peekLSB(40, true)
        assert.equal -51553920400, bitstream.readLSB(40, true)

        bitstream = makeBitstream [0xff, 0xff, 0xff, 0xff, 0xff]
        assert.equal -1, bitstream.peekLSB(4, true)
        assert.equal -1, bitstream.peekLSB(8, true)
        assert.equal -1, bitstream.peekLSB(12, true)
        assert.equal -1, bitstream.peekLSB(16, true)
        assert.equal -1, bitstream.peekLSB(20, true)
        assert.equal -1, bitstream.peekLSB(24, true)
        assert.equal -1, bitstream.peekLSB(28, true)
        assert.equal -1, bitstream.peekLSB(31, true)
        assert.equal -1, bitstream.peekLSB(32, true)
        assert.equal -1, bitstream.peekLSB(36, true)
        assert.equal -1, bitstream.peekLSB(40, true)