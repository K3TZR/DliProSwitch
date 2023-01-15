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

  @State var queryFailed = false
  
  var body: some View {
      
    VStack {
      Text(model.title).font(.title)
      Divider()
      Spacer()
      Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 10) {
        
        ForEach(Array(model.relays.enumerated()), id: \.offset) { offset, relay in
          GridRow {
            Text(relay.name).font(.title2)
            Image(systemName: relay.locked ? "lock.slash" : model.locks[offset] ? "lock" : "power")
              .font(.system(size: 28, weight: .bold))
              .foregroundColor(relay.status ? .green : .red)
              .onTapGesture {
                if model.locks[offset] { NSSound.beep() } else { model.toggleStatus(offset) }
              }.disabled( model.inProcess || relay.locked )
              .contextMenu {
                Button(model.locks[offset] ? "Unlock" : "Lock") { model.locks[offset].toggle() }
              }.disabled( model.inProcess || relay.locked )
          }
        }
      }
      Spacer()
      Divider()
      HStack {
        Button(action: { model.allSet(false) }){ Text("All OFF") }
        Spacer()
        Text("Cycle")
        Button("ON") { model.cycle(on: true) }
        Button("OFF") { model.cycle(on: false) }
      }.disabled(model.inProcess)
    }
    .frame(width: 240, height:450)
    
    .onAppear {
      Task {
        do {
          try await model.synchronize()
        } catch {
          queryFailed = true
        }
      }
    }
    
    .sheet(isPresented: $queryFailed) {
      FailureView(model: model)
    }
        
//    .task {
//      while true {
//        try! await model.synchronize()
//        try! await Task.sleep(for: .seconds(model.pollingInterval))
//      }
//    }
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
      Text("Relay Query FAILED").font(.title)
      Divider()
      Spacer()
      Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 10) {
        GridRow() {
          Text("Ip Address")
          Text(model.ipAddress)
        }
      }.font(.title2)
      Divider()
      Spacer()
      Text("Update your settings").font(.title2)
      Text("then press Refresh")
      Button("OK") { dismiss() }.keyboardShortcut(.defaultAction)
    }
    .frame(width: 300, height: 200)
    .padding()
  }
}
