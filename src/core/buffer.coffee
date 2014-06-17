class AVBuffer
    constructor: (input) ->
        if input instanceof Uint8Array                  # Uint8Array
            @data = input
            
        else if input instanceof ArrayBuffer or         # ArrayBuffer
          Array.isArray(input) or                       # normal JS Array
          typeof input is 'number' or                   # number (i.e. length)
          global.Buffer?.isBuffer(input)                # Node Buffer
            @data = new Uint8Array(input)
            
        else if input.buffer instanceof ArrayBuffer     # typed arrays other than Uint8Array
            @data = new Uint8Array(input.buffer, input.byteOffset, input.length * input.BYTES_PER_ELEMENT)
            
        else if input instanceof AVBuffer               # AVBuffer, make a shallow copy
            @data = input.data
                        
        else
            throw new Error "Constructing buffer with unknown type."
        
        @length = @data.length
        
        # used when the buffer is part of a bufferlist
        @next = null
        @prev = null
    
    @allocate: (size) ->
        return new AVBuffer(size)
    
    copy: ->
        return new AVBuffer(new Uint8Array(@data))
    
    slice: (position, length = @length) ->
        if position is 0 and length >= @length
            return new AVBuffer(@data)
        else
            return new AVBuffer(@data.subarray(position, position + length))
    
    # prefix-free
    BlobBuilder = global.BlobBuilder or global.MozBlobBuilder or global.WebKitBlobBuilder
    URL = global.URL or global.webkitURL or global.mozURL
    
    @makeBlob: (data, type = 'application/octet-stream') ->
        # try the Blob constructor
        try 
            return new Blob [data], type: type
        
        # use the old BlobBuilder
        if BlobBuilder?
            bb = new BlobBuilder
            bb.append data
            return bb.getBlob(type)
            
        # oops, no blobs supported :(
        return null
        
    @makeBlobURL: (data, type) ->
        return URL?.createObjectURL @makeBlob(data, type)
        
    @revokeBlobURL: (url) ->
        URL?.revokeObjectURL url
    
    toBlob: ->
        return AVBuffer.makeBlob @data.buffer
        
    toBlobURL: ->
        return AVBuffer.makeBlobURL @data.buffer
        
module.exports = AVBuffer
