// Fuel Price supersearch
const fetch = require("node-fetch")

scrapeData = []

let init_lat = -15
let lat_interval = 1
let max_lat = -45

let init_long = 112
let long_interval = 3
let max_long = 155

async function fetchAllData() {
  for (let lat = init_lat; lat > max_lat; lat -= lat_interval) {
    for (let long = init_long; long < max_long; long += long_interval) {
      console.log(`lat: ${lat}, long: ${long}`)
      await fetch(`https://petrolspy.com.au/webservice-1/station/box?neLat=${lat}&neLng=${long+long_interval}&swLat=${lat-lat_interval}&swLng=${long}`)
        .then(res => res.json())
        .then(res => {
          let data = res.message.list
          if (!data) return console.error("Error: Fetch Failed")
          if (!data[0]) return console.error("Error: not Iterable from fetch")
          console.log("INFO: fetch success")
          for(let obj of data){
            scrapeData.push(obj)
          }
        })
    }
  }
  return scrapeData
}

Promise.all([fetchAllData()])
  .then((res)=>{
    console.log("DONEEEEEEE \n\n\n\n\n")
    console.log(res)
  })
