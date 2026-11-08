AV = require '../../'
assert = require 'assert'
M4ADemuxer = require '../../src/demuxers/m4a'

describe 'demuxers/m4a co64', ->
    uint32 = (value) ->
        [value >>> 24, value >>> 16 & 255, value >>> 8 & 255, value & 255]

    words = (values...) ->
        bytes = []
        for value in values
            bytes = bytes.concat uint32(value)
        bytes

    atom = (type, parts...) ->
        body = [].concat.apply [], parts
        words(8 + body.length).concat (c.charCodeAt(0) for c in type), body

    movie = (type, offsets) ->
        entries = []
        for offset in offsets
            if type is 'co64'
                entries = entries.concat words(Math.floor(offset / 0x100000000))
            entries = entries.concat words(offset % 0x100000000)

        stbl = atom 'stbl',
            atom('stsd', words(0, 1, 36), [115, 111, 119, 116], words(0, 1, 0, 0), [0, 1, 0, 16], words(0, 44100 * 65536)),
            atom('stts', words(0, 1, offsets.length, 1024)),
            atom('stsc', words(0, 1, 1, 1, 1)),
            atom('stsz', words(0, 2, offsets.length)),
            atom(type, words(0, offsets.length), entries)

        mdia = atom 'mdia',
            atom('mdhd', words(0, 0, 0, 44100, offsets.length * 1024, 0)),
            atom('hdlr', words(0, 0), [115, 111, 117, 110], words(0, 0, 0)),
            atom('minf', stbl)
        atom 'moov', atom('trak', atom('tkhd', words(0, 0, 0, 1)), mdia)

    fixture = (type, moovAtEnd) ->
        ftyp = atom('ftyp', [77, 52, 65, 32], words(0))
        mdat = atom('mdat', [1, 2, 99, 3, 4, 99, 5, 6])
        headers = movie(type, [0, 0, 0])
        start = ftyp.length + 8 + (if moovAtEnd then 0 else headers.length)
        offsets = [start, start + 3, start + 6]
        headers = movie(type, offsets)
        bytes: ftyp.concat(if moovAtEnd then mdat.concat(headers) else headers.concat(mdat))
        offsets: offsets

    parse = (bytes, chunkSize) ->
        source = new AV.EventEmitter
        demuxer = new M4ADemuxer(source, new AV.Buffer(bytes.slice(0, chunkSize)))
        result = data: [], errors: [], demuxer: demuxer
        demuxer.on 'data', (buffer) ->
            result.data = result.data.concat Array.prototype.slice.call(buffer.data)
        demuxer.on 'format', (format) -> result.format = format
        demuxer.on 'error', (error) -> result.errors.push error
        for offset in [chunkSize...bytes.length] by chunkSize
            source.emit 'data', new AV.Buffer(bytes.slice(offset, offset + chunkSize))
        source.emit 'end'
        result

    for type in ['stco', 'co64']
        for moovAtEnd in [false, true]
            for chunkSize in [1, 17, 4096]
                do (type, moovAtEnd, chunkSize) ->
                    it "reads #{type} with moovAtEnd=#{moovAtEnd} in #{chunkSize}-byte chunks", ->
                        input = fixture(type, moovAtEnd)
                        result = parse(input.bytes, chunkSize)
                        assert.deepEqual result.errors, []
                        assert.deepEqual result.data, [1, 2, 3, 4, 5, 6]
                        assert.equal result.format.formatID, 'lpcm'
                        assert.deepEqual result.demuxer.track.chunkOffsets, input.offsets
                        assert.deepEqual result.demuxer.seek(1024),
                            offset: 2
                            position: input.offsets[1]
                            timestamp: 1024

    it 'preserves high and unsigned low words through the seek table', ->
        offsets = [0, 0x80000000, 0xffffffff, 0x100000000, 0x100000001, 0x1ffffffffffffd]
        result = parse(movie('co64', offsets), 7)
        assert.deepEqual result.errors, []
        assert.deepEqual result.demuxer.track.chunkOffsets, offsets
        for position, i in offsets
            assert.deepEqual result.demuxer.seek(i * 1024),
                offset: i * 2
                position: position
                timestamp: i * 1024

    it 'waits for all eight bytes of the final chunk offset', ->
        bytes = movie('co64', [0x100000001, 0x1fffffffffffff])
        source = new AV.EventEmitter
        demuxer = new M4ADemuxer(source, new AV.Buffer(bytes.slice(0, bytes.length - 1)))
        demuxer.readChunk()
        assert.equal demuxer.track, null
        source.emit 'data', new AV.Buffer(bytes.slice(-1))
        assert.deepEqual demuxer.track.chunkOffsets, [0x100000001, 0x1fffffffffffff]
