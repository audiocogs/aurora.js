#import "../crc32.coffee"

module 'sources/buffer', ->
    asyncTest = assert.asyncTest
    buffer = null
    
    getData = (fn) ->
        return fn() if buffer
        
        # if we're in Node, we can read any file we like, otherwise simulate by reading 
        # a blob from an XHR and loading it using a FileSource
        if AV.isNode
            require('fs').readFile "#{__dirname}/data/m4a/base.m4a", (err, data) ->
                buffer = new Uint8Array(data)
                fn()
        else
            xhr = new XMLHttpRequest
            xhr.open 'GET', "#{HTTP_BASE}/data/m4a/base.m4a"
            xhr.responseType = 'arraybuffer'
            xhr.send()
            xhr.onload = ->
                buffer = new Uint8Array(xhr.response)
                fn()
    
    asyncTest 'single AV.Buffer', ->
        getData ->
            crc = new CRC32
            source = new AV.BufferSource new AV.Buffer(buffer)
            
            source.on 'data', (chunk) ->
                crc.update chunk
                
            source.on 'progress', (progress) ->
                assert.equal progress, 100
            
            source.on 'end', ->
                assert.equal crc.toHex(), '84d9f967'
                assert.start()
            
            source.start()
        
    asyncTest 'single Uint8Array', ->
        getData ->
            crc = new CRC32
            source = new AV.BufferSource buffer
        
            source.on 'data', (chunk) ->
                crc.update chunk
            
            source.on 'progress', (progress) ->
                assert.equal progress, 100
        
            source.on 'end', ->
                assert.equal crc.toHex(), '84d9f967'
                assert.start()
        
            source.start()
        
    asyncTest 'single ArrayBuffer', ->
        getData ->
            crc = new CRC32
            source = new AV.BufferSource buffer.buffer
        
            source.on 'data', (chunk) ->
                crc.update chunk
            
            source.on 'progress', (progress) ->
                assert.equal progress, 100
        
            source.on 'end', ->
                assert.equal crc.toHex(), '84d9f967'
                assert.start()
        
            source.start()
        
    asyncTest 'AV.BufferList', ->
        getData ->
            list = new AV.BufferList
            buffers = [
                new AV.Buffer(buffer)
                new AV.Buffer(buffer)
                new AV.Buffer(buffer)
            ]
        
            list.append buffers[0]
            list.append buffers[1]
            list.append buffers[2]
        
            source = new AV.BufferSource list
        
            count = 0
            source.on 'data', (chunk) ->
                assert.equal chunk, buffers[count++]
        
            pcount = 0
            source.on 'progress', (progress) ->
                assert.equal progress, ++pcount / 3 * 100 | 0
        
            source.on 'end', ->
                assert.equal count, 3
                assert.start()
        
            source.start()