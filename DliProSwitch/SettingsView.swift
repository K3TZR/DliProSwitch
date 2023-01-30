//
//  SettingsView.swift
//  DliProSwitch
//
//  Created by Douglas Adams on 1/11/23.
//

import SwiftUI

struct SettingsView: View {
  @ObservedObject var model: DataModel
  
  var body: some View {
    VStack {
      HStack {
        Picker("Device", selection: $model.selectedDevice) {
          ForEach(Array(model.devices.enumerated()), id: \.offset) { offset, device in
            Text(device.name ).tag(offset)
          }
        }.frame(width: 300)
      }
      DeviceView(model: model)
      Divider().background(Color(.blue)).hidden()
      
      TabViews(model: model)
      Divider().background(Color(.blue)).hidden()
      
      Button("Save") { model.deviceSave()}
    }
    .frame(width: 600)
    .padding()
    
    .onChange(of: model.selectedDevice) { _ in
      model.relaysRefresh()
    }
  }
}

struct DeviceView: View {
  @ObservedObject var model: DataModel
  
  var body: some View {
    VStack {
      HStack(spacing: 40) {
        
        Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 10) {
          GridRow {
            Text("Name")
            TextField("Name for the Device", text: $model.devices[model.selectedDevice].name)
          }
          GridRow {
            Text("Title")
            TextField("Title for Dashboard view", text: $model.devices[model.selectedDevice].title)
          }
          GridRow {
            Text("User")
            TextField("Device login name", text: $model.devices[model.selectedDevice].user)
          }
        }
        
        Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 10) {
          GridRow {
            Toggle("Show empty Relay names", isOn: $model.devices[model.selectedDevice].showEmptyNames)
              .gridCellColumns(2)
          }
          GridRow {
            Text("IP Address")
            TextField("Device ip address", text: $model.devices[model.selectedDevice].ipAddress)
          }
          GridRow {
            Text("Password")
            TextField("Device login password", text: $model.devices[model.selectedDevice].password).frame(width: 200, alignment: .leading)
          }
        }
      }
    }
  }
}

struct TabViews: View {
  @ObservedObject var model: DataModel
  
  @State var selectedTab = 0
  
  var body: some View {
    
    TabView(selection: $selectedTab) {
      RelayView(model: model)
        .tabItem {
          Label("Relays", systemImage: "list.bullet")
        }.tag(0)
      CycleView(model: model, on: true)
        .tabItem {
          Label("Cycle ON", systemImage: "forward")
        }.tag(1)
      CycleView(model: model, on: false)
        .tabItem {
          Label("Cycle OFF", systemImage: "backward")
        }.tag(2)
    }
  }
}

struct RelayView: View {
  @ObservedObject var model: DataModel
  
  var body: some View {
    VStack(alignment: .leading) {
      HStack(spacing: 55) {
        HStack(spacing: 20) {
          Text("#")
          Text("Name")
          Text("Locked")
          Text("Disable")
          Text("Cycle")
        }
        HStack(spacing: 20) {
          Text("#")
          Text("Name")
          Text("Locked")
          Text("Disable")
          Text("Cycle")
        }
      }
      HStack(spacing: 50) {
        Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 10) {
          
          ForEach($model.relays) { $relay in
            if relay.number % 2 != 0 {
              GridRow {
                Text("\(relay.number).")
                TextField("name", text: $model.relays[relay.number - 1].name)
                Text(relay.isLocked ? "Y" : "N").foregroundColor(relay.isLocked ? .red : .green)
                Toggle("", isOn: $model.devices[model.selectedDevice].locks[relay.number - 1])
                  .labelsHidden()
                  .disabled(relay.isLocked)
                TextField("delay", value: $model.devices[model.selectedDevice].cycleDelays[relay.number - 1], format: .number)
                  .frame(width: 40)
                  .multilineTextAlignment(.trailing)
              }
            }
          }
        }.frame(width: 250)
        
        Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 10) {
          ForEach($model.relays) { $relay in
            if relay.number % 2 == 0 {
              GridRow {
                Text("\(relay.number).")
                TextField("name", text: $model.relays[relay.number - 1].name)
                Text(relay.isLocked ? "Y" : "N").foregroundColor(relay.isLocked ? .red : .green)
                Toggle("", isOn: $model.devices[model.selectedDevice].locks[relay.number - 1])
                  .labelsHidden()
                  .disabled(relay.isLocked)
                TextField("delay", value: $model.devices[model.selectedDevice].cycleDelays[relay.number - 1], format: .number)
                  .frame(width: 40)
                  .multilineTextAlignment(.trailing)
              }
            }
          }
        }.frame(width: 250)
      }
    }
  }
}

struct CycleView: View {
  @ObservedObject var model: DataModel
  let on: Bool
  
  @State var relayNumbers = [1,2,3,4,5,6,7,8]
  
  var body: some View {
    
    let steps = on ? $model.devices[model.selectedDevice].cycleOnSteps : $model.devices[model.selectedDevice].cycleOffSteps
    
    HStack(spacing: 90) {
      
      Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 10) {
        GridRow {
          Text("#")
          Text("Active")
          Text("Relay")
          Text("ON")
          Text("Delay")
        }
        ForEach(steps, id: \.id) { $step in
          if step.step % 2 != 0 {
            GridRow {
              Text("\(step.step)")
              Toggle("", isOn: $step.active).labelsHidden()
              Picker("", selection: $step.relayNumber) {
                ForEach(relayNumbers, id: \.self) { i in
                  if !model.relays[i - 1].isLocked {
                    Text("\(i)").tag(i)
                  }
                }
              }
              .labelsHidden()
              .frame(width: 50)
              
              Toggle("", isOn: $step.value).labelsHidden()
              TextField("", value: $step.delay, format: .number)
                .frame(width: 40)
                .multilineTextAlignment(.trailing)
            }
          }
        }
      }
      
      Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 10) {
        GridRow {
          Text("#")
          Text("Active")
          Text("Relay")
          Text("ON")
          Text("Delay")
        }
        ForEach(steps, id: \.id) { $step in
          if step.step % 2 == 0 {
            GridRow {
              Text("\(step.step)")
              Toggle("", isOn: $step.active).labelsHidden()
              Picker("", selection: $step.relayNumber) {
                ForEach(relayNumbers, id: \.self) { i in
                  if !model.relays[i - 1].isLocked {
                    Text("\(i)").tag(i)
                  }
                }
              }
              .labelsHidden()
              .frame(width: 50)
              
              Toggle("", isOn: $step.value).labelsHidden()
              TextField("", value: $step.delay, format: .number)
                .frame(width: 40)
                .multilineTextAlignment(.trailing)
            }
          }
        }
      }.font(.system(size: 12).monospaced())
    }
  }
}

struct SettingsView_Previews: PreviewProvider {
  static var previews: some View {
    
    SettingsView(model: DataModel())
      .padding()
  }
}
