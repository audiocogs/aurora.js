AV = require '../../'
assert = require 'assert'
CRC32 = require '../crc32'
config = require '../config'

describe 'sources/http', ->
    # check that the data returned by the source is correct, using a CRC32 checksum
    it 'data', (done) ->
        crc = new CRC32
        source = new AV.HTTPSource "#{config.HTTP_BASE}/data/m4a/base.m4a"
        
        source.on 'data', (chunk) ->
            crc.update chunk
            
        source.on 'end', ->
            assert.equal crc.toHex(), '84d9f967'
            done()
            
        source.start()
        
    it 'progress', (done) ->
        source = new AV.HTTPSource "#{config.HTTP_BASE}/data/m4a/base.m4a"
        
        lastProgress = 0
        source.on 'progress', (progress) ->
            assert.ok progress > lastProgress, 'progress > lastProgress'
            assert.ok progress <= 100, 'progress <= 100'
            lastProgress = progress
            
        source.on 'end', ->
            assert.equal lastProgress, 100
            done()
            
        source.start()
        
    it 'invalid url error', (done) ->
        source = new AV.HTTPSource 'http://dlfigu'
        
        source.on 'error', ->
            assert.ok true
            done()
            
        source.start()
        
    it '404', (done) ->
        source = new AV.HTTPSource "#{config.HTTP_BASE}/nothing.m4a"
        
        source.on 'error', (error) ->
            assert.ok true
            done()
            
        source.start()