demuxerTest = require './shared'

describe 'demuxers/au', ->
    demuxerTest 'bei16', 
        file: 'au/bei16.au'
        format:
            formatID: 'lpcm'
            sampleRate: 44100
            bitsPerChannel: 16
            channelsPerFrame: 2
            bytesPerPacket: 4
            framesPerPacket: 1
            littleEndian: false
            floatingPoint: false
        duration: 7430
        data: 'd4c3bdc0'
        
    demuxerTest 'bef32', 
        file: 'au/bef32.au'
        format:
            formatID: 'lpcm'
            sampleRate: 44100
            bitsPerChannel: 32
            channelsPerFrame: 2
            bytesPerPacket: 8
            framesPerPacket: 1
            littleEndian: false
            floatingPoint: true
        duration: 7430
        data: '52dbaba2'
        
    demuxerTest 'alaw', 
        file: 'au/alaw.au'
        format:
            formatID: 'alaw'
            sampleRate: 44100
            bitsPerChannel: 8
            channelsPerFrame: 2
            bytesPerPacket: 2
            framesPerPacket: 1
            littleEndian: false
            floatingPoint: false
        duration: 7430
        data: 'e49cda0c'
        
    demuxerTest 'ulaw', 
        file: 'au/ulaw.au'
        format:
            formatID: 'ulaw'
            sampleRate: 44100
            bitsPerChannel: 8
            channelsPerFrame: 2
            bytesPerPacket: 2
            framesPerPacket: 1
            littleEndian: false
            floatingPoint: false
        duration: 7430
        data: '18b71b9b'