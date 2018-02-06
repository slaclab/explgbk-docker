let error = false

let res = [

  db.createCollection( "instruments" ),
  db.instruments.insertMany([
    {
        "_id" : "TEM1 / Krios1 G2",
        "description" : "Titan Krios with K2",
        "params" : {
            "isStandard" : "1",
            "num_stations" : "1",
            "camera": [
              'GIF_K2',
              'Falcon3',
              'HAADF'
            ],
            "phase_plate": "1"
        }
    },
    {
        "_id" : "TEM2 / Krios2 G3",
        "description" : "Titan Krios with K2",
        "params" : {
            "isStandard" : "1",
            "num_stations" : "1",
            "camera": [
              'GIF_K2',
              'Falcon3'
            ],
            "phase_plate": "1"
        }
    },
    {
        "_id" : "TEM3 / Arctica1",
        "description" : "Talos Arctica",
        "params" : {
            "isStandard" : "1",
            "num_stations" : "1",
            "camera": [
              'GIF_K2',
              'Falcon3'
            ],
            "phase_plate": "1"
        }
    },
    {
        "_id" : "TEM4 / Krios3",
        "description" : "Titan Krios with K2",
        "params" : {
            "isStandard" : "1",
            "num_stations" : "1",
            "camera": [
              'GIF_K2',
              'Falcon3'
            ],
            "phase_plate": "1"
        }
    }
    
  ])
  
]

printjson(res)

if (error) {
  print('Error, exiting')
  quit(1)
}