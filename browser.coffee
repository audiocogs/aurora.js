do ->
    global = this
    
    #import "src/aurora.coffee"
    #import "src/sources/browser/http.coffee"
    #import "src/sources/browser/file.coffee"
    #import "src/sources/browser/websocket.coffee"
    
    global.AV = AV