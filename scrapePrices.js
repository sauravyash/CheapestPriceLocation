const fetch = require("node-fetch")
const readline = require('readline')
const util = require('util');
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

let completeScrapeData = []

const init_lat = -15
const lat_interval = 1
const max_lat = -45

const init_long = 112
const long_interval = 3
const max_long = 155

const fetchAllData = async () => {
  for (let lat = init_lat; lat > max_lat; lat -= lat_interval) {
    for (let long = init_long; long < max_long; long += long_interval) {
      // console.log(`lat: ${lat}, long: ${long}`)
      await fetch(`https://petrolspy.com.au/webservice-1/station/box?neLat=${lat}&neLng=${long+long_interval}&swLat=${lat-lat_interval}&swLng=${long}`)
        .then(res => res.json())
        .then(res => {
          let data = res.message.list
          if (!data) return console.error("Error: Fetch Failed")
          if (!data[0]) return //console.error("Error: not Iterable from fetch")
          // console.log("INFO: fetch success")

          for(let obj of data) {
            completeScrapeData.push(obj)
          }
        })
    }
  }
  return completeScrapeData
}

const findCheapest = (data, fuel) => {
  data = data.filter(station => station.prices[fuel])
  let pricesOnlyData = data.map(station => station.prices[fuel].amount)
  let lowestPrice = Math.min(...pricesOnlyData)
  let cheapestStation = data.filter(station => station.prices[fuel].amount === lowestPrice)[0]
  // console.log("List:")
  // console.log(cheapestStations)
  return cheapestStation
}

const formatData = data => {
  return data

}

const fuelQuestion = async () => {
  let fuel = ""
  let pos = 0
  await rl.question('What type of fuel? ("U91", "DIESEL", "U95", "U98")\n', (ans) => {
    console.log(`Searching for the cheapest ${ans} fuel...`);
    rl.close();
    fuel = ans
    return
  })
  return {
    fuel,
    pos: 0
  }
}

Promise.all([fuelQuestion(), fetchAllData()])
  .then(res => {
    console.log(res[0]);
    // console.log(res);
    completeScrapeData = completeScrapeData.filter(station => station.brand == "SEVENELEVEN")
    if (completeScrapeData === null){
      throw "Invalid Fuel Type OR UNKNOWN FETCH ERROR"
    }

    console.log(`${res[0].pos + 1} Cheapest ${res[0].fuel} Station: ` + util.inspect(findCheapest(completeScrapeData, "DIESEL")))
  })
  .catch(res=>{
    console.log(res)
  })
