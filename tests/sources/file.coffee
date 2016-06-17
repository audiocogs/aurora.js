AV = require '../../'
assert = require 'assert'
CRC32 = require '../crc32'
config = require '../config'

describe 'sources/file', ->
    getSource = (fn) ->
        # if we're in Node, we can read any file we like, otherwise simulate by reading 
        # a blob from an XHR and loading it using a FileSource
        if global.Buffer?
            fn new AV.FileSource "#{__dirname}/../data/m4a/base.m4a"
        else
            xhr = new XMLHttpRequest
            xhr.open 'GET', "#{config.HTTP_BASE}/data/m4a/base.m4a"
            xhr.responseType = 'blob'
            xhr.send()
            xhr.onload = ->
                fn new AV.FileSource(xhr.response)
    
    it 'data', (done) ->
        getSource (source) ->
            crc = new CRC32
            source.on 'data', (chunk) ->
                crc.update chunk
            
            source.on 'end', ->
                assert.equal crc.toHex(), '84d9f967'
                done()
            
            source.start()
        
    it 'progress', (done) ->
        getSource (source) ->
            lastProgress = 0
            source.on 'progress', (progress) ->
                assert.ok progress > lastProgress, 'progress > lastProgress'
                assert.ok progress <= 100, 'progress <= 100'
                lastProgress = progress
            
            source.on 'end', ->
                assert.equal lastProgress, 100
                done()
            
            source.start()