.PHONY: js browser browser_slim test browser_test clean

js: src/**/*.coffee
	./node_modules/.bin/coffee -c node.coffee src/*.coffee src/**/*.coffee src/**/**/*.coffee

browser: src/**/*.coffee
	mkdir -p build/
	./node_modules/.bin/browserify \
		--standalone AV \
		--extension .coffee \
		--debug \
		. \
		| ./node_modules/.bin/exorcist build/aurora.js.map > build/aurora.js
		
browser_slim: src/**/*.coffee
	mkdir -p build/
	./node_modules/.bin/browserify \
		--standalone AV \
		--extension .coffee \
		--debug \
		browser_slim.coffee \
		| ./node_modules/.bin/exorcist build/aurora_slim.js.map > build/aurora_slim.js

test_node:
	@./node_modules/.bin/mocha \
		--compilers coffee:coffee-script/register \
		--recursive \
		tests
		
test_browser:
	@./node_modules/.bin/mochify \
		--extension .coffee \
		--reporter spec \
		--timeout 10000 \
		tests/**/*.coffee
		
test: test_node test_browser
		
clean:
	mv src/devices/resampler.js resampler.js.tmp
	rm -rf build/ node.js src/*.js src/**/*.js src/**/**/*.js tests/test.js
	mv resampler.js.tmp src/devices/resampler.js
