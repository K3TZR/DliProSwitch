//
//  DataModel.swift
//
//
//  Created by Douglas Adams on 4/13/22.
//

import Foundation
import SwiftUI

enum ApiError: Error {
  case getRequestFailure
  case putRequestFailure
  case queryFailure
}

public struct Relay: Codable, Equatable, Identifiable {
  
  public init(
    name: String,
    status: Bool = false,
    locked: Bool = false
  ) {
    self.name = name
    self.status = status
    self.locked = locked
  }
  public var id = UUID()
  public var name: String
  public var status: Bool
  public var locked: Bool
  
  public enum CodingKeys: String, CodingKey {
    case name
    case status = "state"
    case locked
  }
}

public struct CycleStep {
  var index: Int
  var value: Bool
  var delay: Int
}

public struct Device {
  internal init(name: String, title: String, user: String, password: String, ipAddress: String, locks: [Bool]) {
    self.name = name
    self.title = title
    self.user = user
    self.password = password
    self.ipAddress = ipAddress
    self.locks = locks
  }
  
  var name: String
  var title: String
  var user: String
  var password: String
  var ipAddress: String
  var locks: [Bool]
}

@MainActor
class DataModel: ObservableObject {
  @Published var deviceIndex = 0
  @Published var ipAddress = ""
  @Published var locks = Array(repeating: false, count: 8)
  @Published var password = ""
  @Published var relays = defaultRelays
  @Published var title = ""
  @Published var user = ""
  @Published var inProcess = false
  
  public var devices: [Device] = [
    Device(name: "DIN 4",
           title: "K3TZR Relay Box",
           user: "admin",
           password: "ruwn1viwn_RUF_zolt",
           ipAddress: "192.168.1.220",
           locks: [false,false,false,false,false,false,false,false,]),
    
    Device(name: "Switch Pro",
           title: "K3TZR Shack Control",
           user: "admin",
           password: "8PsCVECFUeyg3Atcq3ZB",
           ipAddress: "192.168.1.221",
           locks: [false,false,false,false,false,false,false,false,]),
  ]
  
  var cycleOnList: [CycleStep] = [
    CycleStep(index: 0, value: true, delay: 2),
    CycleStep(index: 1, value: true, delay: 2),
    CycleStep(index: 2, value: true, delay: 2),
    CycleStep(index: 3, value: true, delay: 2),
    CycleStep(index: 4, value: true, delay: 2),
    CycleStep(index: 5, value: true, delay: 2),
    CycleStep(index: 6, value: true, delay: 2),
    CycleStep(index: 7, value: true, delay: 2),
  ]

  var cycleOffList: [CycleStep] = [
    CycleStep(index: 0, value: false, delay: 2),
    CycleStep(index: 1, value: false, delay: 2),
    CycleStep(index: 2, value: false, delay: 2),
    CycleStep(index: 3, value: false, delay: 2),
    CycleStep(index: 4, value: false, delay: 2),
    CycleStep(index: 5, value: false, delay: 2),
    CycleStep(index: 6, value: false, delay: 2),
    CycleStep(index: 7, value: false, delay: 2),
  ]

  func synchronize() async throws {
    guard !inProcess else { return }
    inProcess = true
    defer { inProcess = false }
    // get device characteristics
    ipAddress = devices[deviceIndex].ipAddress
    title = devices[deviceIndex].title
    user = devices[deviceIndex].user
    password = devices[deviceIndex].password
    locks = devices[deviceIndex].locks
    
    // interrogate the device
    do {
      relays = try JSONDecoder().decode( [Relay].self, from: (await getRequest(url: URL(string: "https://\(ipAddress)/restapi/relay/outlets/")!)))
    } catch {
      throw(ApiError.queryFailure)
    }
  }
  
  func toggleStatus(_ index: Int) {
    guard !inProcess else { return }
    inProcess = true
    defer { inProcess = false }
    guard index >= 0 && index < relays.count else { return }
    // tell the box to change the relay's state
    setRemoteProperty(ipAddress, .status, at: index, to: relays[index].status ? "false" : "true")
    // change it locally
    relays[index].status.toggle()
  }
  
  func refresh() {
    Task {
      try await synchronize()
    }
  }
  
  func allSet(_ value: Bool) {
    guard !inProcess else { return }
    inProcess = true
    defer { inProcess = false }
    setRemoteProperty(ipAddress, .status, at: nil, to: value ? "true" : "false")
    for i in 0...7 {
      if !relays[i].locked { relays[i].status = value }
    }
  }
  
  func setName(_ name: String, _ index: Int) {
    guard !inProcess else { return }
    inProcess = true
    defer { inProcess = false }
    if !relays[index].locked {
      setRemoteProperty(ipAddress, .name, at: index, to: name)
    }
  }
  
  func setInProcess(_ state: Bool) {
      inProcess = state
  }
  
  func cycle(on: Bool) {
    // TODO:
    guard !inProcess else { return }
    Task {
      setInProcess(true)
      if on {
        for entry in cycleOnList {
          if !relays[entry.index].locked {
            setRemoteProperty(ipAddress, .status, at: entry.index, to: entry.value ? "true" : "false")
            relays[entry.index].status = entry.value
            try await Task.sleep(for: .seconds(entry.delay))
          }
        }
      } else {
        for entry in cycleOffList {
          if !relays[entry.index].locked {
            setRemoteProperty(ipAddress, .status, at: entry.index, to: entry.value ? "true" : "false")
            relays[entry.index].status = entry.value
            try await Task.sleep(for: .seconds(entry.delay))
          }
        }
      }
      setInProcess(false)
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - URL methods
  
  func setRemoteProperty(_ ipaddress: String, _ property: Relay.CodingKeys, at index: Int? = nil, to value: String) {
    var indexString = "all;"
    
    if let index = index {
      guard index >= 0 && index < relays.count else { return }
      indexString = String(index)
    }
    
    let url = URL(string: "https://\(ipaddress)/restapi/relay/outlets/\(indexString)/\(property.rawValue)/")!
    Task {
      do {
        try await putRequest(Data(value.utf8), url: url)
      } catch {
        print("Failed to set relay \(property.rawValue)")
      }
    }
  }

  func getRequest(url: URL) async throws -> Data {
    let headers = [
      "Connection": "close",
      "Content-Type": "application/json",
      "Accept": "application/json",
      "X-CSRF": "x"
    ]
    var request = URLRequest(url: url)
    request.setBasicAuth(user, password)
    request.httpMethod = "GET"
    request.allHTTPHeaderFields = headers

    let (data, response) = try await URLSession.shared.data(for: request)
    let successRange = 200...299
    print("Get Request: response code = \((response as! HTTPURLResponse).statusCode)")
    guard successRange.contains((response as! HTTPURLResponse).statusCode) else {
      throw ApiError.getRequestFailure
    }
    return data
  }
  
  func putRequest(_ data: Data, url: URL, jsonContent: Bool = false) async throws {
    
    var headers: [String:String] = [:]
    
    if jsonContent {
      headers = [
        "Connection": "close",
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-CSRF": "x"
      ]
    } else {
      headers = [
        "Connection": "close",
        "ContentType":"text/plain",
        "X-CSRF": "x"
      ]
    }
    
    var request = URLRequest(url: url)
    request.setBasicAuth(user, password)
    request.allHTTPHeaderFields = headers
    request.httpMethod = jsonContent ? "POST" : "PUT"
    request.httpBody = data
    
    let (_, response) = try await URLSession.shared.data(for: request)
    
    let successRange = 200...299
    print("Put Request: response code = \((response as! HTTPURLResponse).statusCode)")
    guard successRange.contains((response as! HTTPURLResponse).statusCode) else {
      throw ApiError.putRequestFailure
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - URL extension

extension URLRequest {
  mutating func setBasicAuth(_ user: String, _ pwd: String) {
    let encodedAuthInfo = String(format: "%@:%@", user, pwd)
      .data(using: String.Encoding.utf8)!
      .base64EncodedString()
    addValue("Basic \(encodedAuthInfo)", forHTTPHeaderField: "Authorization")
  }
}

// ----------------------------------------------------------------------------
// MARK: - Default Relays

let defaultRelays = [
  Relay(name: "Relay 0", status: false, locked: false),
  Relay(name: "Relay 1", status: false, locked: false),
  Relay(name: "Relay 2", status: false, locked: false),
  Relay(name: "Relay 3", status: false, locked: false),
  Relay(name: "Relay 4", status: false, locked: false),
  Relay(name: "Relay 5", status: false, locked: false),
  Relay(name: "Relay 6", status: false, locked: false),
  Relay(name: "Relay 7", status: false, locked: false),
]

