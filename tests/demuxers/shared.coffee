AV = require '../../'
assert = require 'assert'
CRC32 = require '../crc32'
{HTTP_BASE} = require '../config'

expect = (count, done) ->
  return ->
    done() if --count is 0

module.exports = (name, config) ->
    it name, (done) ->
        if global.Buffer?
            source = new AV.FileSource "#{__dirname}/../data/#{config.file}"
        else
            source = new AV.HTTPSource "#{HTTP_BASE}/data/#{config.file}"
            
        source.once 'data', (chunk) ->
            Demuxer = AV.Demuxer.find(chunk)
            demuxer = new Demuxer(source, chunk)
                
            expected = config.format? + config.duration? + config.metadata? + config.chapters? + config.cookie? + config.data?
            done = expect(expected, done)
                
            if config.format
                demuxer.once 'format', (format) ->
                    assert.deepEqual format, config.format
                    done()
                    
            if config.duration
                demuxer.once 'duration', (duration) ->
                    assert.equal duration, config.duration
                    done()
                    
            if config.metadata
                demuxer.once 'metadata', (metadata) ->
                    # generate coverArt CRC
                    if metadata.coverArt
                        crc = new CRC32()
                        crc.update metadata.coverArt
                        metadata.coverArt = crc.toHex()
                        
                    assert.deepEqual metadata, config.metadata
                    done()
                        
            if config.chapters
                demuxer.once 'chapters', (chapters) ->
                    assert.deepEqual chapters, config.chapters
                    done()
                        
            if config.data
                crc = new CRC32
                demuxer.on 'data', (buffer) ->
                    crc.update(buffer)
                        
            demuxer.on 'end', ->
                if config.data
                    assert.equal crc.toHex(), config.data
                    done()
                    
                done()
                    
        source.start()