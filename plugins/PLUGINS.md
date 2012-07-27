Plugins
=======

Aurora supports plugins, and you need some good ones for it to be useful. You place these plugins in this folder.

An Aurora plugin is just a folder with a aurora.plugin file, which is a json file containing something like this,

    {
      "source": "balance.erb.js",
      "output": "balance.js"
    }

The source is the erb.js file that builds the plugin, the output is the filename that it outputs.
