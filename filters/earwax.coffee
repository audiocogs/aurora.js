class EarwaxFilter extends Filter
    filt = new Int8Array([
     # 30°  330°
        4,   -6     # 32 tap stereo FIR filter.
        4,  -11     # One side filters as if the
       -1,   -5     # signal was from 30 degrees
        3,    3     # from the ear, the other as
       -2,    5     # if 330 degrees.
       -5,    0     #
        9,    1     #
        6,    3     #                         Input
       -4,   -1     #                   Left         Right
       -5,   -3     #                __________   __________
       -2,   -5     #               |          | |          |
       -7,    1     #           .---|  Hh,0(f) | |  Hh,0(f) |---.
        6,   -7     #          /    |__________| |__________|    \
       30,  -29     #         /                \ /                \
       12,   -3     #        /                  X                  \
       -11,   4     #       /                  / \                  \
       -3,    7     #  ____V_____   __________V   V__________   _____V____
       -20,   23    # |          | |          |   |          | |          |
        2,    0     # | Hh,30(f) | | Hh,330(f)|   | Hh,330(f)| | Hh,30(f) |
        1,   -6     # |__________| |__________|   |__________| |__________|
       -14,  -5     #      \     ___      /           \      ___     /
       15,  -18     #       \   /   \    /    _____    \    /   \   /
        6,    7     #        `->| + |<--'    /     \    `-->| + |<-'
       15,  -10     #           \___/      _/       \_      \___/
       -14,  22     #               \     / \       / \     /
       -7,   -2     #                `--->| |       | |<---'
       -4,    9     #                     \_/       \_/
        6,  -12     #
        6,   -6     #                       Headphones
        0,  -11
        0,   -5
        4,    0
    ])
    
    NUMTAPS = 64
    
    constructor: ->
        @taps = new Float32Array(NUMTAPS * 2)
        
    process: (buffer) ->
        len = buffer.length
        i = 0
        while len--
            output = 0
            
            for i in [NUMTAPS - 1...0] by -1
                @taps[i] = @taps[i - 1]
                output += @taps[i] * filt[i]
                
            @taps[0] = buffer[i] / 64
            output += @taps[0] * filt[0]
            buffer[i++] = output
        
        return