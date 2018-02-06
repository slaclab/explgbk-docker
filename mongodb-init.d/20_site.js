#!/bin/sh

let error = false

let res = [

  db.createCollection( "site" )

]

printjson(res)

if (error) {
  print('Error, exiting')
  quit(1)
}
