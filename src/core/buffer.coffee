class AV.Buffer
    constructor: (@data) ->
        @length = @data.length
        
        # used when the buffer is part of a bufferlist
        @next = null
        @prev = null
    
    @allocate: (size) ->
        return new AV.Buffer(new Uint8Array(size))
    
    copy: ->
        return new AV.Buffer(new Uint8Array(@data))
    
    slice: (position, length) ->
        if position is 0 and length >= @length
            return new AV.Buffer(@data)
        else
            return new AV.Buffer(@data.subarray(position, position + length))
    
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
        return Buffer.makeBlob @data.buffer
        
    toBlobURL: ->
        return Buffer.makeBlobURL @data.buffer