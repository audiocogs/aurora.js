CRC32 = require '../crc32'

module.exports = (name, config) ->
    assert.asyncTest name, ->
        if global.Buffer?
            source = new AV.FileSource "#{__dirname}/../data/#{config.file}"
        else
            source = new AV.HTTPSource "#{HTTP_BASE}/data/#{config.file}"
            
        source.once 'data', (chunk) ->
            Demuxer = AV.Demuxer.find(chunk)
            demuxer = new Demuxer(source, chunk)
                
            expect = config.format? + config.duration? + config.metadata? + config.chapters? + config.cookie? + config.data?
            assert.expect(expect)
                
            if config.format
                demuxer.once 'format', (format) ->
                    assert.deepEqual format, config.format
                    
            if config.duration
                demuxer.once 'duration', (duration) ->
                    assert.equal duration, config.duration
                    
            if config.metadata
                demuxer.once 'metadata', (metadata) ->
                    # generate coverArt CRC
                    if metadata.coverArt
                        crc = new CRC32()
                        crc.update metadata.coverArt
                        metadata.coverArt = crc.toHex()
                        
                    assert.deepEqual metadata, config.metadata
                        
            if config.chapters
                demuxer.once 'chapters', (chapters) ->
                    assert.deepEqual chapters, config.chapters
                        
            if config.data
                crc = new CRC32
                demuxer.on 'data', (buffer) ->
                    crc.update(buffer)
                        
            demuxer.on 'end', ->
                if config.data
                    assert.equal crc.toHex(), config.data
                    
                assert.start()
                    
        source.start()