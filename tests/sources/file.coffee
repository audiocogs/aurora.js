#import "../crc32.coffee"

module 'sources/file', ->
    asyncTest = assert.asyncTest
        
    getSource = (fn) ->
        # if we're in Node, we can read any file we like, otherwise simulate by reading 
        # a blob from an XHR and loading it using a FileSource
        if AV.isNode
            fn new AV.FileSource "#{__dirname}/data/m4a/base.m4a"
        else
            xhr = new XMLHttpRequest
            xhr.open 'GET', "#{HTTP_BASE}/data/m4a/base.m4a"
            xhr.responseType = 'blob'
            xhr.send()
            xhr.onload = ->
                fn new AV.FileSource(xhr.response)
    
    asyncTest 'data', ->
        getSource (source) ->
            crc = new CRC32
            source.on 'data', (chunk) ->
                crc.update chunk
            
            source.on 'end', ->
                assert.equal crc.toHex(), '84d9f967'
                assert.start()
            
            source.start()
        
    asyncTest 'progress', ->
        getSource (source) ->
            lastProgress = 0
            source.on 'progress', (progress) ->
                assert.ok progress > lastProgress, 'progress > lastProgress'
                assert.ok progress <= 100, 'progress <= 100'
                lastProgress = progress
            
            source.on 'end', ->
                assert.equal lastProgress, 100
                assert.start()
            
            source.start()