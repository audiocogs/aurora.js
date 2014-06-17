demuxerTest = require './shared'

describe 'demuxers/m4a', ->
    demuxerTest 'base', 
        file: 'm4a/base.m4a'
        format:
            formatID: 'mp4a'
            sampleRate: 44100
            bitsPerChannel: 16
            channelsPerFrame: 2
            floatingPoint: false
            littleEndian: false
        duration: 38707
        metadata:
            title: 'base'
            album: 'Test Album'
            artist: 'AAC.js'
            comments: 'This is a test description.'
            composer: 'Devon Govett'
            encoder: 'GarageBand 6.0.5'
        data: '89f4b24e'
            
    demuxerTest 'moov atom at end',
        file: 'm4a/moov_end.m4a'
        format:
            formatID: 'mp4a'
            sampleRate: 44100
            bitsPerChannel: 16
            channelsPerFrame: 2
            floatingPoint: false
            littleEndian: false
        duration: 38707
        metadata:
            title: 'moov_end'
            album: 'Test Album'
            artist: 'AAC.js'
            comments: 'This is a test description.'
            composer: 'Devon Govett'
            encoder: 'GarageBand 6.0.5'
            rating: 'None'
        data: '89f4b24e'
            
    demuxerTest 'metadata',
        file: 'm4a/metadata.m4a'
        format:
            formatID: 'mp4a'
            sampleRate: 44100
            bitsPerChannel: 16
            channelsPerFrame: 2
            floatingPoint: false
            littleEndian: false
        duration: 38707
        metadata:
            album: "Album"
            albumArtist: "Album Artist"
            artist: "Artist"
            category: "Category"
            comments: "Comments"
            composer: "Composer"
            coverArt: '4b87a08c'
            copyright: "© Copyright"
            description: "Description"
            diskNumber: "1 of 0"
            encoder: "Encoding Tool"
            genre: "Custom Genre"
            grouping: "Grouping"
            keywords: "Keywords"
            longDescription: "Long Description"
            lyrics: "Lyrics"
            rating: "Clean"
            releaseDate: "Release Date"
            tempo: 100
            title: "Name"
            trackNumber: "1 of 0"
        data: '89f4b24e'
            
    demuxerTest 'text+image chapters',
        file: 'm4a/chapters.m4a'
        duration: 38707
        data: '263ad71d'
        chapters: [
            { title: 'Start', timestamp: 0, duration: 10000 }
            { title: '10 Seconds', timestamp: 10000, duration: 15000 }
            { title: '25 Seconds', timestamp: 25000, duration: 13706 }
        ]
        
    demuxerTest 'text chapters',
        file: 'm4a/chapters2.m4a'
        data: '263ad71d'
        chapters: [
            { title: 'Start', timestamp: 0, duration: 10000 }
            { title: '10 Seconds', timestamp: 10000, duration: 15000 }
            { title: '25 Seconds', timestamp: 25000, duration: 13706 }
        ]
        
    demuxerTest 'text+url chapters',
        file: 'm4a/chapters3.m4a'
        data: '263ad71d'
        chapters: [
            { title: 'Start', timestamp: 0, duration: 10000 }
            { title: '10 Seconds', timestamp: 10000, duration: 15000 }
            { title: '25 Seconds', timestamp: 25000, duration: 13706 }
        ]
        
    demuxerTest 'text+image+url chapters',
        file: 'm4a/chapters4.m4a'
        data: '263ad71d'
        chapters: [
            { title: 'Start', timestamp: 0, duration: 10000 }
            { title: '10 Seconds', timestamp: 10000, duration: 15000 }
            { title: '25 Seconds', timestamp: 25000, duration: 13706 }
        ]
        
    demuxerTest 'alac',
        file: 'm4a/alac.m4a'
        duration: 38659
        data: 'f685e2c0'
        format:
            formatID: 'alac'
            sampleRate: 44100
            bitsPerChannel: 16
            channelsPerFrame: 2
            floatingPoint: false
            littleEndian: false
            
    demuxerTest 'i8',
        file: 'm4a/i8.mov'
        duration: 8916
        data: 'f12b56ad'
        format:
            formatID: 'lpcm'
            sampleRate: 44100
            bitsPerChannel: 8
            channelsPerFrame: 2
            floatingPoint: false
            littleEndian: false
            
    demuxerTest 'bei16',
        file: 'm4a/bei16.mov'
        duration: 8916
        data: 'd07573bd'
        format:
            formatID: 'lpcm'
            sampleRate: 44100
            bitsPerChannel: 16
            channelsPerFrame: 2
            floatingPoint: false
            littleEndian: false
            
    demuxerTest 'lei16',
        file: 'm4a/lei16.mov'
        duration: 8916
        data: '920d2380'
        format:
            formatID: 'lpcm'
            sampleRate: 44100
            bitsPerChannel: 16
            channelsPerFrame: 2
            floatingPoint: false
            littleEndian: true
            
    demuxerTest 'bei32',
        file: 'm4a/bei32.mov'
        duration: 8916
        data: 'dbaa37f7'
        format:
            formatID: 'lpcm'
            sampleRate: 44100
            bitsPerChannel: 32
            channelsPerFrame: 2
            floatingPoint: false
            littleEndian: false
            bytesPerFrame: 8
            framesPerPacket: 1
            
    demuxerTest 'lei32',
        file: 'm4a/lei32.mov'
        duration: 8916
        data: 'a4bd0fad'
        format:
            formatID: 'lpcm'
            sampleRate: 44100
            bitsPerChannel: 32
            channelsPerFrame: 2
            floatingPoint: false
            littleEndian: true
            bytesPerFrame: 8
            framesPerPacket: 1
            
    demuxerTest 'bef32',
        file: 'm4a/bef32.mov'
        duration: 8916
        data: 'e8606b84'
        format:
            formatID: 'lpcm'
            sampleRate: 44100
            bitsPerChannel: 32
            channelsPerFrame: 2
            floatingPoint: true
            littleEndian: false
            bytesPerFrame: 8
            framesPerPacket: 1
            
    demuxerTest 'lef32',
        file: 'm4a/lef32.mov'
        duration: 8916
        data: 'a41981e4'
        format:
            formatID: 'lpcm'
            sampleRate: 44100
            bitsPerChannel: 32
            channelsPerFrame: 2
            floatingPoint: true
            littleEndian: true
            bytesPerFrame: 8
            framesPerPacket: 1
            
    demuxerTest 'ulaw',
        file: 'm4a/ulaw.mov'
        duration: 8916
        data: '49c9d650'
        format:
            formatID: 'ulaw'
            sampleRate: 44100
            bitsPerChannel: 8
            channelsPerFrame: 2
            floatingPoint: false
            littleEndian: false