#import "../../src/ALAC.coffee"
#import "../../src/ALACDecoder.coffee"
#import "../../src/ag_dec.coffee"
#import "../../src/dp_dec.coffee"
#import "../../src/matrix_dec.coffee"

class ALACDec extends Decoder
    Decoder.register('alac', ALACDec)
    
    setCookie: (buffer) ->
        @decoder = new ALACDecoder(buffer)
        
        # CAF files don't encode the bitsPerChannel
        @format.bitsPerChannel ||= @decoder.config.bitDepth
        
    readChunk: =>
        unless @bitstream.available(4096 << 6)
            @once 'available', @readChunk
        
        else
            out = @decoder.decode(@bitstream)
            
            if out[0] isnt 0
                return @emit 'error', "Error in ALAC decoder: #{out[0]}"
                        
            if out[1]
                @emit 'data', new Int16Array(out[1])