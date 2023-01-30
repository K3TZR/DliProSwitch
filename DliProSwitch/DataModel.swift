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
    name: String = "",
    isOn: Bool = false,
    isLocked: Bool = false
  ) {
    self.name = name
    self.isOn = isOn
    self.isLocked = isLocked
  }
  public var id = UUID()
  public var number = 1
  public var name: String
  public var isOn: Bool
  public var isLocked: Bool
  
  public enum CodingKeys: String, CodingKey {
    case name
    case isOn = "state"
    case isLocked = "locked"
  }
}

public struct CycleStep: Identifiable, Codable {
  internal init(step: Int, relayNumber: Int, active: Bool, value: Bool, delay: Int) {
    self.step = step
    self.relayNumber = relayNumber
    self.active = active
    self.value = value
    self.delay = delay
  }
  
  public var id: Int { step }
  public var step: Int
  var relayNumber: Int
  var active: Bool
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
    locks: [Bool] = defaultLocks,
    cycleOnSteps: [CycleStep] = defaultCycleSteps,
    cycleOffSteps: [CycleStep] = defaultCycleSteps,
    cycleDelays: [Int] = defaultCycleDelays,
    showEmptyNames: Bool = true
  )
  {
    self.name = name
    self.title = title
    self.user = user
    self.password = password
    self.ipAddress = ipAddress
    self.locks = locks
    self.cycleOnSteps = cycleOnSteps
    self.cycleOffSteps = cycleOffSteps
    self.cycleDelays = cycleDelays
    self.showEmptyNames = showEmptyNames
  }
  
  var name: String
  var title: String
  var user: String
  var password: String
  var ipAddress: String
  var locks: [Bool]
  var showEmptyNames: Bool
  var cycleOnSteps: [CycleStep]
  var cycleOffSteps: [CycleStep]
  var cycleDelays: [Int]
}

@MainActor
class DataModel: ObservableObject {
  @AppStorage("selectedDevice") var selectedDevice = 0
  
  @Published var devices: [Device] = []
  @Published var inProcess = false
  @Published var relays = defaultRelays
  @Published var showSheet = false

  var previousRelays = defaultRelays
  var thrownError: Error? = nil
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  init() {
    deviceLoad()
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Device methods

  func deviceToggleLock(_ index: Int) {
    devices[selectedDevice].locks[index].toggle()
    deviceSave()
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Devices methods

  func deviceLoad() {
    // 8 devices
    if !devicesLoadSaved() {
      devicesLoadDefaults()
    }
    relaysLoadDefaults()
  }
  
  func devicesLoadSaved() -> Bool {
    for i in 0...7 {
      if let device:Device = getStruct("device\(i)") { devices.append(device) } else { return false }
    }
    print("Saved Devices loaded")
    
    return true
  }
  
  func devicesLoadDefaults() {
    for i in 0...7 {
      let device = Device(name: "Device\(i)", title: "Title\(i)")
      devices.append(device)
      setStruct("device\(i)", devices[i])
    }
    selectedDevice = 0
    
    print("Default Devices loaded & saved")
  }
  
  func cyclesLoadDefaults(_ device: inout Device) {
    device.cycleOnSteps = defaultCycleSteps
    device.cycleOffSteps = defaultCycleSteps
    
    print("Default Cycles loaded in Device \(device.name)")
  }

  func deviceSave() {
    // save the device to user defaults
    setStruct("device\(selectedDevice)", devices[selectedDevice])
    
    // make an array of the relay names
    var newRelayNames = [(Int,String)]()
    for (i, relay) in relays.enumerated() {
      if relay.name != previousRelays[i].name {
        newRelayNames.append( (i,relay.name) )
      }
    }
    let ipAddress = devices[selectedDevice].ipAddress
    Task {
      // update the relay names from the array of names
      for entry in newRelayNames {
        await setRemoteProperty(ipAddress, .name, at: entry.0, to: entry.1)
        // ??? seems to have problems if we go too fast
        try! await Task.sleep(for: .milliseconds(50))
      }
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Relay methods
  
  func relayCycle(_ index: Int) {
    let initialState = relays[index].isOn
    
    // prevent re-entrancy
    guard !inProcess else { return }
    guard !relays[index].isLocked else { return }
    
    let device = devices[selectedDevice]
    let ipAddress = device.ipAddress
    let cycleDelay = device.cycleDelays[index]
    
    Task {
      setInProcess(true)
      await setRemoteProperty(ipAddress, .isOn, at: index, to: initialState ? "false" : "true")
      relays[index].isOn = !initialState
      try await Task.sleep(for: .seconds(cycleDelay))
      
      await setRemoteProperty(ipAddress, .isOn, at: index, to: initialState ? "true" : "false")
      relays[index].isOn = initialState
//      try await Task.sleep(for: .seconds(cycleDelay))
      setInProcess(false)
    }
  }
  
  
  func relaySetName(_ name: String, _ index: Int) {
    // prevent re-entrancy
    guard !inProcess else { return }
    inProcess = true
    defer { inProcess = false }
    
    let ipAddress = devices[selectedDevice].ipAddress
    if !relays[index].isLocked {
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
    let newValue = relays[index].isOn ? "false" : "true"
    let ipAddress = devices[selectedDevice].ipAddress
    Task {
      await setRemoteProperty(ipAddress, .isOn, at: index, to: newValue)
    }
    // change it locally
    relays[index].isOn.toggle()
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Relays methods
  
  func relaysAllState(_ value: Bool) {
    // prevent re-entrancy
    guard !inProcess else { return }
    inProcess = true
    defer { inProcess = false }

    let ipAddress = devices[selectedDevice].ipAddress
    Task {
      await setRemoteProperty(ipAddress, .isOn, at: -1, to: value ? "true" : "false")
    }
    for i in 0...7 {
      if !relays[i].isLocked { relays[i].isOn = value }
    }
  }
  
  func relaysCycle(on: Bool) {
    // prevent re-entrancy
    guard !inProcess else { return }
    
    let ipAddress = devices[selectedDevice].ipAddress
    Task {
      setInProcess(true)
      if on {
        for entry in devices[selectedDevice].cycleOnSteps {
          if entry.active && !relays[entry.relayNumber - 1].isLocked {
            await setRemoteProperty(ipAddress, .isOn, at: entry.relayNumber - 1, to: entry.value ? "true" : "false")
            relays[entry.relayNumber - 1].isOn = entry.value
            try await Task.sleep(for: .seconds(entry.delay))
          }
        }
      } else {
        for entry in devices[selectedDevice].cycleOffSteps {
          if entry.active && !relays[entry.relayNumber - 1].isLocked {
            await setRemoteProperty(ipAddress, .isOn, at: entry.relayNumber - 1, to: entry.value ? "true" : "false")
            relays[entry.relayNumber - 1].isOn = entry.value
            try await Task.sleep(for: .seconds(entry.delay))
          }
        }
      }
      setInProcess(false)
    }
  }

  func relaysLoadDefaults() {
    relays = defaultRelays
    // fixup relay numbers
    for i in 0...7 {
      relays[i].number = i + 1
    }
    
    print("Default Relays loaded & re-numbered")
  }
  
  func relaysRefresh() {
    Task {
      do {
        try await loadRelays()
      } catch {
        showSheet = true
      }
    }
  }
  
  func loadRelays() async throws {
    // prevent re-entrancy
    guard !inProcess else { return }
    inProcess = true
    defer { inProcess = false }
    
    // get device characteristics
    let user = devices[selectedDevice].user
    let password = devices[selectedDevice].password
    
    // interrogate the device
    do {
      relays = try JSONDecoder().decode( [Relay].self, from: (await getRequest(url: URL(string: "https://\(devices[selectedDevice].ipAddress)/restapi/relay/outlets/")!,
                                                                               user: user,
                                                                               password: password)))
      
      // init the relay numbers
      for i in 0...7 {
        relays[i].number = i+1
      }
      previousRelays = relays

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
    let user = devices[selectedDevice].user
    let password = devices[selectedDevice].password
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
  Relay(name: "Relay 1", isOn: false, isLocked: false),
  Relay(name: "Relay 2", isOn: false, isLocked: false),
  Relay(name: "Relay 3", isOn: false, isLocked: false),
  Relay(name: "Relay 4", isOn: false, isLocked: false),
  Relay(name: "Relay 5", isOn: false, isLocked: false),
  Relay(name: "Relay 6", isOn: false, isLocked: false),
  Relay(name: "Relay 7", isOn: false, isLocked: false),
  Relay(name: "Relay 8", isOn: false, isLocked: false),
]

let defaultLocks = [Bool](repeating: false, count: 8)

let defaultCycleSteps = [
  CycleStep(step: 1, relayNumber: 1, active: false, value: false, delay: 2),
  CycleStep(step: 2, relayNumber: 2, active: false, value: false, delay: 2),
  CycleStep(step: 3, relayNumber: 3, active: false, value: false, delay: 2),
  CycleStep(step: 4, relayNumber: 4, active: false, value: false, delay: 2),
  CycleStep(step: 5, relayNumber: 5, active: false, value: false, delay: 2),
  CycleStep(step: 6, relayNumber: 6, active: false, value: false, delay: 2),
  CycleStep(step: 7, relayNumber: 7, active: false, value: false, delay: 2),
  CycleStep(step: 8, relayNumber: 8, active: false, value: false, delay: 2),
]

let defaultCycleDelays = [Int](repeating: 3, count: 8)

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
