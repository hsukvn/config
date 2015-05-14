#!/usr/bin/env node

'use strict';

var fileutil = (function() {
	var fs = require('fs');
	return {
		load: function(fname) {
			try {
				return fs.readFileSync(fname, { encoding: 'utf8' });
			} catch(e) {
				if (e.code !== 'ENOENT') {
					throw e;
				} else {
					return "";
				}
			}
		},
		mtime: function(fname) {
			var st = fs.statSync(fname);
			return st.mtime;
		},
		isDirectory: function(path) {
			try {
				var st = fs.statSync(path);
			} catch (ignore) {
				return false;
			}
			return st.isDirectory();
		},
		listMdInDir: function(path) {
			var fnames = [];
			fs.readdirSync(path).forEach(function(fname) {
				var st = fs.statSync(path + "/" + fname);
				var strftime = require('strftime');
				var hasMdFile = false;

				if (!/\.md$/.test(fname) && !st.isDirectory()) {
					return ;
				}
				if (fname == "INDEX.md") {
					return ;
				}

				if (st.isDirectory()) {
					fs.readdirSync(path + "/" + fname).forEach(function(f) {
						if (/\.md$/.test(f)) {
							hasMdFile = true;
							return false;
						}
					});
					if (!hasMdFile) {
						return ;
					}
				}

				fnames.push({
					name: fname,
					type: st.isDirectory() ? 'folder' : 'file',
					mtime: st.mtime,
					mtime_str: strftime("%F %T", st.mtime)
				});
			});

			fnames.sort(function(a, b) {
				return b.mtime.getTime() - a.mtime.getTime();
			});
			return fnames;
		}
	};
}());
var swig = (function(template_path) {
	var swig = require('swig');

	swig.setDefaults({
		loader: swig.loaders.fs(template_path)
	});

	return swig;
}(__dirname + "/../template"));
var marked = (function() {
	var marked = require('marked');
	var toc = require('marked-toc');
	var renderer = new marked.Renderer();
	var proj_id_map = {
		'DSM': 27,
		'DSM Build System': 81,
		'DSM Critical Update': 231,
		'Glacier Backup': 171,
		'Glacier': 171,
		'HiDrive Backup': 102,
		'HiDrive': 102,
		'Time Backup': 67,
		'x': undefined
	};

	renderer.heading = function(text, level) {
		return swig.render(
			'<h{{level}} id="{{escapedText}}">' +
				'<a name="{{escapedText}}" class="heading-anchor" href="#{{escapedText}}">' +
					'{{text|safe}}' +
				'</a>' +
			'</h{{level}}>\n',
			{locals: {
				level: level,
				text: text,
				escapedText: text.toLowerCase().replace('.', '').replace(/[^\w]+/g, '-')
			}}
		);
	};
	renderer.table = function(header, body) {
		return '<table class="table">\n' +
				'<thead>\n' + header + '</thead>\n' +
				'<tbody>\n' + body + '</tbody>\n' +
			'</table>\n';
	};
	renderer.listitem = function(text) {
		return '<li>' + text.replace(/^(<p>)?\[[ _]\]/, '<input type="checkbox" disabled>')
		.replace(/^(<p>)?\[[xvo]\]/i, '<input type="checkbox" checked disabled>') + '</li>\n';
	};
	renderer.paragraph = function(text) {
		if (text.match(/.+[\r\n]+:.+([\r\n]+:.+)*/m)) {
			var toks = text.split('\n');
			var key = toks.shift();
			var value = '';
			toks.forEach(function(tok) {
				value += tok.replace(/^:\s*/, '');
			});
			return '<dl><dt>' + key + '</dt><dd>' + value + '</dd></dl>\n';
		} else if (text.match(/^TBD:\s*(.*)/)) {
			return '<div class="alert alert-warning"><p><span class="glyphicon glyphicon-user"></span> ' + text + '</p></div>';
		} else if (text.match(/^TBM:\s*(.*)/)) {
			return '<div class="alert alert-info"><p><span class="glyphicon glyphicon-pencil"></span> ' + text + '</p></div>';
		} else if (text.match(/^BUG:\s*(.*)/)) {
			return '<div class="alert alert-danger"><p><span class="glyphicon glyphicon-remove-sign"></span> ' + text + '</p></div>';
		} else {
			return '<p>' + text + '</p>\n';
		}
	};

	marked.setOptions({
		renderer: renderer,
		gfm: true,
		tables: true,
		breaks: false,
		pedantic: false,
		sanitize: false,
		smartLists: true,
		smartypants: false
	});

	marked.toc = function(text) {
		var renderer2 = new marked.Renderer();

		renderer2.list = function(body, ordered) {
			var type = ordered ? 'ol' : 'ul';
			return '<' + type + ' class="nav">\n' + body + '</' + type + '>\n';
		};

		var html = marked(toc(text, {firsth1: true}), {renderer: renderer2});

		return html.replace(/<ul class="nav">/, '<ul class="nav bs-docs-sidenav">');
	};

	marked.doc = function(text) {
		var html = marked(text);

		return html.replace(/\[([^\]]+)\]\#([0-9]+)/g, function(text, project, report_id) {
			var proj_id = proj_id_map[project];
			return '<a href="https://bug.synology.com/report/report_show.php?project_id=' + proj_id +
				'&report_id=' + report_id + '">' + text + '</a>';
		});
	};

	marked.reveal = function(text) {
		renderer.heading = marked.Renderer.prototype.heading;
		var html = marked(text);

		return '<section>'
			+ html.split('<!-- section -->').join('</section><section>')
			+ '</section>';
	};

	return marked;
}());

var doc = (function() {
	var util = require('util');
	var ncgi = require('ncgi');
	var params = ncgi.getParameters();
	var fname;

	if (process.argv.length > 2) {
		params.filename = process.argv[1];
	}

	if (process.argv.length > 3) {
		params.format = params.format;
	} else if (params.f) {
		params.format = params.f;
	}
	params.format = params.format || 'html';

	// FIXME i don't known why
	if (util.isArray(params.filename)) {
		params.filename = params.filename[0];
	}

	return {
		isCgi: !(process.argv.length > 2),
		fname: params.filename,
		format: params.format,
		print: params.filename ? ncgi.print : util.print
	};
}());

if (!doc.fname) {
	console.log("Status: 404 Not Found");
	process.exit(1);
}
// FIXME how to check path?
if (doc.fname.match(/\.\./)) {
	console.log("Status: 403");
	process.exit(1);
}

var strftime = require('strftime');
var tpl, text;

if (fileutil.isDirectory(doc.fname)) {
	tpl = swig.compileFile('index.tpl.html');
	text = fileutil.load(doc.fname + "/INDEX.md");
	doc.print(tpl({
		title: 'index',
		mtime: text ? strftime("%F %T", fileutil.mtime(doc.fname + '/INDEX.md')) : 0,
		index: text,
		files: fileutil.listMdInDir(doc.fname)
	}));
	process.exit(0);
}

text = fileutil.load(doc.fname);

if (!text) {
	console.log("Status: 404 Not Found");
	process.exit(1);
}

if ('html' === doc.format) {
	tpl = swig.compileFile("markdown.tpl.html");
	doc.print(tpl({
		title: doc.fname.replace(/^.*?([^\/]+)\.md$/, '$1'),
		html: marked.doc(text),
		toc: marked.toc(text),
		mtime: strftime("%F %T", fileutil.mtime(doc.fname))
	}));
} else if ('raw' === doc.format) {
	doc.print(text);
} else if ('reveal' === doc.format) {
	tpl = swig.compileFile('reveal.tpl.html');
	doc.print(tpl({
		title: doc.fname.replace(/\.md$/, ''),
		html: marked.reveal(text),
		mtime: strftime("%F %T", fileutil.mtime(doc.fname))
	}));
}
