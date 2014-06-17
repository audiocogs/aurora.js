Demuxer = require '../demuxer'

class M4ADemuxer extends Demuxer
    Demuxer.register(M4ADemuxer)
    
    # common file type identifiers
    # see http://mp4ra.org/filetype.html for a complete list
    TYPES = ['M4A ', 'M4P ', 'M4B ', 'M4V ', 'isom', 'mp42', 'qt  ']
    
    @probe: (buffer) ->
        return buffer.peekString(4, 4) is 'ftyp' and
               buffer.peekString(8, 4) in TYPES
        
    init: ->
        # current atom heirarchy stacks
        @atoms = []
        @offsets = []
        
        # m4a files can have multiple tracks
        @track = null
        @tracks = []
        
    # lookup table for atom handlers
    atoms = {}
    
    # lookup table of container atom names
    containers = {}
    
    # declare a function to be used for parsing a given atom name
    atom = (name, fn) ->        
        c = []
        for container in name.split('.').slice(0, -1)
            c.push container
            containers[c.join('.')] = true
            
        atoms[name] ?= {}
        atoms[name].fn = fn
        
    # declare a function to be called after parsing of an atom and all sub-atoms has completed
    after = (name, fn) ->
        atoms[name] ?= {}
        atoms[name].after = fn
        
    readChunk: ->
        @break = false
        
        while @stream.available(1) and not @break
            # if we're ready to read a new atom, add it to the stack
            if not @readHeaders
                return unless @stream.available(8)
                
                @len = @stream.readUInt32() - 8
                @type = @stream.readString(4)
                
                continue if @len is 0
                
                @atoms.push @type
                @offsets.push @stream.offset + @len
                @readHeaders = true
                
            # find a handler for the current atom heirarchy
            path = @atoms.join '.'                
            handler = atoms[path]
            
            if handler?.fn
                # wait until we have enough data, unless this is the mdat atom
                return unless @stream.available(@len) or path is 'mdat'

                # call the parser for the atom type
                handler.fn.call(this)
                
                # check if this atom can contain sub-atoms
                if path of containers
                    @readHeaders = false
                    
            # handle container atoms
            else if path of containers
                @readHeaders = false
                
            # unknown atom
            else
                # wait until we have enough data
                return unless @stream.available(@len)
                @stream.advance(@len)
                
            # pop completed items from the stack
            while @stream.offset >= @offsets[@offsets.length - 1]
                # call after handler
                handler = atoms[@atoms.join '.']
                if handler?.after
                    handler.after.call(this)
                
                type = @atoms.pop()
                @offsets.pop()
                @readHeaders = false
                
    atom 'ftyp', ->
        if @stream.readString(4) not in TYPES
            return @emit 'error', 'Not a valid M4A file.'
        
        @stream.advance(@len - 4)
    
    atom 'moov.trak', ->
        @track = {}
        @tracks.push @track
        
    atom 'moov.trak.tkhd', ->
        @stream.advance(4) # version and flags
        
        @stream.advance(8) # creation and modification time
        @track.id = @stream.readUInt32()
        
        @stream.advance(@len - 16)
        
    atom 'moov.trak.mdia.hdlr', ->
        @stream.advance(4) # version and flags
        
        @stream.advance(4) # component type
        @track.type = @stream.readString(4)
        
        @stream.advance(12) # component manufacturer, flags, and mask
        @stream.advance(@len - 24) # component name
    
    atom 'moov.trak.mdia.mdhd', ->
        @stream.advance(4) # version and flags
        @stream.advance(8) # creation and modification dates
        
        @track.timeScale = @stream.readUInt32()
        @track.duration = @stream.readUInt32()
        
        @stream.advance(4) # language and quality
        
    # corrections to bits per channel, base on formatID
    # (ffmpeg appears to always encode the bitsPerChannel as 16)
    BITS_PER_CHANNEL = 
        ulaw: 8
        alaw: 8
        in24: 24
        in32: 32
        fl32: 32
        fl64: 64
        
    atom 'moov.trak.mdia.minf.stbl.stsd', ->
        @stream.advance(4) # version and flags
        
        numEntries = @stream.readUInt32()
        
        # just ignore the rest of the atom if this isn't an audio track
        if @track.type isnt 'soun'
            return @stream.advance(@len - 8)
        
        if numEntries isnt 1
            return @emit 'error', "Only expecting one entry in sample description atom!"
            
        @stream.advance(4) # size
        
        format = @track.format = {}
        format.formatID = @stream.readString(4)
        
        @stream.advance(6) # reserved
        @stream.advance(2) # data reference index
        
        version = @stream.readUInt16()
        @stream.advance(6) # skip revision level and vendor
        
        format.channelsPerFrame = @stream.readUInt16()
        format.bitsPerChannel = @stream.readUInt16()
        
        @stream.advance(4) # skip compression id and packet size
        
        format.sampleRate = @stream.readUInt16()
        @stream.advance(2)
        
        if version is 1
            format.framesPerPacket = @stream.readUInt32()
            @stream.advance(4) # bytes per packet
            format.bytesPerFrame = @stream.readUInt32()
            @stream.advance(4) # bytes per sample
            
        else if version isnt 0
            @emit 'error', 'Unknown version in stsd atom'
            
        if BITS_PER_CHANNEL[format.formatID]?
            format.bitsPerChannel = BITS_PER_CHANNEL[format.formatID]
            
        format.floatingPoint = format.formatID in ['fl32', 'fl64']
        format.littleEndian = format.formatID is 'sowt' and format.bitsPerChannel > 8
        
        if format.formatID in ['twos', 'sowt', 'in24', 'in32', 'fl32', 'fl64', 'raw ', 'NONE']
            format.formatID = 'lpcm'
        
    atom 'moov.trak.mdia.minf.stbl.stsd.alac', ->
        @stream.advance(4)
        @track.cookie = @stream.readBuffer(@len - 4)
        
    atom 'moov.trak.mdia.minf.stbl.stsd.esds', ->
        offset = @stream.offset + @len
        @track.cookie = M4ADemuxer.readEsds @stream
        @stream.seek offset # skip garbage at the end 
        
    atom 'moov.trak.mdia.minf.stbl.stsd.wave.enda', ->
        @track.format.littleEndian = !!@stream.readUInt16()
        
    # reads a variable length integer
    @readDescrLen: (stream) ->
        len = 0
        count = 4

        while count--
            c = stream.readUInt8()
            len = (len << 7) | (c & 0x7f)
            break unless c & 0x80

        return len
        
    @readEsds: (stream) ->
        stream.advance(4) # version and flags
        
        tag = stream.readUInt8()
        len = M4ADemuxer.readDescrLen(stream)

        if tag is 0x03 # MP4ESDescrTag
            stream.advance(2) # id
            flags = stream.readUInt8()

            if flags & 0x80 # streamDependenceFlag
                stream.advance(2)

            if flags & 0x40 # URL_Flag
                stream.advance stream.readUInt8()

            if flags & 0x20 # OCRstreamFlag
                stream.advance(2)

        else
            stream.advance(2) # id

        tag = stream.readUInt8()
        len = M4ADemuxer.readDescrLen(stream)
            
        if tag is 0x04 # MP4DecConfigDescrTag
            codec_id = stream.readUInt8() # might want this... (isom.c:35)
            stream.advance(1) # stream type
            stream.advance(3) # buffer size
            stream.advance(4) # max bitrate
            stream.advance(4) # avg bitrate

            tag = stream.readUInt8()
            len = M4ADemuxer.readDescrLen(stream)
            
            if tag is 0x05 # MP4DecSpecificDescrTag
                return stream.readBuffer(len)
        
        return null
        
    # time to sample
    atom 'moov.trak.mdia.minf.stbl.stts', ->
        @stream.advance(4) # version and flags
        
        entries = @stream.readUInt32()
        @track.stts = []
        for i in [0...entries] by 1
            @track.stts[i] =
                count: @stream.readUInt32()
                duration: @stream.readUInt32()
                
        @setupSeekPoints()
    
    # sample to chunk
    atom 'moov.trak.mdia.minf.stbl.stsc', ->
        @stream.advance(4) # version and flags
        
        entries = @stream.readUInt32()
        @track.stsc = []
        for i in [0...entries] by 1
            @track.stsc[i] = 
                first: @stream.readUInt32()
                count: @stream.readUInt32()
                id: @stream.readUInt32()
                
        @setupSeekPoints()
        
    # sample size
    atom 'moov.trak.mdia.minf.stbl.stsz', ->
        @stream.advance(4) # version and flags
        
        @track.sampleSize = @stream.readUInt32()
        entries = @stream.readUInt32()
        
        if @track.sampleSize is 0 and entries > 0
            @track.sampleSizes = []
            for i in [0...entries] by 1
                @track.sampleSizes[i] = @stream.readUInt32()
                
        @setupSeekPoints()
    
    # chunk offsets
    atom 'moov.trak.mdia.minf.stbl.stco', -> # TODO: co64
        @stream.advance(4) # version and flags
        
        entries = @stream.readUInt32()
        @track.chunkOffsets = []
        for i in [0...entries] by 1
            @track.chunkOffsets[i] = @stream.readUInt32()
            
        @setupSeekPoints()
        
    # chapter track reference
    atom 'moov.trak.tref.chap', ->
        entries = @len >> 2
        @track.chapterTracks = []
        for i in [0...entries] by 1
            @track.chapterTracks[i] = @stream.readUInt32()
            
        return
        
    # once we have all the information we need, generate the seek table for this track
    setupSeekPoints: ->
        return unless @track.chunkOffsets? and @track.stsc? and @track.sampleSize? and @track.stts?
        
        stscIndex = 0
        sttsIndex = 0
        sttsIndex = 0
        sttsSample = 0
        sampleIndex = 0
        
        offset = 0
        timestamp = 0
        @track.seekPoints = []
        
        for position, i in @track.chunkOffsets
            for j in [0...@track.stsc[stscIndex].count] by 1
                # push the timestamp and both the physical position in the file
                # and the offset without gaps from the start of the data
                @track.seekPoints.push
                    offset: offset
                    position: position
                    timestamp: timestamp
                
                size = @track.sampleSize or @track.sampleSizes[sampleIndex++]
                offset += size
                position += size
                timestamp += @track.stts[sttsIndex].duration
                
                if sttsIndex + 1 < @track.stts.length and ++sttsSample is @track.stts[sttsIndex].count
                    sttsSample = 0
                    sttsIndex++
                    
            if stscIndex + 1 < @track.stsc.length and i + 1 is @track.stsc[stscIndex + 1].first
                stscIndex++
        
    after 'moov', ->        
        # if the mdat block was at the beginning rather than the end, jump back to it
        if @mdatOffset?
            @stream.seek @mdatOffset - 8
            
        # choose a track
        for track in @tracks when track.type is 'soun'
            @track = track
            break
            
        if @track.type isnt 'soun'
            @track = null
            return @emit 'error', 'No audio tracks in m4a file.'
            
        # emit info
        @emit 'format', @track.format
        @emit 'duration', @track.duration / @track.timeScale * 1000 | 0
        if @track.cookie
            @emit 'cookie', @track.cookie
        
        # use the seek points from the selected track
        @seekPoints = @track.seekPoints
        
    atom 'mdat', ->
        if not @startedData
            @mdatOffset ?= @stream.offset
            
            # if we haven't read the headers yet, the mdat atom was at the beginning
            # rather than the end. Skip over it for now to read the headers first, and
            # come back later.
            if @tracks.length is 0
                bytes = Math.min(@stream.remainingBytes(), @len)
                @stream.advance bytes
                @len -= bytes
                return
            
            @chunkIndex = 0
            @stscIndex = 0
            @sampleIndex = 0
            @tailOffset = 0
            @tailSamples = 0
            
            @startedData = true
            
        # read the chapter information if any
        unless @readChapters
            @readChapters = @parseChapters()
            return if @break = not @readChapters
            @stream.seek @mdatOffset
            
        # get the starting offset
        offset = @track.chunkOffsets[@chunkIndex] + @tailOffset
        length = 0
        
        # make sure we have enough data to get to the offset
        unless @stream.available(offset - @stream.offset)
            @break = true
            return
        
        # seek to the offset
        @stream.seek(offset)
        
        # calculate the maximum length we can read at once
        while @chunkIndex < @track.chunkOffsets.length
            # calculate the size in bytes of the chunk using the sample size table
            numSamples = @track.stsc[@stscIndex].count - @tailSamples
            chunkSize = 0
            for sample in [0...numSamples] by 1
                size = @track.sampleSize or @track.sampleSizes[@sampleIndex]
                
                # if we don't have enough data to add this sample, jump out
                break unless @stream.available(length + size)
                
                length += size
                chunkSize += size
                @sampleIndex++
            
            # if we didn't make it through the whole chunk, add what we did use to the tail
            if sample < numSamples
                @tailOffset += chunkSize
                @tailSamples += sample
                break
            else
                # otherwise, we can move to the next chunk
                @chunkIndex++
                @tailOffset = 0
                @tailSamples = 0
                
                # if we've made it to the end of a list of subsequent chunks with the same number of samples,
                # go to the next sample to chunk entry
                if @stscIndex + 1 < @track.stsc.length and @chunkIndex + 1 is @track.stsc[@stscIndex + 1].first
                    @stscIndex++
                
                # if the next chunk isn't right after this one, jump out
                if offset + length isnt @track.chunkOffsets[@chunkIndex]
                    break
        
        # emit some data if we have any, otherwise wait for more
        if length > 0
            @emit 'data', @stream.readBuffer(length)
            @break = @chunkIndex is @track.chunkOffsets.length
        else
            @break = true
            
    parseChapters: ->
        return true unless @track.chapterTracks?.length > 0

        # find the chapter track
        id = @track.chapterTracks[0]
        for track in @tracks
            break if track.id is id

        if track.id isnt id
            @emit 'error', 'Chapter track does not exist.'

        @chapters ?= []
        
        # use the seek table offsets to find chapter titles
        while @chapters.length < track.seekPoints.length
            point = track.seekPoints[@chapters.length]
            
            # make sure we have enough data
            return false unless @stream.available(point.position - @stream.offset + 32)

            # jump to the title offset
            @stream.seek point.position

            # read the length of the title string
            len = @stream.readUInt16()
            title = null
            
            return false unless @stream.available(len)
            
            # if there is a BOM marker, read a utf16 string
            if len > 2
                bom = @stream.peekUInt16()
                if bom in [0xfeff, 0xfffe]
                    title = @stream.readString(len, 'utf16-bom')

            # otherwise, use utf8
            title ?= @stream.readString(len, 'utf8')
            
            # add the chapter title, timestamp, and duration
            nextTimestamp = track.seekPoints[@chapters.length + 1]?.timestamp ? track.duration
            @chapters.push
                title: title
                timestamp: point.timestamp / track.timeScale * 1000 | 0
                duration: (nextTimestamp - point.timestamp) / track.timeScale * 1000 | 0
                
        # we're done, so emit the chapter data
        @emit 'chapters', @chapters
        return true
        
    # metadata chunk
    atom 'moov.udta.meta', ->
        @metadata = {}        
        @stream.advance(4) # version and flags
        
    # emit when we're done
    after 'moov.udta.meta', ->
        @emit 'metadata', @metadata

    # convienience function to generate metadata atom handler
    meta = (field, name, fn) ->
        atom "moov.udta.meta.ilst.#{field}.data", ->
            @stream.advance(8)
            @len -= 8
            fn.call this, name

    # string field reader
    string = (field) ->
        @metadata[field] = @stream.readString(@len, 'utf8')

    # from http://atomicparsley.sourceforge.net/mpeg-4files.html
    meta '©alb', 'album', string
    meta '©arg', 'arranger', string
    meta '©art', 'artist', string
    meta '©ART', 'artist', string
    meta 'aART', 'albumArtist', string
    meta 'catg', 'category', string
    meta '©com', 'composer', string
    meta '©cpy', 'copyright', string
    meta 'cprt', 'copyright', string
    meta '©cmt', 'comments', string
    meta '©day', 'releaseDate', string
    meta 'desc', 'description', string
    meta '©gen', 'genre', string # custom genres
    meta '©grp', 'grouping', string
    meta '©isr', 'ISRC', string
    meta 'keyw', 'keywords', string
    meta '©lab', 'recordLabel', string
    meta 'ldes', 'longDescription', string
    meta '©lyr', 'lyrics', string
    meta '©nam', 'title', string
    meta '©phg', 'recordingCopyright', string
    meta '©prd', 'producer', string
    meta '©prf', 'performers', string
    meta 'purd', 'purchaseDate', string
    meta 'purl', 'podcastURL', string
    meta '©swf', 'songwriter', string
    meta '©too', 'encoder', string
    meta '©wrt', 'composer', string

    meta 'covr', 'coverArt', (field) ->
        @metadata[field] = @stream.readBuffer(@len)

    # standard genres
    genres = [
        "Blues", "Classic Rock", "Country", "Dance", "Disco", "Funk", "Grunge", 
        "Hip-Hop", "Jazz", "Metal", "New Age", "Oldies", "Other", "Pop", "R&B",
        "Rap", "Reggae", "Rock", "Techno", "Industrial", "Alternative", "Ska", 
        "Death Metal", "Pranks", "Soundtrack", "Euro-Techno", "Ambient", 
        "Trip-Hop", "Vocal", "Jazz+Funk", "Fusion", "Trance", "Classical", 
        "Instrumental", "Acid", "House", "Game", "Sound Clip", "Gospel", "Noise",
        "AlternRock", "Bass", "Soul", "Punk", "Space", "Meditative", "Instrumental Pop", 
        "Instrumental Rock", "Ethnic", "Gothic",  "Darkwave", "Techno-Industrial", 
        "Electronic", "Pop-Folk", "Eurodance", "Dream", "Southern Rock", "Comedy", 
        "Cult", "Gangsta", "Top 40", "Christian Rap", "Pop/Funk", "Jungle", 
        "Native American", "Cabaret", "New Wave", "Psychadelic", "Rave", "Showtunes",
        "Trailer", "Lo-Fi", "Tribal", "Acid Punk", "Acid Jazz", "Polka", "Retro", 
        "Musical", "Rock & Roll", "Hard Rock", "Folk", "Folk/Rock", "National Folk", 
        "Swing", "Fast Fusion", "Bebob", "Latin", "Revival", "Celtic", "Bluegrass",
        "Avantgarde", "Gothic Rock", "Progressive Rock", "Psychedelic Rock", "Symphonic Rock",
        "Slow Rock", "Big Band", "Chorus", "Easy Listening", "Acoustic", "Humour", "Speech", 
        "Chanson", "Opera", "Chamber Music", "Sonata", "Symphony", "Booty Bass", "Primus", 
        "Porn Groove", "Satire", "Slow Jam", "Club", "Tango", "Samba", "Folklore", "Ballad", 
        "Power Ballad", "Rhythmic Soul", "Freestyle", "Duet", "Punk Rock", "Drum Solo", 
        "A Capella", "Euro-House", "Dance Hall"
    ]

    meta 'gnre', 'genre', (field) ->
        @metadata[field] = genres[@stream.readUInt16() - 1]

    meta 'tmpo', 'tempo', (field) ->
        @metadata[field] = @stream.readUInt16()

    meta 'rtng', 'rating', (field) ->
        rating = @stream.readUInt8()
        @metadata[field] = if rating is 2 then 'Clean' else if rating isnt 0 then 'Explicit' else 'None'

    diskTrack = (field) ->
        @stream.advance(2)
        @metadata[field] = @stream.readUInt16() + ' of ' + @stream.readUInt16()
        @stream.advance(@len - 6)

    meta 'disk', 'diskNumber', diskTrack
    meta 'trkn', 'trackNumber', diskTrack

    bool = (field) ->
        @metadata[field] = @stream.readUInt8() is 1

    meta 'cpil', 'compilation', bool
    meta 'pcst', 'podcast', bool
    meta 'pgap', 'gapless', bool
    
module.exports = M4ADemuxer
