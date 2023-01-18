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
    
    VStack {
      if model.deviceIndex == -1 || model.devices.count == 0 {
        Text("No Device")
        
      } else {
        Text(model.devices[model.deviceIndex].title).font(.title)
        Divider().background(Color(.blue))
        Spacer()
        Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 10) {
          
          ForEach(Array(model.relays.enumerated()), id: \.offset) { offset, relay in
            if model.devices[model.deviceIndex].showEmptyNames || !relay.name.isEmpty {
              GridRow {
                Text("\(offset+1). " + relay.name).font(.title2)
                Image(systemName: relay.locked ? "lock.shield" : model.devices[model.deviceIndex].locks[offset] ? "lock" : "power")
                  .font(.system(size: 28, weight: .bold))
                  .foregroundColor(relay.status ? .green : .red)
                  .onTapGesture {
                    model.relayToggleState(offset)
                  }.disabled( model.inProcess || relay.locked || model.devices[model.deviceIndex].locks[offset] )
                
                  .contextMenu {
                    Button(model.devices[model.deviceIndex].locks[offset] ? "Unlock" : "Lock") { model.devices[model.deviceIndex].locks[offset].toggle() }
                  }.disabled( model.inProcess || relay.locked )
              }
            }
          }
          BottomButtonsView(model: model)
        }
      }
    }
    .frame(width: 275, height:450)
    
    .onAppear {
      if model.deviceIndex == -1 {
        // No Device selected
        model.showSheet = true
        
      } else {
        // A Device is selected
        Task {
          do {
            // try to get the Device and sync
            model.deviceLoad()
            try await model.relaysSynchronize()
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
    
    VStack {
      if model.deviceIndex == -1 {
        Text("No Device Selected").font(.title).foregroundColor(.red)
        Divider().background(Color(.blue))
        Spacer()
        Text("Select or Add a Device").font(.title2)
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
        Text(model.devices[model.deviceIndex].name).font(.title)
        Text("Unable to reach the Device").font(.title2).foregroundColor(.red)
        Divider().background(Color(.blue))
//        Spacer()
        Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 10) {
          GridRow() {
            Text("at IP Address")
            Text(model.devices[model.deviceIndex].ipAddress)
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
