let error = false

let res = [

  db.createCollection( "instruments" ),
  db.instruments.insertMany([
    {
        "_id" : "TEM1",
        "description" : "Titan Krios G2",
        "params" : {
            "isStandard" : "1",
            "num_stations" : "1",
            "camera": [
              'GIF_K2',
              'Falcon3',
              'HAADF'
            ],
            "phase_plate": "1",
            "energy_filter": "1",
            "keV": 300,
            "cs": 2.7
        }
    },
    {
        "_id" : "TEM2",
        "description" : "Titan Krios G3",
        "params" : {
            "isStandard" : "1",
            "num_stations" : "1",
            "camera": [
              'GIF_K2',
              'Falcon3'
            ],
            "phase_plate": "1",
            "energy_filter": "1",
            "keV": 300,
            "cs": 2.7
        }
    },
    {
        "_id" : "TEM3",
        "description" : "Talos Arctica",
        "params" : {
            "isStandard" : "1",
            "num_stations" : "1",
            "camera": [
              'GIF_K2',
              'Falcon3'
            ],
            "phase_plate": "1",
            "energy_filter": "1",
            "keV": 200,
            "cs": 2.7
        }
    },
    {
        "_id" : "TEM4",
        "description" : "Titan Krios G2",
        "params" : {
            "isStandard" : "1",
            "num_stations" : "1",
            "camera": [
              'GIF_K2',
              'Falcon3'
            ],
            "phase_plate": "1",
            "energy_filter": "0",
            "keV": 300,
            "cs": 2.7
        }
    },
    {
        "_id" : "Unassigned",
        "description" : "Unallocated Experiments",
        "params" : {
        }
    }
    
  ])
  
]

printjson(res)

if (error) {
  print('Error, exiting')
  quit(1)
}
