#!/usr/bin/env python

from email.MIMEText import MIMEText
from email.parser import Parser
import smtplib, sys

def get_exe_output(prog, *args, **kwargs):
	from subprocess import Popen, PIPE

	cmd = [prog]
	cmd.extend(args)

	pipe = Popen(cmd, stdout = PIPE, stderr = PIPE, close_fds = True, **kwargs)

	(out, err) = pipe.communicate(input = None)
	ret = pipe.wait()

	return (ret, out, err)

def send_mail(from_addrs, to_addrs, subject, content, server = "mail.synology.com"):
	server = smtplib.SMTP(server)
	#server.set_debuglevel(1)
	server.sendmail(from_addrs, to_addrs, content)
	server.quit()

text = sys.stdin.read()
header = Parser().parsestr(text)

header["From"] = "syno@git.thu"

send_mail(
	header.get("From"),
	header.get("To").split(","),
	header.get("Subject"),
	header.as_string()
)
