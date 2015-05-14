#!/usr/bin/python
# encoding: utf-8
import os

if "__main__" == __name__:
	import httplib
	import urllib
	import json

	conn = httplib.HTTPConnection('192.168.16.57', 5000)
	conn.set_debuglevel(10)

	conn.request('GET', '/webman/login.cgi?' + urllib.urlencode({
		'username': 'admin',
		'passwd': 'q',
		'enable_syno_token': 'yes'
	}), None, {
		'Content-Type': 'application/x-www-form-urlencoded',
		'Connection': 'keep-alive',
	})
	res = conn.getresponse()
	if res.status != httplib.OK:
		conn.close()
		raise SystemError();

	content = res.read()
	cookie = res.getheader("set-cookie").split(";")[0] + ';'

	content_json = json.loads(content)
	synotoken = content_json['SynoToken']
	print "synotoken:", synotoken

	print "---- content ----"
	print content



	conn.request('POST', '/webman/modules/ControlPanel/modules/terminal.cgi', urllib.urlencode({
		#'action': 'load'
		'action': 'apply',
		'telnet_enable': 'on',
		'ssh_enable': 'on',
	}), {
		'Content-Type': 'application/x-www-form-urlencoded',
		'Cookie': cookie,
		'X-SYNO-TOKEN': synotoken,
	})
	res = conn.getresponse()
	if res.status != httplib.OK:
		conn.close()
		raise SystemError();

	content = res.read()
	print "---- content ----"
	print content



	conn.request('GET', '/webman/logout.cgi', None, {
		'Content-Type': 'application/x-www-form-urlencoded',
		'Cookie': cookie,
		'X-SYNO-TOKEN': synotoken,
	})
	res = conn.getresponse()
	if res.status != httplib.FOUND:
		conn.close()
		raise SystemError();

	content = res.read()
	print "---- content ----"
	print content
