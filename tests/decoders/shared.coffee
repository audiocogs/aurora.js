AV = require '../../'
assert = require 'assert'
CRC32 = require '../crc32'
{HTTP_BASE} = require '../config'

module.exports = (name, config) ->
    it name, (done) ->
        if global.Buffer?
            source = new AV.FileSource "#{__dirname}/../data/#{config.file}"
        else
            source = new AV.HTTPSource "#{HTTP_BASE}/data/#{config.file}"
            
        source.once 'data', (chunk) ->
            Demuxer = AV.Demuxer.find(chunk)
            demuxer = new Demuxer(source, chunk)
        
            demuxer.once 'format', (format) ->
                Decoder = AV.Decoder.find(format.formatID)
                decoder = new Decoder(demuxer, format)
                crc = new CRC32

                decoder.on 'data', (chunk) ->
                    crc.update new AV.Buffer(new Uint8Array(chunk.buffer))
                    
                decoder.on 'end', ->
                    assert.equal crc.toHex(), config.data
                    done()
                    
                do read = ->
                    continue while decoder.decode()
                    decoder.once 'data', read
                
        source.start()