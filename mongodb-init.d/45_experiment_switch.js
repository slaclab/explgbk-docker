let error = false

let res = [

  db.createCollection( "experiment_switch" ),
  db.experiment_switch.createIndex( {experiment_name: 1, instrument: 1,  station: 1, switch_time: 1} ) //,
  // db.experiment_switch.insertMany([
  //   {
  //       "experiment_name" : "tem1",
  //       "instrument" : "TEM1 / Krios1 G2",
  //       "station" : 0,
  //       "switch_time" : ISODate("2017-12-08T00:00:00Z"),
  //       "requestor_uid" : "ytl"
  //   },
  //   {
  //       "experiment_name" : "tem2",
  //       "instrument" : "TEM2 / Krios2 G3",
  //       "station" : 0,
  //       "switch_time" : ISODate("2017-12-08T01:00:00Z"),
  //       "requestor_uid" : "ytl"
  //   },
  //   {
  //       "experiment_name" : "tem3",
  //       "instrument" : "TEM3 / Arctica1",
  //       "station" : 0,
  //       "switch_time" : ISODate("2017-12-08T02:00:00Z"),
  //       "requestor_uid" : "ytl"
  //   },
  //   {
  //       "experiment_name" : "tem4",
  //       "instrument" : "TEM4 / Krios3 G2",
  //       "station" : 0,
  //       "switch_time" : ISODate("2017-12-08T03:00:00Z"),
  //       "requestor_uid" : "ytl"
  //   }
  //])
  
]

printjson(res)

if (error) {
  print('Error, exiting')
  quit(1)
}