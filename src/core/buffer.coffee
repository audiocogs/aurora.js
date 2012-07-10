class Buffer
    constructor: (@data) ->
        @length = @data.length
    
    @allocate: (size) ->
        return new Buffer(new Uint8Array(size))
    
    copy: ->
        return new Buffer(new Uint8Array(@data))
    
    slice: (position, length) ->
        if position is 0 and length >= @length
            return new Buffer(@data)
        else
            return new Buffer(@data.subarray(position, position + length))
    
    # prefix-free
    BlobBuilder = window.BlobBuilder or window.MozBlobBuilder or window.WebKitBlobBuilder
    URL = window.URL or window.webkitURL or window.mozURL
    
    @makeBlob: (data) ->
        # try the Blob constructor
        try 
            return new Blob [data]
        
        # use the old BlobBuilder
        if BlobBuilder?
            bb = new BlobBuilder
            bb.append data
            return bb.getBlob()
            
        # oops, no blobs supported :(
        return null
        
    @makeBlobURL: (data) ->
        return URL?.createObjectURL @makeBlob(data)
        
    @revokeBlobURL: (url) ->
        URL?.revokeObjectURL url
    
    toBlob: ->
        return Buffer.makeBlob @data.buffer
        
    toBlobURL: ->
        return Buffer.makeBlobURL @data.buffer