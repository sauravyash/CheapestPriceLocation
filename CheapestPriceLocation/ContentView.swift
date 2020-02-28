//
//  ContentView.swift
//  CheapestPriceLocation
//
//  Created by Yash on 27/1/20.
//  Copyright © 2020 sauravyash. All rights reserved.
//

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
  
  var locationManager = CLLocationManager()
  func setupManager() {
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    locationManager.requestWhenInUseAuthorization()
    locationManager.requestAlwaysAuthorization()
  }

  func makeUIView(context: Context) -> MKMapView {
    setupManager()
    let mapView = MKMapView(frame: UIScreen.main.bounds)
    mapView.showsUserLocation = true
    mapView.userTrackingMode = .follow
    return mapView
  }
  
  func updateUIView(_ uiView: MKMapView, context: Context) {
	
  }
}

extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var addedDict = [Element: Bool]()

        return filter {
            addedDict.updateValue(true, forKey: $0) == nil
        }
    }

    mutating func removeDuplicates() {
        self = self.removingDuplicates()
    }
}

struct APIHeader: Codable {
	var apiVersion: String
	var requested: UInt64?
	var type: String?
	var size: UInt32?
}

struct APIFuel: Codable {
	var id: String
	var type: String
	var updated: Date
	var relevant: Bool
	var amount: Double
}

struct APILocation: Codable {
	var x: Double
	var y: Double
}

struct APIFuelPrice: Codable {
	var id: String?
	var stationId: String?
	var type: String?
	var updated: Date?
	var relevant: Bool?
	var reportedBy: String?
	var amount: Double
}

struct APIFuelPrices: Codable {
	var DIESEL: APIFuelPrice?
	var U98 : APIFuelPrice?
	var U95 : APIFuelPrice?
	var LPG : APIFuelPrice?
	var E10 : APIFuelPrice?
	var TruckDSL : APIFuelPrice?
	var PremDSL : APIFuelPrice?
	var E85 : APIFuelPrice?
	var U91 : APIFuelPrice?
	var BIODIESEL : APIFuelPrice?
	var AdBlue : APIFuelPrice?
}

struct APIStation: Codable, Hashable, Identifiable {
	static func == (lhs: APIStation, rhs: APIStation) -> Bool {
		return lhs.id == rhs.id
	}
	var id: String
	var name: String
	var brand: String
	var state: String
	var suburb: String
	var address: String
	var postCode: String?
	var country: String?
	var phone: String?
	var location: APILocation
	var prices: APIFuelPrices
	var icon: String?
	var brandIcon: String?
	var autoUpdated: Bool?
	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
}

struct APIFuelExpiration : Codable {
	var fresh: UInt32
	var fade: UInt32
	var type: String
}

struct APIExpiration : Codable {
	var DIESEL: APIFuelExpiration?
	var U98 : APIFuelExpiration?
	var U95 : APIFuelExpiration?
	var LPG : APIFuelExpiration?
	var E10 : APIFuelExpiration?
	var TruckDSL : APIFuelExpiration?
	var PremDSL : APIFuelExpiration?
	var E85 : APIFuelExpiration?
	var U91 : APIFuelExpiration?
	var BIODIESEL : APIFuelExpiration?
	var AdBlue : APIFuelExpiration?
}

struct APIMessage: Codable {
	var expiration: APIExpiration
	var list: [APIStation]
}

struct JSONAPI: Codable {
	var header: APIHeader
	var message: APIMessage
}

func decodeAPI(data: Data) throws -> JSONAPI? {
    do {
        let decoder = JSONDecoder()
        let APIData = try decoder.decode(JSONAPI.self, from: data)
        return APIData
    } catch let error {
        print(error)
        return nil
    }
}

func RequestPrice(URLString: String, completion: @escaping (Result<[APIStation], Error>)->()) {
	let url = URL(string: URLString)!
	let task = URLSession.shared.dataTask(with: url) {
		(data, response, error) in
		
		guard let data = data else { return }
		
		do {
			let APIData = try decodeAPI(data: data)
			print(APIData?.message.list ?? "nil")
			completion(.success(APIData?.message.list ?? []))
		}
		catch let e {
			completion(.failure(e))
		}
	}
	task.resume()
}

func FetchPrices() {
	let serialQueue = DispatchQueue(label: "loadingSerialQueue")
	
	let init_lat: Int16 = -15
	let lat_interval: Int16 = 1
	let max_lat: Int16 = -45
	let lat_range: Int16 = -1 * (max_lat - init_lat)

	let init_long: Int16 = 112
	let long_interval: Int16 = 3
	let max_long: Int16 = 155
	let long_range: Int16 = (max_long - init_long)

	var stationData = [APIStation]()
	
//	var progress:Int8 = 0
//	var completed:Int8 = 0
	
	serialQueue.async {
		for lat in 0...lat_range {
			for long in 0...long_range {
				let url = "https://petrolspy.com.au/webservice-1/station/box?neLat=" + String(init_lat - lat) + "&neLng=" + String(init_long + long + long_interval) +
					"&swLat=" + String(init_lat - lat - lat_interval) +
					"&swLng=" + String(init_long + long)
				
				RequestPrice(URLString: url) { (res) in
					switch res {
					case .success(let stations):
						stations.forEach{(station) in
							ContentView.fuelPrices.append(station)
						}
							break
						default:
							break
					}
				}
				if (lat == lat_range && long == long_range) {
					ContentView.isLoadingFuel = false
				}
			}
		}
	}
}

func FindCheapest(stationData: [APIStation], fuel: String, count: Int = 5) -> [APIStation] {
	var data711 = stationData.removingDuplicates().filter {
		$0.brand == "SEVENELEVEN"
	}
	switch fuel {
		case "U91":
			data711.sort {
				$0.prices.U91!.amount < $1.prices.U91!.amount
			}
			break
		
		case "DIESEL":
			data711.sort {
				$0.prices.DIESEL!.amount < $1.prices.DIESEL!.amount
			}
			break
		
		case "E10":
			data711.sort {
				$0.prices.E10!.amount < $1.prices.E10!.amount
			}
			break
		
		default:
			break
	}
	return Array(data711[..<count])
}

struct StationRow: View {
    var station: APIStation

    var body: some View {
        Text("Come and eat at \(station.name)")
    }
}

func ListBody(modelData: [APIStation]?, fuel: String) -> some View {
	return List(modelData ?? [], id: \.id) { station in
		HStack {
			Image(systemName: "gauge")
				.frame(width: CGFloat(50), height: CGFloat(10), alignment: .leading)
			Text(String(format: "%.1f", station.prices.U91?.amount ?? 0) + "c")
				.frame(width: CGFloat(50), height: CGFloat(10), alignment: .leading)
			VStack {
				Text("\(station.suburb), \(station.state)")
			}
		}.font(.title)
    }
}

struct LoadingIcon: View {
	@State private var animateTrimmedCicle = true
    @State private var animateInnerCicle = false

	var body: some View {
		ZStack {
			Circle()
				.frame(width: 30, height: 30)
				.foregroundColor(Color(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)))
				.scaleEffect(animateInnerCicle ? 1 : 0.5)
				.animation(Animation.interpolatingSpring(stiffness: 100, damping: 20).speed(1).repeatForever(autoreverses: true))
				 .onAppear() {
					self.animateInnerCicle.toggle()
			}
			ZStack {
				Circle()
					.trim(from: 3/4, to: 1)
					.stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
					.frame(width: 50, height: 50)
					.foregroundColor(Color(#colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)))
				Circle()
					.trim(from: 3/4, to: 1)
					.stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
					.frame(width: 50, height: 50)
					.foregroundColor(Color(#colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)))
					.rotationEffect(.degrees(-180))
			}.scaleEffect(animateTrimmedCicle ? 1 : 0.4 )
				.rotationEffect(.degrees(animateTrimmedCicle ? 1080 : 0))
				.animation(Animation.interpolatingSpring(stiffness: 100, damping: 20).speed(1).repeatForever(autoreverses: true))
				 .onAppear() {
					self.animateTrimmedCicle.toggle()
				}
		}
	}
}

struct ContentView: View {
	let serialQueue = DispatchQueue(label: "loadingSerialQueue")
	@State var loadProgress = 0
	
    @State private var tab = 1
	@State var stationDisplayState = displayState.unloaded
	@State var selectedFuel = "U91"
	@State static var isLoadingFuel = false
	static var fuelPrices : [APIStation] = []
	
	enum displayState {
		case unloaded
		case loading
		case loaded
	}
	
    var body: some View {
		TabView(selection: $tab){
			MapView()
                .tabItem {
                    VStack {
						Image("first")
                        Text("Map")
                    }
                }
                .tag(0)
			
			VStack {
				Text("Find Cheapest Price")
					.font(.title)
					.padding(.bottom)
				
				
				if (stationDisplayState == .loading) {
					VStack {
						LoadingIcon()
							.padding(.vertical)
						Text("\(loadProgress)%")
					}
				}
				else if(stationDisplayState == .loaded) {
					Picker(selection: $selectedFuel, label: Text("")) {
						Text("U91").tag(1)
						Text("E10").tag(2)
						Text("Diesel").tag(3)
						Text("U95").tag(4)
						Text("U98").tag(5)
					}
					ListBody(
						modelData: FindCheapest(
							stationData: ContentView.fuelPrices,
							fuel: selectedFuel
						),
						fuel: selectedFuel
					)
				} else {
					Button(action: {
						self.serialQueue.sync {
							self.stationDisplayState = .loading
							ContentView.isLoadingFuel = true
							FetchPrices()
							
							if (ContentView.isLoadingFuel == false) {
								self.stationDisplayState = .loaded
							}
								
						}
						
					}) {
						Text("Find")
					}
				}
			}
                .tabItem {
                    VStack {
                        Image("second")
                        Text("Find")
                    }
                }
                .tag(1)
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
		let contentView = ContentView()
		return contentView
    }
}
