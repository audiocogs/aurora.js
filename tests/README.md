Tests
=====

The tests for Aurora are written using the [QUnit](http://qunitjs.com/) testing framework.  They 
run in both Node.js and the browser.

##Setup

First, you'll need the test data, so init your git submodules to download them, and update them
if you've already downloaded them before.

    git submodule init
    git submodule update

## To run in the browser:

        grunt test
        
    You may need to install the dependencies using `npm install` first.
    
## To run in Node:
1. Follow the setup steps above.
2. Either run `importer test.coffee` or `npm test` from the root directory.