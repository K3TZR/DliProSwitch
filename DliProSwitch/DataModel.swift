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
  case jsonDecodeFailure
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

public struct CycleStep: Identifiable, Codable {
  internal init(id: UUID = UUID(), index: Int, enable: Bool, value: Bool, delay: Int) {
    self.id = id
    self.index = index
    self.enable = enable
    self.value = value
    self.delay = delay
  }
  
  public var id: UUID
  var index: Int
  var enable: Bool
  var value: Bool
  var delay: Int
}

public struct Device: Codable {
  internal init
  (
    name: String = "Unknown",
    title: String = "none",
    user: String = "",
    password: String = "",
    ipAddress: String = "",
    locks: [Bool] = Array(repeating: false, count: 8),
    showEmptyNames: Bool = true
  )
  {
    self.name = name
    self.title = title
    self.user = user
    self.password = password
    self.ipAddress = ipAddress
    self.locks = locks
    self.showEmptyNames = showEmptyNames
  }
  
  var name: String
  var title: String
  var user: String
  var password: String
  var ipAddress: String
  var locks: [Bool]
  var showEmptyNames: Bool
  var cycleOnList = [
    CycleStep(index: 0, enable: false, value: false, delay: 2),
    CycleStep(index: 1, enable: false, value: false, delay: 2),
    CycleStep(index: 2, enable: false, value: false, delay: 2),
    CycleStep(index: 3, enable: false, value: false, delay: 2),
    CycleStep(index: 4, enable: false, value: false, delay: 2),
    CycleStep(index: 5, enable: false, value: false, delay: 2),
    CycleStep(index: 6, enable: false, value: false, delay: 2),
    CycleStep(index: 7, enable: false, value: false, delay: 2),
  ]
  var cycleOffList = [
    CycleStep(index: 0, enable: false, value: false, delay: 2),
    CycleStep(index: 1, enable: false, value: false, delay: 2),
    CycleStep(index: 2, enable: false, value: false, delay: 2),
    CycleStep(index: 3, enable: false, value: false, delay: 2),
    CycleStep(index: 4, enable: false, value: false, delay: 2),
    CycleStep(index: 5, enable: false, value: false, delay: 2),
    CycleStep(index: 6, enable: false, value: false, delay: 2),
    CycleStep(index: 7, enable: false, value: false, delay: 2),
  ]
}

@MainActor
class DataModel: ObservableObject {
  @AppStorage("deviceIndex") var deviceIndex = -1
  @Published var relays = defaultRelays
  @Published var inProcess = false
  @Published var devices: [Device] = []
  
  @Published var showSheet = false
  var thrownError: Error? = nil
    
  // ----------------------------------------------------------------------------
  // MARK: - Device methods
  
  func deviceAdd(_ name: String, _ title: String, _ user: String, _ password: String, _ ipAddress: String) {
    // add a Device
    let device = Device(name: name, title: title, user: user, password: password, ipAddress: ipAddress)
    devices.append(device)
    // set the index to pont to it
    deviceIndex = devices.count - 1
    // resave all devices to user defaults
    for (index, device) in devices.enumerated() {
      setStruct("device\(index)", device)
    }
  }
  
  func deviceDelete() {
    if deviceIndex == 0 {
      // add the default (will be at index == 1)
      deviceAdd("New", "", "", "", "")
      // delete the one that was at index == 0
      devices.remove(at: deviceIndex)
    } else {
      // decrement the index and remove (at the pre-decrement index value)
      deviceIndex -= 1
      devices.remove(at: deviceIndex + 1)
    }

    // make all of the saved devices empty (nil)
    let nilDevice: Device? = nil
    for index in 0...7 {
      setStruct("device\(index)", nilDevice)
    }
    // save all  current devices to user defaults
    for (index, device) in devices.enumerated() {
      setStruct("device\(index)", device)
    }
  }

  func deviceLoad() {
    // max of 8 devices
//    deviceIndex = 0
    if let device:Device = getStruct("device0") { devices.append(device) }
    if let device:Device = getStruct("device1") { devices.append(device) }
    if let device:Device = getStruct("device2") { devices.append(device) }
    if let device:Device = getStruct("device3") { devices.append(device) }
    if let device:Device = getStruct("device4") { devices.append(device) }
    if let device:Device = getStruct("device5") { devices.append(device) }
    if let device:Device = getStruct("device6") { devices.append(device) }
    if let device:Device = getStruct("device7") { devices.append(device) }
    
    // make sure there is always at least one device
    if devices.count == 0 { deviceAdd("New", "", "", "", "")}
  }

  func deviceSave() {
    // save the device to user defaults
    setStruct("device\(deviceIndex)", devices[deviceIndex])
    
    // make an array of the relay names
    var newNames = [String]()
    for relay in relays {
      newNames.append(relay.name)
    }
    let ipAddress = devices[deviceIndex].ipAddress
    Task {
      // update the relay names from the array of names
      for index in 0...7 {
        await setRemoteProperty(ipAddress, .name, at: index, to: newNames[index])
        // ??? seems to have problems if we go too fast
        try! await Task.sleep(for: .milliseconds(50))
      }
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Relay methods
  
  func relaySetName(_ name: String, _ index: Int) {
    // prevent re-entrancy
    guard !inProcess else { return }
    inProcess = true
    defer { inProcess = false }
    
    let ipAddress = devices[deviceIndex].ipAddress
    if !relays[index].locked {
      Task {
        await setRemoteProperty(ipAddress, .name, at: index, to: name)
      }
    }
  }
  
  func relayToggleState(_ index: Int) {
    guard !inProcess else { return }
    inProcess = true
    defer { inProcess = false }
    guard index >= 0 && index < relays.count else { return }
    
    // tell the box to change the relay's state
    let newValue = relays[index].status ? "false" : "true"
    let ipAddress = devices[deviceIndex].ipAddress
    Task {
      await setRemoteProperty(ipAddress, .status, at: index, to: newValue)
    }
    // change it locally
    relays[index].status.toggle()
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Relays methods
  
  func relaysAllState(_ value: Bool) {
    // prevent re-entrancy
    guard !inProcess else { return }
    inProcess = true
    defer { inProcess = false }

    let ipAddress = devices[deviceIndex].ipAddress
    Task {
      await setRemoteProperty(ipAddress, .status, at: -1, to: value ? "true" : "false")
    }
    for i in 0...7 {
      if !relays[i].locked { relays[i].status = value }
    }
  }
  
  func relaysCycle(on: Bool) {
    // prevent re-entrancy
    guard !inProcess else { return }
    
    let ipAddress = devices[deviceIndex].ipAddress
    Task {
      setInProcess(true)
      if on {
        for entry in devices[deviceIndex].cycleOnList {
          if entry.enable && !relays[entry.index - 1].locked {
            await setRemoteProperty(ipAddress, .status, at: entry.index - 1, to: entry.value ? "true" : "false")
            relays[entry.index - 1].status = entry.value
            try await Task.sleep(for: .seconds(entry.delay))
          }
        }
      } else {
        for entry in devices[deviceIndex].cycleOffList {
          if entry.enable && !relays[entry.index - 1].locked {
            await setRemoteProperty(ipAddress, .status, at: entry.index - 1, to: entry.value ? "true" : "false")
            relays[entry.index - 1].status = entry.value
            try await Task.sleep(for: .seconds(entry.delay))
          }
        }
      }
      setInProcess(false)
    }
  }

  func relaysRefresh() {
    Task {
      do {
        try await relaysSynchronize()
      } catch {
        showSheet = true
      }
    }
  }
  
  func relaysSynchronize() async throws {
    // prevent re-entrancy
    guard !inProcess else { return }
    inProcess = true
    defer { inProcess = false }
    
    // get device characteristics
    let user = devices[deviceIndex].user
    let password = devices[deviceIndex].password
    
    // interrogate the device
    do {
      relays = try JSONDecoder().decode( [Relay].self, from: (await getRequest(url: URL(string: "https://\(devices[deviceIndex].ipAddress)/restapi/relay/outlets/")!,
                                                                               user: user,
                                                                               password: password)))
    } catch {
      thrownError = error as? ApiError
      showSheet = true
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Misc methods
  
  private func setInProcess(_ state: Bool) {
      inProcess = state
  }
  
  private func setRemoteProperty(_ ipaddress: String, _ property: Relay.CodingKeys, at index: Int, to value: String) async {
    var indexString = ""
    
    if index == -1 {
      indexString = "all;"
    } else if index >= 0 && index < relays.count {
      indexString = String(index)
    } else {
      return
    }
    let user = devices[deviceIndex].user
    let password = devices[deviceIndex].password
    let url = URL(string: "https://\(ipaddress)/restapi/relay/outlets/\(indexString)/\(property.rawValue)/")!
    do {
      try await putRequest(Data(value.utf8), url: url, user: user, password: password)
    } catch {
      thrownError = error
      showSheet = true
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - URL methods
  
  func getRequest(url: URL, user: String, password: String) async throws -> Data {
    let successRange = 200...299
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
    guard successRange.contains((response as! HTTPURLResponse).statusCode) else {
      throw ApiError.getRequestFailure
    }
    return data
  }
  
  func putRequest(_ data: Data, url: URL, user: String, password: String, jsonContent: Bool = false) async throws {
    let successRange = 200...299
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
  Relay(name: "Relay 1", status: false, locked: false),
  Relay(name: "Relay 2", status: false, locked: false),
  Relay(name: "Relay 3", status: false, locked: false),
  Relay(name: "Relay 4", status: false, locked: false),
  Relay(name: "Relay 5", status: false, locked: false),
  Relay(name: "Relay 6", status: false, locked: false),
  Relay(name: "Relay 7", status: false, locked: false),
  Relay(name: "Relay 8", status: false, locked: false),
]

// ----------------------------------------------------------------------------
// MARK: - User defaults for structs

/// Read a user default entry and transform it into a struct
/// - Parameters:
///    - key:         the name of the default
/// - Returns:        a struct or nil
public func getStruct<T: Decodable>(_ key: String) -> T? {
  
  if let data = UserDefaults.standard.object(forKey: key) as? Data {
    let decoder = JSONDecoder()
    if let value = try? decoder.decode(T.self, from: data) {
      return value
    } else {
      return nil
    }
  }
  return nil
}

/// Write a user default entry for a struct
/// - Parameters:
///    - key:        the name of the default
///    - value:      a struct  to be encoded and written to user defaults
public func setStruct<T: Encodable>(_ key: String, _ value: T?) {
  
  if value == nil {
    UserDefaults.standard.removeObject(forKey: key)
  } else {
    let encoder = JSONEncoder()
    if let encoded = try? encoder.encode(value) {
      UserDefaults.standard.set(encoded, forKey: key)
    } else {
      UserDefaults.standard.removeObject(forKey: key)
    }
  }
}
