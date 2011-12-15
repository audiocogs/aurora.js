class M4ADemuxer extends Demuxer
    Demuxer.register(M4ADemuxer)
    
    @probe: (buffer) ->
        return buffer.peekString(8, 4) is 'M4A '
        
    # from http://atomicparsley.sourceforge.net/mpeg-4files.html
    metafields = 
        '©alb': 'Album'
        '©arg': 'Arranger'
        '©art': 'Artist'
        '©ART': 'Album Artist'
        'catg': 'Category'
        '©com': 'Composer'
        'covr': 'Cover Art'
        'cpil': 'Compilation'
        '©cpy': 'Copyright'
        'cprt': 'Copyright'
        'desc': 'Description'
        'disk': 'Disk Number'
        '©gen': 'Genre' # custom genres
        'gnre': 'Genre' # standard ones
        '©grp': 'Grouping'
        '©isr': 'ISRC Code'
        'keyw': 'Keyword'
        '©lab': 'Record Label'
        '©lyr': 'Lyrics'
        '©nam': 'Title'
        'pcst': 'Podcast'
        'pgap': 'Gapless'
        '©phg': 'Recording Copyright'
        '©prd': 'Producer'
        '©prf': 'Performers'
        'purl': 'Podcast URL'
        'rtng': 'Rating'
        '©swf': 'Songwriter'
        'tmpo': 'Tempo'
        '©too': 'Encoder'
        'trkn': 'Track Number'
        '©wrt': 'Composer'
        
    genres = [
        "Blues", "Classic Rock", "Country", "Dance", "Disco",
        "Funk", "Grunge", "Hip-Hop", "Jazz", "Metal",
        "New Age", "Oldies", "Other", "Pop", "R&B",
        "Rap", "Reggae", "Rock", "Techno", "Industrial",
        "Alternative", "Ska", "Death Metal", "Pranks", "Soundtrack",
        "Euro-Techno", "Ambient", "Trip-Hop", "Vocal", "Jazz+Funk",
        "Fusion", "Trance", "Classical", "Instrumental", "Acid",
        "House", "Game", "Sound Clip", "Gospel", "Noise",
        "AlternRock", "Bass", "Soul", "Punk", "Space", 
        "Meditative", "Instrumental Pop", "Instrumental Rock", "Ethnic", "Gothic", 
        "Darkwave", "Techno-Industrial", "Electronic", "Pop-Folk", "Eurodance", 
        "Dream", "Southern Rock", "Comedy", "Cult", "Gangsta",
        "Top 40", "Christian Rap", "Pop/Funk", "Jungle", "Native American",
        "Cabaret", "New Wave", "Psychadelic", "Rave", "Showtunes",
        "Trailer", "Lo-Fi", "Tribal", "Acid Punk", "Acid Jazz",
        "Polka", "Retro", "Musical", "Rock & Roll", "Hard Rock",
        "Folk", "Folk/Rock", "National Folk", "Swing", "Fast Fusion",
        "Bebob", "Latin", "Revival", "Celtic", "Bluegrass",
        "Avantgarde", "Gothic Rock", "Progressive Rock", "Psychedelic Rock", "Symphonic Rock",
        "Slow Rock", "Big Band", "Chorus", "Easy Listening", "Acoustic", 
        "Humour", "Speech", "Chanson", "Opera", "Chamber Music", "Sonata", 
        "Symphony", "Booty Bass", "Primus", "Porn Groove", 
        "Satire", "Slow Jam", "Club", "Tango", "Samba", 
        "Folklore", "Ballad", "Power Ballad", "Rhythmic Soul", "Freestyle", 
        "Duet", "Punk Rock", "Drum Solo", "A Capella", "Euro-House",
        "Dance Hall"
    ]
        
    readChunk: ->
        return unless @stream.available(1)
                
        if not @readHeaders and @stream.available(8)
            @len = @stream.readUInt32() - 8
            @type = @stream.readString(4)
            
            return @readChunk() if @len is 0
            @readHeaders = true
            
        if @type is 'mdat'
            buffer = @stream.readSingleBuffer(@len)
            @len -= buffer.length
            @readHeaders = @len > 0
            
            if @sentCookie
                @emit 'data', buffer
            else
                @dataSections ?= []
                @dataSections.push buffer
                
        else if @type is 'meta'
            @stream.advance(4) # random zeros
            
            @metadata = {}
            @readHeaders = false
            @readChunk()
            
            return @emit 'metadata', @metadata
        
        else if @type of metafields
            @metafield = @type
            @readHeaders = false
            
        else if @type is 'data' and @stream.available(@len)
            field = metafields[@metafield]
            @readHeaders = false
        
            switch @metafield
                when 'disk', 'trkn'
                    pos = @stream.offset
                    @stream.advance(10)
                    
                    @metadata[field] = @stream.readUInt16() + ' of ' + @stream.readUInt16()
                    @stream.advance(@len - (@stream.offset - pos))
                    
                when 'cpil', 'pgap', 'pcst'
                    @stream.advance(8)
                    @metadata[field] = @stream.readUInt8() is 1
                    
                when 'gnre'
                    @stream.advance(8)
                    @metadata[field] = genres[@stream.readUInt16() - 1]
                    
                when 'rtng'
                    @stream.advance(8)
                    rating = @stream.readUInt8()
                    @metadata[field] = if rating == 2 then 'Clean' else if rating != 0 then 'Explicit' else 'None'
                
                when 'tmpo'
                    @stream.advance(8)
                    @metadata[field] = @stream.readUInt16()
                    
                when 'covr'
                    return @readChunk() unless @stream.available(@len)
                
                    @stream.advance(8)
                    @metadata[field] = @stream.readBuffer(@len - 8).data.buffer
                    
                else
                    @metadata[field] = decodeURIComponent(escape(@stream.readString(@len))) # UTF-8 decode
                    
        else if @type in ['moov', 'trak', 'mdia', 'minf', 'stbl', 'udta', 'ilst']
            # traverse into these types - they are container atoms
            @readHeaders = false
            
        else if @stream.available(@len)
            switch @type
                when 'ftyp'
                    if @stream.readString(4) isnt 'M4A '
                        return @emit 'error', 'Not a valid M4A file.'
                    
                    @stream.advance(@len - 4)
                    
                when 'mdhd'
                    @stream.advance(4) # version and flags
                    @stream.advance(8) # creation and modification dates
                    
                    sampleRate = @stream.readUInt32()
                    duration = @stream.readUInt32()
                    @emit 'duration', duration / sampleRate * 1000 | 0
                    
                    @stream.advance(4) # language and quality
                    
                when 'stsd'
                    maxpos = @stream.offset + @len
                    @stream.advance(4) # version and flags
                    
                    numEntries = @stream.readUInt32()
                    if numEntries isnt 1
                        return @emit 'error', "Only expecting one entry in sample description atom!"
                        
                    @stream.advance(4) # size
                    
                    @format = {}
                    @format.formatID = @stream.readString(4)
                    
                    @stream.advance(6) # reserved
                    
                    if @stream.readUInt16() isnt 1
                        return @emit 'error', 'Unknown version in stsd atom.'
                    
                    @stream.advance(6) # skip revision level and vendor
                    @stream.advance(2) # reserved
                    
                    @format.channelsPerFrame = @stream.readUInt16()
                    @format.bitsPerChannel = @stream.readUInt16()
                    
                    @stream.advance(4) # skip compression id and packet size
                    
                    @format.sampleRate = @stream.readUInt16()
                    @stream.advance(2)
                    
                    @emit 'format', @format
                    
                    # read the cookie
                    @emit 'cookie', @stream.readBuffer(maxpos - @stream.offset)
                    @sentCookie = true
                    
                    # if the data was already decoded, emit it
                    if @dataSections
                        interval = setInterval =>
                            @emit 'data', @dataSections.shift()
                            clearInterval interval if @dataSections.length is 0
                        , 100
                    
                else
                    @stream.advance(@len)
            
            @readHeaders = false
        else
            console.log @len, @readHeaders, @type, @metafield
            throw 'whoa'
        
        @readChunk()