#import "../../src/ALAC.coffee"
#import "../../src/ALACDecoder.coffee"
#import "../../src/ag_dec.coffee"
#import "../../src/dp_dec.coffee"
#import "../../src/matrix_dec.coffee"

class ALACDec extends Decoder
    Decoder.register('alac', ALACDec)
    
    setCookie: (buffer) ->
        @decoder = new ALACDecoder(buffer)
        
    readChunk: ->
        return unless @decoder
        
        @waiting = not @bitstream.available(4096 << 6)
        return if @waiting
        
        out = @decoder.decode(@bitstream, @format.framesPerPacket, @format.channelsPerFrame)
        
        if out[0] isnt 0
            return @emit 'error', "Error in ALAC decoder: #{out[0]}"
            
        if out[1]
            @emit 'data', out[1]