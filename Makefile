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
		
browser_test:
	./node_modules/.bin/browserify tests/test.coffee --extension .coffee -o tests/test.js
		
clean:
	mv src/devices/resampler.js resampler.js.tmp
	rm -rf build/ node.js src/*.js src/**/*.js src/**/**/*.js tests/test.js
	mv resampler.js.tmp src/devices/resampler.js
