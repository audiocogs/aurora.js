#import "../crc32.coffee"

module 'sources/http', ->
    asyncTest = assert.asyncTest
    
    # check that the data returned by the source is correct, using a CRC32 checksum
    asyncTest 'data', ->
        crc = new CRC32
        source = new AV.HTTPSource "#{HTTP_BASE}/data/m4a/base.m4a"
        
        source.on 'data', (chunk) ->
            crc.update chunk
            
        source.on 'end', ->
            assert.equal crc.toHex(), '84d9f967'
            assert.start()
            
        source.start()
        
    asyncTest 'progress', ->
        source = new AV.HTTPSource "#{HTTP_BASE}/data/m4a/base.m4a"
        
        lastProgress = 0
        source.on 'progress', (progress) ->
            assert.ok progress > lastProgress, 'progress > lastProgress'
            assert.ok progress <= 100, 'progress <= 100'
            lastProgress = progress
            
        source.on 'end', ->
            assert.equal lastProgress, 100
            assert.start()
            
        source.start()
        
    asyncTest 'invalid url error', ->
        source = new AV.HTTPSource 'http://dlfigu'
        
        source.on 'error', ->
            assert.ok true
            assert.start()
            
        source.start()
        
    asyncTest '404', ->
        source = new AV.HTTPSource "#{HTTP_BASE}/nothing.m4a"
        
        source.on 'error', (error) ->
            assert.ok true
            assert.start()
            
        source.start()