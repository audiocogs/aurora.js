#import "shared.coffee"

module 'demuxers/caf', ->
    demuxerTest 'base', 
        file: 'caf/aac.caf'
        format:
            formatID: 'aac '
            sampleRate: 44100
            bitsPerChannel: 0
            channelsPerFrame: 2
            bytesPerPacket: 0
            framesPerPacket: 1024
        duration: 38659
        data: 'd21b23ee'
        
    demuxerTest 'bei16',
        file: 'caf/bei16.caf'
        format:
            formatID: 'lpcm'
            sampleRate: 44100
            bitsPerChannel: 16
            channelsPerFrame: 2
            bytesPerPacket: 4
            framesPerPacket: 1
            floatingPoint: false
            littleEndian: false
        duration: 38659
        data: '4f427df9'
        
    demuxerTest 'lei32',
        file: 'caf/lei32.caf'
        format:
            formatID: 'lpcm'
            sampleRate: 44100
            bitsPerChannel: 32
            channelsPerFrame: 2
            bytesPerPacket: 8
            framesPerPacket: 1
            floatingPoint: false
            littleEndian: true
        duration: 38659
        data: '771d822a'
        
    demuxerTest 'bef32',
        file: 'caf/bef32.caf'
        format:
            formatID: 'lpcm'
            sampleRate: 44100
            bitsPerChannel: 32
            channelsPerFrame: 2
            bytesPerPacket: 8
            framesPerPacket: 1
            floatingPoint: true
            littleEndian: false
        duration: 38659
        data: '7bf9d9d2'
        
    demuxerTest 'lef64',
        file: 'caf/lef64.caf'
        format:
            formatID: 'lpcm'
            sampleRate: 44100
            bitsPerChannel: 64
            channelsPerFrame: 2
            bytesPerPacket: 16
            framesPerPacket: 1
            floatingPoint: true
            littleEndian: true
        duration: 38659
        data: '9a3372e'