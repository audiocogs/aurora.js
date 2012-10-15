class AV.Buffer
    constructor: (@data) ->
        @length = @data.length
    
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