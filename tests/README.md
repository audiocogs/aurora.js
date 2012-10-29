Tests
=====

## To run in the browser:
1. Start servers to host Aurora and the tests:

        importer ../browser.coffee -p 3030
        importer test.coffee -p 3031
        
    You may need to install `importer` using `npm install importer -g` first.
2. Open `test.html` in your browser.
    
## To run in Node:
1. Either run `importer test.coffee`
2. Or `npm test` from the root directory.