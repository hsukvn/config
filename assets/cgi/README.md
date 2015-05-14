markdown.cgi - Markdown document generator
==========================================

* read markdown file and output html.
* list md file and folders

put the ``.htaccess`` file with the following config.

```
<IfModule mod_rewrite.c>
	RewriteEngine On
	#RewriteOptions AllowNoSlash
	RewriteRule \.md$ ../assets/cgi/markdown.cgi?filename=%{REQUEST_FILENAME} [QSA,L]
	RewriteCond %{REQUEST_FILENAME} -d
	RewriteRule (\/$|^$) ../assets/cgi/markdown.cgi?filename=%{REQUEST_FILENAME} [QSA]
</IfModule>
```

used modules
------------

### backend

* [swig](http://paularmstrong.github.io/swig/)
* [ncgi](https://github.com/regadou/node-cgi)
* [marked](https://github.com/chjj/marked)
* [marked-toc]()
* [strftime]()

### frontend

* jquery
* reveal.js
* hilight.js

customized renderer
-------------------

reference: https://github.com/chjj/marked#overriding-renderer-methods

current marked options

```
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
```

* [x] add bootstrap class `table` to table element
* [x] GFM task list for ``* [ ] ...`` and ``* [x] ...``
* [x] heading embedded anchor link
* [x] bug tracker auto link, ex. [DSM]#1234
* [x] add toc side bar with scroll-spy
* [x] definition list
* [x] integrate reveal.js

todo
----

* [ ] convert to dokuwiki syntax
* [ ] remove marked-toc (it is too heavy, a simple renderer hook could do what
    i want?

