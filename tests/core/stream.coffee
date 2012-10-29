module 'core/stream', ->
    makeStream = (arrays...) ->
        list = new AV.BufferList
    
        for array in arrays
            list.append new AV.Buffer new Uint8Array(array)
        
        return new AV.Stream(list)
        
    test 'copy', ->
        stream = makeStream [10, 160], [20, 29, 119]
        copy = stream.copy()
        
        assert.notEqual copy, stream
        assert.deepEqual copy, stream
        
    test 'advance', ->
        stream = makeStream [10, 160], [20, 29, 119]
        assert.equal 0, stream.offset
        
        stream.advance(2)
        assert.equal 2, stream.offset
        
    test 'rewind', ->
        stream = makeStream [10, 160], [20, 29, 119]
        
        stream.advance(4)
        assert.equal 4, stream.offset
        assert.equal 2, stream.localOffset
        
        stream.rewind(2)
        assert.equal 2, stream.offset
        assert.equal 0, stream.localOffset
        
        stream.rewind(1)
        assert.equal 1, stream.offset
        assert.equal 1, stream.localOffset
        
        stream.advance(3)
        assert.equal 4, stream.offset
        assert.equal 2, stream.localOffset
        
        stream.rewind(4)
        assert.equal 0, stream.offset
        assert.equal 0, stream.localOffset
        
    test 'seek', ->
        stream = makeStream [10, 160], [20, 29, 119]
        
        stream.seek(3)
        assert.equal 3, stream.offset
        assert.equal 1, stream.localOffset
        
        stream.seek(1)
        assert.equal 1, stream.offset
        assert.equal 1, stream.localOffset
        
    test 'remainingBytes', ->
        stream = makeStream [10, 160], [20, 29, 119]
        assert.equal 5, stream.remainingBytes()
        
        stream.advance(2)
        assert.equal 3, stream.remainingBytes()
        
    test 'buffer', ->
        stream = makeStream [10, 160], [20, 29, 119]
        assert.deepEqual new AV.Buffer(new Uint8Array([10, 160, 20, 29])), stream.peekBuffer(0, 4)
        assert.deepEqual new AV.Buffer(new Uint8Array([160, 20, 29, 119])), stream.peekBuffer(1, 4)
        assert.deepEqual new AV.Buffer(new Uint8Array([10, 160, 20, 29])), stream.readBuffer(4)
        
    test 'single buffer', ->
        stream = makeStream [10, 160], [20, 29, 119]
        assert.deepEqual new AV.Buffer(new Uint8Array([10, 160])), stream.peekSingleBuffer(0, 4)
        assert.deepEqual new AV.Buffer(new Uint8Array([10, 160])), stream.readSingleBuffer(4)

    test 'uint8', ->
        stream = makeStream [10, 160], [20, 29, 119]
        values = [10, 160, 20, 29]

        # check peek with correct offsets across buffers
        for value, i in values
            assert.equal value, stream.peekUInt8(i)

        # check reading across buffers
        for value in values
            assert.equal value, stream.readUInt8()

        # if it were a signed int, would be -1
        stream = makeStream([255, 23])
        assert.equal 255, stream.readUInt8()
        
    test 'int8', ->
        stream = makeStream [0x23, 0xff, 0x87], [0xab, 0x7c, 0xef]
        values = [0x23, -1, -121, -85, 124, -17]

        # peeking
        for value, i in values
            assert.equal value, stream.peekInt8(i)

        # reading
        for value in values
            assert.equal value, stream.readInt8()
            
    test 'uint16', ->
        stream = makeStream [0, 0x23, 0x42], [0x3f]
        copy = stream.copy()

        # peeking big endian
        for value, i in [0x23, 0x2342, 0x423f]
            assert.equal value, stream.peekUInt16(i)

        # peeking little endian
        for value, i in [0x2300, 0x4223, 0x3f42]
            assert.equal value, stream.peekUInt16(i, true)

        # reading big endian
        for value in [0x23, 0x423f]
            assert.equal value, stream.readUInt16()

        # reading little endian
        for value in [0x2300, 0x3f42]
            assert.equal value, copy.readUInt16(true)

        # check that it interprets as unsigned
        stream = makeStream [0xfe, 0xfe]
        assert.equal 0xfefe, stream.peekUInt16(0)
        assert.equal 0xfefe, stream.peekUInt16(0, true)
        
    test 'int16', ->
        stream = makeStream [0x16, 0x79, 0xff], [0x80]
        copy = stream.copy()

        # peeking big endian
        for value, i in [0x1679, -128]
            assert.equal value, stream.peekInt16(i * 2)

        # peeking little endian
        for value, i in [0x7916, -32513]
            assert.equal value, stream.peekInt16(i * 2, true)

        # reading big endian
        for value in [0x1679, -128]
            assert.equal value, stream.readInt16()

        # reading little endian
        for value, i in [0x7916, -32513]
            assert.equal value, copy.readInt16(true)
            
    test 'uint24', ->
        stream = makeStream [0x23, 0x16], [0x56, 0x11, 0x78, 0xaf]
        copy = stream.copy()

        # peeking big endian
        for value, i in [0x231656, 0x165611, 0x561178, 0x1178af]
            assert.equal value, stream.peekUInt24(i)

        # peeking little endian
        for value, i in [0x561623, 0x115616, 0x781156, 0xaf7811]
            assert.equal value, stream.peekUInt24(i, true)

        # reading big endian
        for value in [0x231656, 0x1178af]
            assert.equal value, stream.readUInt24()

        for value in [0x561623, 0xaf7811]
            assert.equal value, copy.readUInt24(true)
            
    test 'int24', ->
        stream = makeStream [0x23, 0x16, 0x56], [0xff, 0x10, 0xfa]
        copy = stream.copy()

        # peeking big endian
        for value, i in [0x231656, 0x1656ff, 0x56ff10, -61190]
            assert.equal value, stream.peekInt24(i)

        # peeking little endian
        for value, i in [0x561623, -43498, 0x10ff56, -388865]
            assert.equal value, stream.peekInt24(i, true)

        # reading big endian
        for value in [0x231656, -61190]
            assert.equal value, stream.readInt24()

        # reading little endian
        for value in [0x561623, -388865]
            assert.equal value, copy.readInt24(true)
            
    test 'uint32', ->
        stream = makeStream [0x32, 0x65, 0x42], [0x56, 0x23], [0xff, 0x45, 0x11]
        copy = stream.copy()

        # peeking big endian
        for value, i in [0x32654256, 0x65425623, 0x425623ff, 0x5623ff45, 0x23ff4511]
            assert.equal value, stream.peekUInt32(i)

        # peeking little endian
        for value, i in [0x56426532, 0x23564265, 0xff235642, 0x45ff2356, 0x1145ff23]
            assert.equal value, stream.peekUInt32(i, true)

        # reading big endian
        for value in [0x32654256, 0x23ff4511]
            assert.equal value, stream.readUInt32()

        # reading little endian
        for value in [0x56426532, 0x1145ff23]
            assert.equal value, copy.readUInt32(true)
            
    test 'int32', ->
        stream = makeStream [0x43, 0x53], [0x16, 0x79, 0xff, 0xfe], [0xef, 0xfa]
        copy = stream.copy()

        stream2 = makeStream [0x42, 0xc3, 0x95], [0xa9, 0x36, 0x17]
        copy2 = stream2.copy()

        # peeking big endian
        for value, i in [0x43531679, -69638]
            assert.equal value, stream.peekInt32(i * 4)

        for value, i in [0x42c395a9, -1013601994, -1784072681]
            assert.equal value, stream2.peekInt32(i)

        # peeking little endian
        for value, i in [0x79165343, -84934913]
            assert.equal value, stream.peekInt32(i * 4, true)

        for value, i in [-1449802942, 917083587, 389458325]
            assert.equal value, stream2.peekInt32(i, true)

        # reading big endian
        for value in [0x43531679, -69638]
            assert.equal value, stream.readInt32()

        # reading little endian
        for value in [0x79165343, -84934913]
            assert.equal value, copy.readInt32(true)

        stream = makeStream [0xff, 0xff, 0xff, 0xff]
        assert.equal -1, stream.peekInt32()
        assert.equal -1, stream.peekInt32(0, true)
        
    test 'float32', ->
        stream = makeStream [0, 0, 0x80], [0x3f, 0, 0, 0, 0xc0], [0xab, 0xaa], 
                            [0xaa, 0x3e, 0, 0, 0, 0], [0, 0, 0], [0x80, 0, 0, 0x80], [0x7f, 0, 0, 0x80, 0xff]
        copy = stream.copy()

        valuesBE = [4.600602988224807e-41, 2.6904930515036488e-43, -1.2126478207002966e-12, 0, 1.793662034335766e-43, 4.609571298396486e-41, 4.627507918739843e-41]
        valuesLE = [1, -2, 0.3333333432674408, 0, 0, Infinity, -Infinity]

        # peeking big endian
        for value, i in valuesBE
            assert.equal value, stream.peekFloat32(i * 4)

        # peeking little endian
        for value, i in valuesLE
            assert.equal value, stream.peekFloat32(i * 4, true)

        # reading big endian
        for value in valuesBE
            assert.equal value, stream.readFloat32()

        # reading little endian
        for value in valuesLE
            assert.equal value, copy.readFloat32(true)

        # special cases
        stream2 = makeStream [0xff, 0xff, 0x7f, 0x7f]
        assert.ok isNaN(stream2.peekFloat32(0))
        assert.equal 3.4028234663852886e+38, stream2.peekFloat32(0, true)
        
    test 'float64', ->
        stream = makeStream [0x55, 0x55, 0x55, 0x55, 0x55, 0x55], [0xd5, 0x3f]
        copy = stream.copy()
        assert.equal 1.1945305291680097e+103, stream.peekFloat64(0)
        assert.equal 0.3333333333333333, stream.peekFloat64(0, true)
        assert.equal 1.1945305291680097e+103, stream.readFloat64()
        assert.equal 0.3333333333333333, copy.readFloat64(true)

        stream = makeStream [1, 0, 0, 0, 0, 0], [0xf0, 0x3f]
        copy = stream.copy()
        assert.equal 7.291122019655968e-304, stream.peekFloat64(0)
        assert.equal 1.0000000000000002, stream.peekFloat64(0, true)
        assert.equal 7.291122019655968e-304, stream.readFloat64()
        assert.equal 1.0000000000000002, copy.readFloat64(true)

        stream = makeStream [2, 0, 0, 0, 0, 0], [0xf0, 0x3f]
        copy = stream.copy()
        assert.equal 4.778309726801735e-299, stream.peekFloat64(0)
        assert.equal 1.0000000000000004, stream.peekFloat64(0, true)
        assert.equal 4.778309726801735e-299, stream.readFloat64()
        assert.equal 1.0000000000000004, copy.readFloat64(true)

        stream = makeStream [0xff, 0xff, 0xff, 0xff, 0xff, 0xff], [0x0f, 0x00]
        copy = stream.copy()
        assert.ok isNaN stream.peekFloat64(0)
        assert.equal 2.225073858507201e-308, stream.peekFloat64(0, true)
        assert.ok isNaN stream.readFloat64()
        assert.equal 2.225073858507201e-308, copy.readFloat64(true)

        stream = makeStream [0xff, 0xff, 0xff, 0xff, 0xff, 0xff], [0xef, 0x7f]
        copy = stream.copy()
        assert.ok isNaN stream.peekFloat64(0)
        assert.equal 1.7976931348623157e+308, stream.peekFloat64(0, true)
        assert.ok isNaN stream.readFloat64()
        assert.equal 1.7976931348623157e+308, copy.readFloat64(true)

        stream = makeStream [0, 0, 0, 0, 0, 0], [0xf0, 0x3f]
        copy = stream.copy()
        assert.equal 3.03865e-319, stream.peekFloat64(0)
        assert.equal 1, stream.peekFloat64(0, true)
        assert.equal 3.03865e-319, stream.readFloat64()
        assert.equal 1, copy.readFloat64(true)

        stream = makeStream [0, 0, 0, 0, 0, 0], [0x10, 0]
        copy = stream.copy()
        assert.equal 2.0237e-320, stream.peekFloat64(0)
        assert.equal 2.2250738585072014e-308, stream.peekFloat64(0, true)
        assert.equal 2.0237e-320, stream.readFloat64()
        assert.equal 2.2250738585072014e-308, copy.readFloat64(true)

        stream = makeStream [0, 0, 0, 0, 0, 0], [0, 0]
        copy = stream.copy()
        assert.equal 0, stream.peekFloat64(0)
        assert.equal 0, stream.peekFloat64(0, true)
        assert.equal false, 1 / stream.peekFloat64(0, true) < 0
        assert.equal 0, stream.readFloat64()
        assert.equal 0, copy.readFloat64(true)

        stream = makeStream [0, 0, 0, 0, 0, 0], [0, 0x80]
        copy = stream.copy()
        assert.equal 6.3e-322, stream.peekFloat64(0)
        assert.equal 0, stream.peekFloat64(0, true)
        assert.equal true, 1 / stream.peekFloat64(0, true) < 0
        assert.equal 6.3e-322, stream.readFloat64()
        assert.equal 0, copy.readFloat64(true)

        stream = makeStream [0, 0, 0, 0, 0, 0], [0xf0, 0x7f]
        copy = stream.copy()
        assert.equal 3.0418e-319, stream.peekFloat64(0)
        assert.equal Infinity, stream.peekFloat64(0, true)
        assert.equal 3.0418e-319, stream.readFloat64()
        assert.equal Infinity, copy.readFloat64(true)

        stream = makeStream [0, 0, 0, 0, 0, 0], [0xf0, 0xff]
        copy = stream.copy()
        assert.equal 3.04814e-319, stream.peekFloat64(0)
        assert.equal -Infinity, stream.peekFloat64(0, true)
        assert.equal 3.04814e-319, stream.readFloat64()
        assert.equal -Infinity, copy.readFloat64(true)
        
    test 'float80', ->
        stream = makeStream [0x3f, 0xff, 0x80, 0x00, 0x00, 0x00], [0x00, 0x00, 0x00, 0x00]
        copy = stream.copy()
        assert.equal 1, stream.peekFloat80()
        assert.equal 0, stream.peekFloat80(0, true)
        assert.equal 1, stream.readFloat80()
        assert.equal 0, copy.readFloat80(true)
        
        stream = makeStream [0x00, 0x00, 0x00], [0x00, 0x00, 0x00, 0x00, 0x80, 0xff, 0x3f]
        assert.equal 1, stream.peekFloat80(0, true)
        assert.equal 1, stream.readFloat80(true)
        
        stream = makeStream [0xbf, 0xff, 0x80, 0x00, 0x00, 0x00], [0x00, 0x00, 0x00, 0x00]
        copy = stream.copy()
        assert.equal -1, stream.peekFloat80()
        assert.equal 0, stream.peekFloat80(0, true)
        assert.equal -1, stream.readFloat80()
        assert.equal 0, copy.readFloat80(true)
        
        stream = makeStream [0x00, 0x00, 0x00], [0x00, 0x00, 0x00, 0x00, 0x80, 0xff, 0xbf]
        assert.equal -1, stream.peekFloat80(0, true)
        assert.equal -1, stream.readFloat80(true)
        
        stream = makeStream [0x40, 0x0e, 0xac, 0x44, 0, 0, 0, 0, 0, 0]
        copy = stream.copy()
        assert.equal 44100, stream.peekFloat80()
        assert.equal 0, stream.peekFloat80(0, true)
        assert.equal 44100, stream.readFloat80()
        assert.equal 0, copy.readFloat80(true)
        
        stream = makeStream [0, 0, 0, 0, 0, 0, 0x44, 0xac, 0x0e, 0x40]
        assert.equal 44100, stream.peekFloat80(0, true)
        assert.equal 44100, stream.readFloat80(true)
        
        stream = makeStream [0x7f, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
        copy = stream.copy()
        assert.equal Infinity, stream.peekFloat80()
        assert.equal 0, stream.peekFloat80(0, true)
        assert.equal Infinity, stream.readFloat80()
        assert.equal 0, copy.readFloat80(true)
        
        stream = makeStream [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0x7f]
        assert.equal Infinity, stream.peekFloat80(0, true)
        assert.equal Infinity, stream.readFloat80(true)
        
        stream = makeStream [0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
        assert.equal -Infinity, stream.peekFloat80()
        assert.equal -Infinity, stream.readFloat80()
        
        stream = makeStream [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff]
        assert.equal -Infinity, stream.peekFloat80(0, true)
        assert.equal -Infinity, stream.readFloat80(true)
        
        stream = makeStream [0x7f, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
        assert.ok isNaN stream.peekFloat80()
        assert.ok isNaN stream.readFloat80()
        
        stream = makeStream [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0x7f]
        assert.ok isNaN stream.peekFloat80(0, true)
        assert.ok isNaN stream.readFloat80(true)
        
        stream = makeStream [0x40, 0x00, 0xc9, 0x0f, 0xda, 0x9e, 0x46, 0xa7, 0x88, 0x00]
        assert.equal 3.14159265, stream.peekFloat80()
        assert.equal 3.14159265, stream.readFloat80()
        
        stream = makeStream [0x00, 0x88, 0xa7, 0x46, 0x9e, 0xda, 0x0f, 0xc9, 0x00, 0x40]
        assert.equal 3.14159265, stream.peekFloat80(0, true)
        assert.equal 3.14159265, stream.readFloat80(true)
        
        stream = makeStream [0x3f, 0xfd, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xa8, 0xff]
        copy = stream.copy()
        assert.equal 0.3333333333333333, stream.peekFloat80()
        assert.equal -Infinity, stream.peekFloat80(0, true)
        assert.equal 0.3333333333333333, stream.readFloat80()
        assert.equal -Infinity, copy.readFloat80(true)
        
        stream = makeStream [0x41, 0x55, 0xaa, 0xaa, 0xaa, 0xaa, 0xae, 0xa9, 0xf8, 0x00]
        assert.equal 1.1945305291680097e+103, stream.peekFloat80()
        assert.equal 1.1945305291680097e+103, stream.readFloat80()
        
    test 'ascii/latin1', ->
        stream = makeStream [0x68, 0x65, 0x6c, 0x6c, 0x6f]
        assert.equal 'hello', stream.peekString(0, 5)
        assert.equal 'hello', stream.peekString(0, 5, 'ascii')
        assert.equal 'hello', stream.peekString(0, 5, 'latin1')
        assert.equal 'hello', stream.readString(5, 'ascii')
        assert.equal 5, stream.offset

    test 'ascii/latin1 null terminated', ->
        stream = makeStream [0x68, 0x65, 0x6c, 0x6c, 0x6f, 0]
        assert.equal 'hello\0', stream.peekString(0, 6)
        assert.equal 'hello', stream.peekString(0, null)
        assert.equal 'hello', stream.readString(null)
        assert.equal 6, stream.offset

    test 'utf8', ->
        stream = makeStream [195, 188, 98, 101, 114]
        assert.equal '√ºber', stream.peekString(0, 5, 'utf8')
        assert.equal '√ºber', stream.readString(5, 'utf8')
        assert.equal 5, stream.offset

        stream = makeStream [0xc3, 0xb6, 0xe6, 0x97, 0xa5, 0xe6, 0x9c, 0xac, 0xe8, 0xaa, 0x9e]
        assert.equal '√∂Êó•Êú¨Ë™û', stream.peekString(0, 11, 'utf8')
        assert.equal '√∂Êó•Êú¨Ë™û', stream.readString(11, 'utf8')
        assert.equal 11, stream.offset

        stream = makeStream [0xf0, 0x9f, 0x91, 0x8d]
        assert.equal 'Ì†ΩÌ±ç', stream.peekString(0, 4, 'utf8')
        assert.equal 'Ì†ΩÌ±ç', stream.readString(4, 'utf8')
        assert.equal 4, stream.offset

        stream = makeStream [0xe2, 0x82, 0xac]
        assert.equal '‚Ç¨', stream.peekString(0, 3, 'utf8')
        assert.equal '‚Ç¨', stream.readString(3, 'utf8')
        assert.equal 3, stream.offset

    test 'utf-8 null terminated', ->
        stream = makeStream [195, 188, 98, 101, 114, 0]
        assert.equal '√ºber', stream.peekString(0, null, 'utf-8')
        assert.equal '√ºber', stream.readString(null, 'utf-8')
        assert.equal 6, stream.offset

        stream = makeStream [0xc3, 0xb6, 0xe6, 0x97, 0xa5, 0xe6, 0x9c, 0xac, 0xe8, 0xaa, 0x9e, 0]
        assert.equal '√∂Êó•Êú¨Ë™û', stream.peekString(0, null, 'utf8')
        assert.equal '√∂Êó•Êú¨Ë™û', stream.readString(null, 'utf8')
        assert.equal 12, stream.offset

        stream = makeStream [0xf0, 0x9f, 0x91, 0x8d, 0]
        assert.equal 'Ì†ΩÌ±ç', stream.peekString(0, null, 'utf8')
        assert.equal 'Ì†ΩÌ±ç', stream.readString(null, 'utf8')
        assert.equal 5, stream.offset

        stream = makeStream [0xe2, 0x82, 0xac, 0]
        assert.equal '‚Ç¨', stream.peekString(0, null, 'utf8')
        assert.equal '‚Ç¨', stream.readString(null, 'utf8')
        assert.equal 4, stream.offset

    test 'utf16be', ->
        stream = makeStream [0, 252, 0, 98, 0, 101, 0, 114]
        assert.equal '√ºber', stream.peekString(0, 8, 'utf16be')
        assert.equal '√ºber', stream.readString(8, 'utf16be')
        assert.equal 8, stream.offset

        stream = makeStream [4, 63, 4, 64, 4, 56, 4, 50, 4, 53, 4, 66]
        assert.equal '–ø—Ä–∏–≤–µ—Ç', stream.peekString(0, 12, 'utf16be')
        assert.equal '–ø—Ä–∏–≤–µ—Ç', stream.readString(12, 'utf16be')
        assert.equal 12, stream.offset

        stream = makeStream [0, 0xf6, 0x65, 0xe5, 0x67, 0x2c, 0x8a, 0x9e]
        assert.equal '√∂Êó•Êú¨Ë™û', stream.peekString(0, 8, 'utf16be')
        assert.equal '√∂Êó•Êú¨Ë™û', stream.readString(8, 'utf16be')
        assert.equal 8, stream.offset

        stream = makeStream [0xd8, 0x3d, 0xdc, 0x4d]
        assert.equal 'Ì†ΩÌ±ç', stream.peekString(0, 4, 'utf16be')
        assert.equal 'Ì†ΩÌ±ç', stream.readString(4, 'utf16be')
        assert.equal 4, stream.offset

    test 'utf16-be null terminated', ->
        stream = makeStream [0, 252, 0, 98, 0, 101, 0, 114, 0, 0]
        assert.equal '√ºber', stream.peekString(0, null, 'utf16-be')
        assert.equal '√ºber', stream.readString(null, 'utf16-be')
        assert.equal 10, stream.offset

        stream = makeStream [4, 63, 4, 64, 4, 56, 4, 50, 4, 53, 4, 66, 0, 0]
        assert.equal '–ø—Ä–∏–≤–µ—Ç', stream.peekString(0, null, 'utf16be')
        assert.equal '–ø—Ä–∏–≤–µ—Ç', stream.readString(null, 'utf16be')
        assert.equal 14, stream.offset

        stream = makeStream [0, 0xf6, 0x65, 0xe5, 0x67, 0x2c, 0x8a, 0x9e, 0, 0]
        assert.equal '√∂Êó•Êú¨Ë™û', stream.peekString(0, null, 'utf16be')
        assert.equal '√∂Êó•Êú¨Ë™û', stream.readString(null, 'utf16be')
        assert.equal 10, stream.offset

        stream = makeStream [0xd8, 0x3d, 0xdc, 0x4d, 0, 0]
        assert.equal 'Ì†ΩÌ±ç', stream.peekString(0, null, 'utf16be')
        assert.equal 'Ì†ΩÌ±ç', stream.readString(null, 'utf16be')
        assert.equal 6, stream.offset

    test 'utf16le', ->
        stream = makeStream [252, 0, 98, 0, 101, 0, 114, 0]
        assert.equal '√ºber', stream.peekString(0, 8, 'utf16le')
        assert.equal '√ºber', stream.readString(8, 'utf16le')
        assert.equal 8, stream.offset

        stream = makeStream [63, 4, 64, 4, 56, 4, 50, 4, 53, 4, 66, 4]
        assert.equal '–ø—Ä–∏–≤–µ—Ç', stream.peekString(0, 12, 'utf16le')
        assert.equal '–ø—Ä–∏–≤–µ—Ç', stream.readString(12, 'utf16le')
        assert.equal 12, stream.offset

        stream = makeStream [0xf6, 0, 0xe5, 0x65, 0x2c, 0x67, 0x9e, 0x8a]
        assert.equal '√∂Êó•Êú¨Ë™û', stream.peekString(0, 8, 'utf16le')
        assert.equal '√∂Êó•Êú¨Ë™û', stream.readString(8, 'utf16le')
        assert.equal 8, stream.offset

        stream = makeStream [0x42, 0x30, 0x44, 0x30, 0x46, 0x30, 0x48, 0x30, 0x4a, 0x30]
        assert.equal '„ÅÇ„ÅÑ„ÅÜ„Åà„Åä', stream.peekString(0, 10, 'utf16le')
        assert.equal '„ÅÇ„ÅÑ„ÅÜ„Åà„Åä', stream.readString(10, 'utf16le')
        assert.equal 10, stream.offset

        stream = makeStream [0x3d, 0xd8, 0x4d, 0xdc]
        assert.equal 'Ì†ΩÌ±ç', stream.peekString(0, 4, 'utf16le')
        assert.equal 'Ì†ΩÌ±ç', stream.readString(4, 'utf16le')
        assert.equal 4, stream.offset

    test 'utf16-le null terminated', ->
        stream = makeStream [252, 0, 98, 0, 101, 0, 114, 0, 0, 0]
        assert.equal '√ºber', stream.peekString(0, null, 'utf16-le')
        assert.equal '√ºber', stream.readString(null, 'utf16-le')
        assert.equal 10, stream.offset

        stream = makeStream [63, 4, 64, 4, 56, 4, 50, 4, 53, 4, 66, 4, 0, 0]
        assert.equal '–ø—Ä–∏–≤–µ—Ç', stream.peekString(0, null, 'utf16le')
        assert.equal '–ø—Ä–∏–≤–µ—Ç', stream.readString(null, 'utf16le')
        assert.equal 14, stream.offset

        stream = makeStream [0xf6, 0, 0xe5, 0x65, 0x2c, 0x67, 0x9e, 0x8a, 0, 0]
        assert.equal '√∂Êó•Êú¨Ë™û', stream.peekString(0, null, 'utf16le')
        assert.equal '√∂Êó•Êú¨Ë™û', stream.readString(null, 'utf16le')
        assert.equal 10, stream.offset

        stream = makeStream [0x42, 0x30, 0x44, 0x30, 0x46, 0x30, 0x48, 0x30, 0x4a, 0x30, 0, 0]
        assert.equal '„ÅÇ„ÅÑ„ÅÜ„Åà„Åä', stream.peekString(0, null, 'utf16le')
        assert.equal '„ÅÇ„ÅÑ„ÅÜ„Åà„Åä', stream.readString(null, 'utf16le')
        assert.equal 12, stream.offset

        stream = makeStream [0x3d, 0xd8, 0x4d, 0xdc, 0, 0]
        assert.equal 'Ì†ΩÌ±ç', stream.peekString(0, null, 'utf16le')
        assert.equal 'Ì†ΩÌ±ç', stream.readString(null, 'utf16le')
        assert.equal 6, stream.offset

    test 'utf16bom big endian', ->
        stream = makeStream [0xfe, 0xff, 0, 252, 0, 98, 0, 101, 0, 114]
        assert.equal '√ºber', stream.peekString(0, 10, 'utf16bom')
        assert.equal '√ºber', stream.readString(10, 'utf16bom')
        assert.equal 10, stream.offset

        stream = makeStream [0xfe, 0xff, 4, 63, 4, 64, 4, 56, 4, 50, 4, 53, 4, 66]
        assert.equal '–ø—Ä–∏–≤–µ—Ç', stream.peekString(0, 14, 'utf16bom')
        assert.equal '–ø—Ä–∏–≤–µ—Ç', stream.readString(14, 'utf16bom')
        assert.equal 14, stream.offset

        stream = makeStream [0xfe, 0xff, 0, 0xf6, 0x65, 0xe5, 0x67, 0x2c, 0x8a, 0x9e]
        assert.equal '√∂Êó•Êú¨Ë™û', stream.peekString(0, 10, 'utf16bom')
        assert.equal '√∂Êó•Êú¨Ë™û', stream.readString(10, 'utf16bom')
        assert.equal 10, stream.offset

        stream = makeStream [0xfe, 0xff, 0xd8, 0x3d, 0xdc, 0x4d]
        assert.equal 'Ì†ΩÌ±ç', stream.peekString(0, 6, 'utf16bom')
        assert.equal 'Ì†ΩÌ±ç', stream.readString(6, 'utf16bom')
        assert.equal 6, stream.offset

    test 'utf16-bom big endian, null terminated', ->
        stream = makeStream [0xfe, 0xff, 0, 252, 0, 98, 0, 101, 0, 114, 0, 0]
        assert.equal '√ºber', stream.peekString(0, null, 'utf16-bom')
        assert.equal '√ºber', stream.readString(null, 'utf16-bom')
        assert.equal 12, stream.offset

        stream = makeStream [0xfe, 0xff, 4, 63, 4, 64, 4, 56, 4, 50, 4, 53, 4, 66, 0, 0]
        assert.equal '–ø—Ä–∏–≤–µ—Ç', stream.peekString(0, null, 'utf16-bom')
        assert.equal '–ø—Ä–∏–≤–µ—Ç', stream.readString(null, 'utf16-bom')
        assert.equal 16, stream.offset

        stream = makeStream [0xfe, 0xff, 0, 0xf6, 0x65, 0xe5, 0x67, 0x2c, 0x8a, 0x9e, 0, 0]
        assert.equal '√∂Êó•Êú¨Ë™û', stream.peekString(0, null, 'utf16bom')
        assert.equal '√∂Êó•Êú¨Ë™û', stream.readString(null, 'utf16bom')
        assert.equal 12, stream.offset

        stream = makeStream [0xfe, 0xff, 0xd8, 0x3d, 0xdc, 0x4d, 0, 0]
        assert.equal 'Ì†ΩÌ±ç', stream.peekString(0, null, 'utf16bom')
        assert.equal 'Ì†ΩÌ±ç', stream.readString(null, 'utf16bom')
        assert.equal 8, stream.offset

    test 'utf16bom little endian', ->
        stream = makeStream [0xff, 0xfe, 252, 0, 98, 0, 101, 0, 114, 0]
        assert.equal '√ºber', stream.peekString(0, 10, 'utf16bom')
        assert.equal '√ºber', stream.readString(10, 'utf16bom')
        assert.equal 10, stream.offset

        stream = makeStream [0xff, 0xfe, 63, 4, 64, 4, 56, 4, 50, 4, 53, 4, 66, 4]
        assert.equal '–ø—Ä–∏–≤–µ—Ç', stream.peekString(0, 14, 'utf16bom')
        assert.equal '–ø—Ä–∏–≤–µ—Ç', stream.readString(14, 'utf16bom')
        assert.equal 14, stream.offset

        stream = makeStream [0xff, 0xfe, 0xf6, 0, 0xe5, 0x65, 0x2c, 0x67, 0x9e, 0x8a]
        assert.equal '√∂Êó•Êú¨Ë™û', stream.peekString(0, 10, 'utf16bom')
        assert.equal '√∂Êó•Êú¨Ë™û', stream.readString(10, 'utf16bom')
        assert.equal 10, stream.offset

        stream = makeStream [0xff, 0xfe, 0x3d, 0xd8, 0x4d, 0xdc]
        assert.equal 'Ì†ΩÌ±ç', stream.peekString(0, 6, 'utf16bom')
        assert.equal 'Ì†ΩÌ±ç', stream.readString(6, 'utf16bom')
        assert.equal 6, stream.offset

    test 'utf16-bom little endian, null terminated', ->
        stream = makeStream [0xff, 0xfe, 252, 0, 98, 0, 101, 0, 114, 0, 0, 0]
        assert.equal '√ºber', stream.peekString(0, null, 'utf16-bom')
        assert.equal '√ºber', stream.readString(null, 'utf16-bom')
        assert.equal 12, stream.offset

        stream = makeStream [0xff, 0xfe, 63, 4, 64, 4, 56, 4, 50, 4, 53, 4, 66, 4, 0, 0]
        assert.equal '–ø—Ä–∏–≤–µ—Ç', stream.peekString(0, null, 'utf16bom')
        assert.equal '–ø—Ä–∏–≤–µ—Ç', stream.readString(null, 'utf16bom')
        assert.equal 16, stream.offset

        stream = makeStream [0xff, 0xfe, 0xf6, 0, 0xe5, 0x65, 0x2c, 0x67, 0x9e, 0x8a, 0, 0]
        assert.equal '√∂Êó•Êú¨Ë™û', stream.peekString(0, null, 'utf16bom')
        assert.equal '√∂Êó•Êú¨Ë™û', stream.readString(null, 'utf16bom')
        assert.equal 12, stream.offset

        stream = makeStream [0xff, 0xfe, 0x3d, 0xd8, 0x4d, 0xdc, 0, 0]
        assert.equal 'Ì†ΩÌ±ç', stream.peekString(0, null, 'utf16bom')
        assert.equal 'Ì†ΩÌ±ç', stream.readString(null, 'utf16bom')
        assert.equal 8, stream.offset