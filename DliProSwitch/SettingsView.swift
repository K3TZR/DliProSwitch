//
//  SettingsView.swift
//  DliProSwitch
//
//  Created by Douglas Adams on 1/11/23.
//

//import ComposableArchitecture
import SwiftUI

struct SettingsView: View {
  @ObservedObject var model: DataModel
  
  enum Focusable: String, Hashable, Equatable {
    case relay0
    case relay1
    case relay2
    case relay3
    case relay4
    case relay5
    case relay6
    case relay7
    //    case title
    //    case ipAddress
    //    case user
    //    case password
  }
  
  @FocusState private var hasFocus: Focusable?
  
  var body: some View {
    VStack {
      Picker("Device", selection: $model.deviceIndex) {
        ForEach(Array(model.devices.enumerated()), id: \.offset) { offset, device in
          Text(device.name).tag(offset)
        }
      }.frame(width: 300)
      Divider()
      HStack(spacing: 20) {
        Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 10) {
          GridRow {
            Text("Title").frame(width: 37, alignment: .leading)
            Text(model.devices[model.deviceIndex].title).frame(width: 200, alignment: .leading)
          }
          GridRow {
            Text("User")
            Text(model.devices[model.deviceIndex].user)
          }
        }
        Spacer()
        Grid(alignment: .leading, horizontalSpacing: 30, verticalSpacing: 10) {
          GridRow {
            Text("IP Address")
            Text(model.devices[model.deviceIndex].ipAddress)
          }
          GridRow {
            Text("Password")
            Text(model.devices[model.deviceIndex].password).frame(width: 200, alignment: .leading)
          }
        }
    }
    Divider()
    HStack(spacing: 20) {
      Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 10) {
        GridRow {
          Text("Relay 0")
          TextField("name", text: $model.relays[0].name)
            .focused($hasFocus, equals: .relay0)
            .onSubmit { model.setName(model.relays[0].name, 0)}
//          Toggle("Locked", isOn: $model.relays[0].softLock)
        }
        GridRow {
          Text("Relay 2")
          TextField("name", text: $model.relays[2].name)
            .focused($hasFocus, equals: .relay2)
            .onSubmit { model.setName(model.relays[2].name, 2)}
//          Toggle("Locked", isOn: $model.relays[2].softLock)
        }
        GridRow {
          Text("Relay 4")
          TextField("name", text: $model.relays[4].name)
            .focused($hasFocus, equals: .relay4)
            .onSubmit { model.setName(model.relays[4].name, 4)}
//          Toggle("Locked", isOn: $model.relays[4].softLock)
        }
        GridRow {
          Text("Relay 6")
          TextField("name", text: $model.relays[6].name)
            .focused($hasFocus, equals: .relay6)
            .onSubmit { model.setName(model.relays[6].name, 6)}
//          Toggle("Locked", isOn: $model.relays[6].softLock)
        }
      }
      Spacer()
      Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 10) {
        GridRow {
          Text("Relay 1")
          TextField("name", text: $model.relays[1].name)
            .focused($hasFocus, equals: .relay1)
            .onSubmit { model.setName(model.relays[1].name, 1)}
//          Toggle("Locked", isOn: $model.relays[1].softLock)
        }
        GridRow {
          Text("Relay 3")
          TextField("name", text: $model.relays[3].name)
            .focused($hasFocus, equals: .relay3)
            .onSubmit { model.setName(model.relays[3].name, 3)}
//          Toggle("Locked", isOn: $model.relays[3].softLock)
        }
        GridRow {
          Text("Relay 5")
          TextField("name", text: $model.relays[5].name)
            .focused($hasFocus, equals: .relay5)
            .onSubmit { model.setName(model.relays[5].name, 5)}
//          Toggle("Locked", isOn: $model.relays[5].softLock)
        }
        GridRow {
          Text("Relay 7")
          TextField("name", text: $model.relays[7].name)
            .focused($hasFocus, equals: .relay7)
            .onSubmit { model.setName(model.relays[7].name, 7)}
//          Toggle("Locked", isOn: $model.relays[7].softLock)
        }
      }
    }
    HStack {
      Spacer()
      Button("Refresh") { model.refresh() }
    }
  }
    .onChange(of: hasFocus) { [hasFocus] _ in
      //      print("onChange: from \(hasFocus?.rawValue ?? "none") -> \(newValue?.rawValue ?? "none")")
      switch hasFocus {
      case .relay0:    model.setName(model.relays[0].name, 0)
      case .relay1:    model.setName(model.relays[1].name, 1)
      case .relay2:    model.setName(model.relays[2].name, 2)
      case .relay3:    model.setName(model.relays[3].name, 3)
      case .relay4:    model.setName(model.relays[4].name, 4)
      case .relay5:    model.setName(model.relays[5].name, 5)
      case .relay6:    model.setName(model.relays[6].name, 6)
      case .relay7:    model.setName(model.relays[7].name, 7)
        //      case .title, .ipAddress, .user, .password:    break
      case .none:   break
      }
    }
    .frame(width: 600, height: 220)
    .padding()
}
}

struct SettingsView_Previews: PreviewProvider {
  static var previews: some View {
    SettingsView(model: DataModel())
  }
}
