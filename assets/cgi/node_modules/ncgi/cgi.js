var util = require('util');
var fs = require('fs');
var path = require('path');
var qs = require('querystring');
var mimetype = null;

var read = function (uri, encoding) {
   var colon = uri.indexOf(':');
   var proto = (colon < 2) ? null : uri.substring(0, colon);
   if (proto) {
      //TODO: implement fetching file with http, ftp, ssh, ...
      throw new Error("network file fetching is not implemented yet");
   }
   else if (uri.charAt(0) == '/') {
       var root = process.env.DOCUMENT_ROOT
       if (root != null)
          uri = path.join(root, uri);
   }
   else
       uri = path.join(process.cwd(), uri);

   if (!encoding)
      encoding = "utf8";
   return fs.readFileSync(uri, encoding);
};

var print = function (txt) {
   if (mimetype == null)
      setMimetype("text/html");
   return util.print(txt);
};


var getMimetype = function() {
   return mimetype;
};

var setMimetype = function(type) {
   if (mimetype == null || mimetype == "") {
      mimetype = type;
      util.print("Content-type: "+mimetype+"\n\n");
   }
   return mimetype;
};

var getParameters = function () {
   var query = process.env.QUERY_STRING;
   var getobj = (query == null || query.trim() == "") ? null : qs.parse(query);
   var method = process.env.REQUEST_METHOD;
   if (method != null && method.toLowerCase() == "post") {
      // TODO: implement multipart data
      if (process.env.CONTENT_TYPE != 'application/x-www-form-urlencoded')
         throw new Error("Posting of content-type "+process.env.CONTENT_TYPE+" not supported");
      var length = parseInt(process.env.CONTENT_LENGTH);
      var buffer = new Buffer(length);
      fs.readSync(process.stdin.fd, buffer, 0, length);
      var postobj = qs.parse(buffer.toString());
   }
   else
      var postobj = null;
      
   if (getobj == null) {
      if (postobj == null)
         return {};
      else
         return postobj;
   }
   else if (postobj == null)
      return getobj;
   else {
      for (var i in postobj)
         getobj[i] = postobj[i];
      return getobj;
   }  
};

exports.getMimetype = getMimetype;
exports.setMimetype = setMimetype;
exports.print = print;
exports.read = read;
exports.getParameters = getParameters;



