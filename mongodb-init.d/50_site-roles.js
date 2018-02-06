#!/bin/sh

let error = false

let res = [

  db.roles.createIndex( {app: 1, name: 1} ),
  db.roles.insertMany([
    {
    	app: "LogBook",
    	name: "Editor",
    	privileges: [
    		"read",
    		"post",
    		"manage_shifts",
    		"edit",
    		"delete"
    	],
    	players: [
    		"uid:mshankar",
    		"uid:wilko",
        "uid:ytl"
    	]
    },
    {
    	app: "LogBook",
    	name: "Writer",
    	privileges: [
    		"manage_shifts",
    		"post",
    		"read"
    	],
    	players: [
    		"ps-pcds",
        "uid:mshankar",
    		"uid:wilko",
        "uid:ytl"
    	]
    },
    {
    	app: "LogBook",
    	name: "Reader",
    	privileges: [
    		"read"
    	],
    	players: [
    		"ps-sci",
        "ps-data",
    		"ps-mgt",
        "uid:mshankar",
    		"uid:wilko",
        "uid:ytl"    
    	]
    }
  ])

]

printjson(res)

if (error) {
  print('Error, exiting')
  quit(1)
}



