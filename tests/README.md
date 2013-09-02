Tests
=====

The tests for Aurora are written using the [QUnit](http://qunitjs.com/) testing framework.
They run in both Node.js and the browser.

##Setup
1. don't forget to install all the dev dependencies by running `npm install` from the root folder. If not already done, you might want to install `importer` globally with `npm install importer -g`.

2. you'll need the test data, so init your git submodules to download them, and update them
    if you've already downloaded them before.

        git submodule init
        git submodule update

3. whether you run the tests with Node.js or in the browser, you will need running an HTTP server to host QUnit as well as the test data files.

    To start a simple static HTTP server in the tests directory, run the following command:

        python -m SimpleHTTPServer
    
    If you already have the test directory on an HTTP server, all you need to do is set the base URL of 
    the "tests" folder to the `HTTP_BASE` variable in `config.coffee`.

## To run in the browser:
1. Follow the setup steps above.

2. Start servers to host Aurora and the tests themselves:

        importer ../browser.coffee -p 3030
        importer test.coffee -p 3031
    
3. Open `test.html` in your browser, using the HTTP server that you set up above.
    
## To run in Node:
1. Follow the setup steps above.
2. Build the library's entry point by running `importer node.coffee node.js` from the root folder
3. Either run `importer test.coffee` or `npm test` from the root directory.