#import "src/aurora.coffee"
#import "src/sources/node/http.coffee"
#import "src/sources/node/file.coffee"

AV.isNode = true
AV.require = (modules...) ->
    Module = require 'module'
    
    # create a temporary reference to the AV namespace 
    # that we can access from within the required modules
    key = "__AV__#{Date.now()}"
    Module::[key] = AV
    
    # temporarily override the module wrapper
    wrapper = Module.wrapper[0]
    Module.wrapper[0] += "var AV = module['#{key}'];"
    
    # require the modules
    for module in modules
        require module
        
    # replace the wrapper and delete the temporary AV reference
    Module.wrapper[0] = wrapper
    delete Module::[key]
    
    return

module.exports = AV