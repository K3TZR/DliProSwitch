//
//  ContentView.swift
//  DliProSwitch
//
//  Created by Douglas Adams on 1/11/23.
//

import AVFoundation
import SwiftUI

struct DashboardView: View {
  @ObservedObject var model: DataModel
  
  var body: some View {
    
    let device = model.devices[model.selectedDevice]
    
    VStack {
      Text(device.title).font(.title)
      Divider().background(Color(.blue))
      Spacer()
      
      Grid(verticalSpacing: 10) {
        ForEach(model.relays, id: \.id) { relay in
          if device.showEmptyNames || !relay.name.isEmpty {
            GridRow {
              Text("\(relay.number). " + relay.name).font(.title2).frame(width: 170, alignment: .leading)
              Image(systemName: relay.isLocked ? "lock.slash.fill" : device.locks[relay.number - 1] ? "lock" : "power")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(relay.isOn ? .green : .red)
                .onTapGesture {
                  model.relayToggleState(relay.number - 1)
                }.disabled( model.inProcess || relay.isLocked || device.locks[relay.number - 1] )
              
                .contextMenu {
                  Button("Cycle") { model.relayCycle(relay.number - 1)}
                  Button(device.locks[relay.number - 1] ? "Unlock" : "Lock") { model.deviceToggleLock(relay.number - 1) }
                }.disabled( model.inProcess || relay.isLocked )
            }
          }
        }
        BottomButtonsView(model: model)
      }
    }
    .frame(width: 275, height:450)
    .padding(.horizontal)
    .padding(.bottom)
    
    .onAppear {
      if device.user.isEmpty || device.password.isEmpty || device.ipAddress.isEmpty {
        model.showSheet = true
      } else {
        Task {
          do {
            // read the physical device
            try await model.loadRelays()
          } catch {
            model.showSheet = true
          }
        }
      }
    }
    
    .sheet(isPresented: $model.showSheet) {
      FailureView(model: model)
    }
  }
}

private struct BottomButtonsView: View {
  @ObservedObject var model: DataModel
  
  var body: some View {
    Spacer()
    Divider().background(Color(.blue))
    HStack {
      Button(action: { model.relaysAllState(false) }){ Text("All OFF") }
      Spacer()
      Text("Cycle")
      Button("ON") { model.relaysCycle(on: true) }
      Button("OFF") { model.relaysCycle(on: false) }
    }.disabled(model.inProcess)
  }
}

struct Dashboardiew_Previews: PreviewProvider {
  static var previews: some View {
    DashboardView(model: DataModel())
  }
}

struct FailureView: View {
  let model: DataModel
  
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    
    let device = model.devices[model.selectedDevice]

    VStack {
      if device.user.isEmpty || device.password.isEmpty || device.ipAddress.isEmpty {
        Text("\(device.name)").font(.title).foregroundColor(.red)
        Divider().background(Color(.blue))
        Spacer()
        Text("One or more properties empty").font(.title2)
        Text("Update the Device").font(.title2)
        Spacer()

      } else if model.thrownError != nil {
        Text("An error occurred").font(.title).foregroundColor(.red)
        Divider().background(Color(.blue))
        Spacer()
        if let theError = model.thrownError as? ApiError {
          switch theError {
          case .getRequestFailure:  Text("Get request failure").font(.title2)
          case .jsonDecodeFailure:  Text("Json decode failure").font(.title2)
          case .putRequestFailure:  Text("Put request failure").font(.title2)
          case .queryFailure:       Text("Device query failure").font(.title2)
          }
        } else {
          Text("Unknown error").font(.title2)
        }
        Spacer()
        Divider().background(Color(.blue))
        Spacer()
        Text("Check your device & settings").font(.title2)

      } else {
        Text(model.devices[model.selectedDevice].name).font(.title)
        Text("Unable to reach the Device").font(.title2).foregroundColor(.red)
        Divider().background(Color(.blue))
//        Spacer()
        Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 10) {
          GridRow() {
            Text("at IP Address")
            Text(model.devices[model.selectedDevice].ipAddress)
          }
        }.font(.title2)
        Divider().background(Color(.blue))
        Spacer()
        Text("Update your settings").font(.title2)
      }
      
      Divider().background(Color(.blue))
      Button("OK") { dismiss(); NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil) }.keyboardShortcut(.defaultAction)
    }
    
    .frame(width: 275, height: 200)
    .padding()
  }
}
