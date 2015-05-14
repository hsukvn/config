# node-cgi

Node module to call node scripts as a CGI script

# USAGE

\#!/usr/bin/node
var ncgi = require('ncgi');
var params = ncgi.getParameters();
ncgi.print("Hello world<br/>\n");
ncgi.print("parameters="+require('util').inspect(params)+"<br/>\n");


# FEATURES

* A node script can be called from Apache by giving it the .cgi extension and making it executable
* Supports GET as well as POST (application/x-www-form-urlencoded content-type only) parameters
* Can set a custom mimetype with ncgi.getParameters() (default text/html)
* Can include a script relative to the current script with eval(ncgi.read('path/to/relativ/script.js'))

# LICENSE

node-cgi is released under GPL license


