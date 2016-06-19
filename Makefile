.PHONY: js browser browser_slim test clean

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

server.pid:
	@./node_modules/.bin/static \
		-p 8000 \
		-H '{"access-control-expose-headers": "content-length", "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "Origin, X-Requested-With, Content-Type, Accept, Range, Content-Length, If-None-Match"}' \
		tests \
		> /dev/null \
		& echo $$! > $@
		
stop_server:
	@kill `cat server.pid` && rm -f server.pid

test_node: clean server.pid
	@./node_modules/.bin/mocha \
		--compilers coffee:coffee-script/register \
		--recursive \
		tests
		
test_browser: clean server.pid
	@./node_modules/.bin/mochify \
		--extension .coffee \
		--reporter spec \
		--timeout 10000 \
		tests/**/*.coffee
		
test: test_node test_browser stop_server
test-node: test_node stop_server
test-browser: test_browser stop_server
		
clean:
	@mv src/devices/resampler.js resampler.js.tmp
	@rm -rf build/ node.js src/*.js src/**/*.js src/**/**/*.js tests/test.js
	@mv resampler.js.tmp src/devices/resampler.js
