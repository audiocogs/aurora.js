module.exports = (grunt) ->
    
    grunt.loadNpmTasks('grunt-contrib-clean')
    grunt.loadNpmTasks('grunt-contrib-connect')
    grunt.loadNpmTasks('grunt-contrib-copy')
    grunt.loadNpmTasks('grunt-contrib-watch')
    grunt.loadNpmTasks('grunt-importer')
    grunt.loadNpmTasks('grunt-open')

    grunt.initConfig
        pkg: grunt.file.readJSON('package.json')

        connect:
            test:
                options:
                    base: ['.tmp', 'tests']
                    port: 8080

        open:
            test:
                path: 'http://localhost:<%= connect.test.options.port %>/test.html'

        watch:
            config:
                files: ['Gruntfile.coffee']
                options:
                    reload: true
            browser:
                files: ['src/**/*.coffee']
                tasks: ['importer:browser']
            browser_slim:
                files: ['src/**/*.coffee']
                tasks: ['importer:browser_slim']
            node:
                files: ['src/**/*.coffee']
                tasks: ['importer:node']
            test:
                files: ['src/**/*.coffee', 'tests/**/*.coffee']
                tasks: ['importer:test', 'importer:browser']
                options:
                    livereload: true

        importer:
            browser:
                src: 'browser.coffee',
                dest: '.tmp/browser.js'
            browser_slim:
                src: 'browser_slim.coffee'
                dest: '.tmp/browser_slim.js'
            node:
                src: 'node.coffee'
                dest: '.tmp/node.js'
            test:
                src: 'tests/test.coffee'
                dest: '.tmp/tests.js'

        clean:
            tmp: '.tmp'
            dist: 'dist'

        copy:
            dist:
                cwd: '.tmp/'
                src: '*'
                dest: 'dist/'
                expand: true


    grunt.registerTask 'build', [
        'clean',
        'importer',
        'copy:dist',
        'clean:tmp'
    ]

    grunt.registerTask 'test', [
        'clean:tmp'
        'importer:browser'
        'importer:test'
        'connect:test',
        'open:test'
        'watch:test'
    ]

    grunt.registerTask('default', ['build'])
