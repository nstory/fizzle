module.exports = (grunt) ->
  grunt.initConfig
    clean:
      build: ['build/', 'lib/']

    coffee:
      build:
        files: [
          expand: true
          ext: '.js'
          extDot: 'last'
          src: ['src/*.coffee', 'spec/*.coffee']
          dest: 'build/'
        ]

    jasmine:
      test:
        src: 'build/src/*.js'
        options: {
          specs: 'build/spec/*.spec.js'
        }

    watch:
      options:
        atBegin: true
      test:
        files: ['Gruntfile.coffee', 'src/*.coffee', 'spec/*.coffee']
        tasks: ['test']

  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-jasmine'
  grunt.loadNpmTasks 'grunt-contrib-watch'

  grunt.registerTask 'build', ['clean', 'coffee']
  grunt.registerTask 'test', ['build', 'jasmine']
