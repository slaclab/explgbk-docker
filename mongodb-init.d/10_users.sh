#!/bin/sh

MONGO=mongo
rootAuthDatabase='admin'

# _js_escape 'some "string" value'
_js_escape() {
	jq --null-input --arg 'str' "$1" '$str'
}
#
# db.createUser({
#   user: "admin", pwd: "somepassword",
#   roles: [
#     { role: "root", db: $(_js_escape "$rootAuthDatabase") },
#     { role: 'userAdminAnyDatabase', db: $(_js_escape "$rootAuthDatabase") },
#   ]
# })

"${MONGO}" "$rootAuthDatabase" <<-EOJS
  use $(_js_escape "$rootAuthDatabase")
  db.createUser({
    user: "reader", pwd: "somepassword",
    roles: [ { role: "readAnyDatabase", db: $(_js_escape "$rootAuthDatabase") } ]
  })
  db.createUser({
    user: "writer", pwd: "somepassword",
    roles: [ { role: "readWriteAnyDatabase", db: $(_js_escape "$rootAuthDatabase") } ]
  })

EOJS

