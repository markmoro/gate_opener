from bottle import route, run, get, post, request, template
import uuid
import hashlib
import hmac
import os

key = os.environ['HASH_KEY']
token = None

@route('/token')
def index():
	u = uuid.uuid4()
	global token
	token = u.bytes.encode("base64")[:20]
	return token


@post('/open') 
def do_open():
	digest = request.forms.get('d')
	check = check = hmac.new(key,token+'open',hashlib.sha1).hexdigest()
	if check == digest:
		print 'Correct Digest'
		return 'Correct'
	else:
		print 'Wrong Digest'
		return 'Wrong'



run(host='localhost', port=8080)

	