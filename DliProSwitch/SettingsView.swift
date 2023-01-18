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
        Picker("Device", selection: $model.deviceIndex) {
          ForEach(Array(model.devices.enumerated()), id: \.offset) { offset, device in
            Text(device.name ).tag(offset)
          }
        }.frame(width: 300)
        Spacer()
        Button("Delete") { model.deviceDelete()}
        Button("New") { model.deviceAdd("New", "", "", "", "") }
      }
      if model.deviceIndex != -1 {
        DeviceView(model: model)
        Divider().background(Color(.blue)).hidden()
        Spacer()
        CycleView(model: model)
      }
    }
    .onAppear {
      if model.deviceIndex == -1 { model.deviceAdd("New", "", "", "", "") }
    }
    .frame(width: 600)
    .padding()
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
            TextField("", text: $model.devices[model.deviceIndex].name)
          }
          GridRow {
            Text("Title")
            TextField("", text: $model.devices[model.deviceIndex].title)
          }
          GridRow {
            Text("User")
            TextField("", text: $model.devices[model.deviceIndex].user)
          }
        }

        Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 10) {
          GridRow {
            Text("IP Address")
            TextField("", text: $model.devices[model.deviceIndex].ipAddress)
          }
          GridRow {
            Text("Password")
            TextField("", text: $model.devices[model.deviceIndex].password).frame(width: 200, alignment: .leading)
          }
        }
      }
      Divider().background(Color(.blue))
      HStack(spacing: 80) {
        Text("Relay Names")
        Toggle("Show empty Relay names", isOn: $model.devices[model.deviceIndex].showEmptyNames)
      }
      HStack(spacing: 100) {

        Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 10) {
          GridRow {
            Text("1.")
            TextField("name", text: $model.relays[0].name)
            Toggle("Lock", isOn: $model.devices[model.deviceIndex].locks[0])
          }
          GridRow {
            Text("3.")
            TextField("name", text: $model.relays[2].name)
            Toggle("Lock", isOn: $model.devices[model.deviceIndex].locks[2])
          }
          GridRow {
            Text("5.")
            TextField("name", text: $model.relays[4].name)
            Toggle("Lock", isOn: $model.devices[model.deviceIndex].locks[4])
          }
          GridRow {
            Text("7.")
            TextField("name", text: $model.relays[6].name)
            Toggle("Lock", isOn: $model.devices[model.deviceIndex].locks[6])
          }
        }.frame(width: 200)

        Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 10) {
          GridRow {
            Text("2.")
            TextField("name", text: $model.relays[1].name)
            Toggle("Lock", isOn: $model.devices[model.deviceIndex].locks[1])
          }
          GridRow {
            Text("4.")
            TextField("name", text: $model.relays[3].name)
            Toggle("Lock", isOn: $model.devices[model.deviceIndex].locks[3])
          }
          GridRow {
            Text("6.")
            TextField("name", text: $model.relays[5].name)
            Toggle("Lock", isOn: $model.devices[model.deviceIndex].locks[5])
          }
          GridRow {
            Text("8.")
            TextField("name", text: $model.relays[7].name)
            Toggle("Lock", isOn: $model.devices[model.deviceIndex].locks[7])
          }
        }.frame(width: 200)
      }
    }
  }
}

struct CycleView: View {
  @ObservedObject var model: DataModel
  
  @State var index = [1,2,3,4,5,6,7,8]
  
  var body: some View {
    
    VStack {
      HStack(spacing: 60) {
        VStack(alignment: .leading, spacing: 5) {
          Text("Cycle ON")
          HStack(spacing: 15) {
            Text("Enabled")
            Text("Index")
            Text("Value")
            Text("Delay")
          }
          ForEach($model.devices[model.deviceIndex].cycleOnList) { step in
            HStack(spacing: 30) {
              Group {
                Toggle("", isOn: step.enable).labelsHidden()
                Picker("", selection: step.index) {
                  ForEach(index, id: \.self) { i in
                    Text("\(i)").tag(i)
                  }
                }
                .labelsHidden()
                .frame(width: 50)
                
                Toggle("", isOn: step.value).labelsHidden()
                TextField("", value: step.delay, format: .number)
                  .frame(width: 40)
                  .multilineTextAlignment(.trailing)
              }
            }
          }
        }
        
        VStack(alignment: .leading, spacing: 5) {
          Text("Cycle OFF")
          HStack(spacing: 15) {
            Text("Enabled")
            Text("Index")
            Text("Value")
            Text("Delay")
          }
          ForEach($model.devices[model.deviceIndex].cycleOffList) { step in
            HStack(spacing: 30) {
              Group {
                Toggle("", isOn: step.enable).labelsHidden()
                Picker("", selection: step.index) {
                  ForEach(index, id: \.self) { i in
                    Text("\(i)").tag(i)
                  }
                }
                .labelsHidden()
                .frame(width: 50)
                
                Toggle("", isOn: step.value).labelsHidden()
                TextField("", value: step.delay, format: .number)
                  .frame(width: 40)
                  .multilineTextAlignment(.trailing)
              }
            }
          }
        }
      }.font(.system(size: 12).monospaced())
      Button("Save") { model.deviceSave()}
    }
  }
}

struct SettingsView_Previews: PreviewProvider {
  static var previews: some View {
    
    SettingsView(model: DataModel())
      .padding()
  }
}
