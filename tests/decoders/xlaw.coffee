#import "shared.coffee"

module 'decoders/xlaw', ->
    decoderTest 'alaw',
        file: 'au/alaw.au'
        data: '1543ac89'
        
    decoderTest 'ulaw',
        file: 'm4a/ulaw.mov'
        data: '565b7fd'