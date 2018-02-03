#!/bin/sh

let error = false

let res = [

  db.createCollection( "site" ),
  db.roles.createIndex( {app: 1, name: 1} ),
  db.experiment_switch.createIndex( {experiment_name: 1, instrument: 1,  station: 1, switch_time: 1} )

]

printjson(res)

if (error) {
  print('Error, exiting')
  quit(1)
}
