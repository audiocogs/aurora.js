Tests
=====

The tests for Aurora are written using the [Mocha](http://mochajs.org/) testing framework.  They 
run in both Node.js and the browser.

## Setup

First, you'll need the test data, so init your git submodules to download them, and update them
if you've already downloaded them before.

    git submodule init
    git submodule update

## Running

1. Follow the setup steps above.
2. Run `make test` to test in both Node and PhantomJS.
3. Alternatively, you can run just `make test-browser` or `make test-node` 
   to run only in that environment.
