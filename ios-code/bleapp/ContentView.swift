


import SwiftUI
import CoreBluetooth

struct ContentView: View {

    @StateObject var service = BluetoothService()
    @State private var isLoading = true
    @State private var selectedPeripheral: CBPeripheral?

    var body: some View {
       
        VStack {
            
            Text("Capacitance Measure Tool")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 10)
            
            Text(service.peripheralStatus.rawValue)
                .font(.title)
            
           
            
            Text("Value : \(service.capacitanceValue)")
                .font(.largeTitle)
                .fontWeight(.heavy)
                .padding(.top, 16)
        
            // Add space before the list
                       Divider()
                           .padding(.vertical, 20)

                        // List of peripherals with Connect buttons
            List(service.discoveredPeripherals.filter { ($0.name ?? "Unnamed Device") != "Unnamed Device" }, id: \.identifier) { peripheral in
                HStack {
                    VStack(alignment: .leading) {
                        Text(peripheral.name ?? "Unnamed Device")
                            .font(.subheadline)
                        Text("UUID: \(peripheral.identifier.uuidString.prefix(8))…")
                            .font(.caption)
                    }

                    Spacer()

                    Button("Connect") {
                        selectedPeripheral = peripheral
                        service.connectToPeripheral(peripheral)
                    }
                    .padding(6)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                }
            }

                        .refreshable {
                            service.rescanPeripherals()
                        }
                        .listStyle(.plain)
        }
        //.padding()
        if let selected = selectedPeripheral,
           service.peripheralStatus == .connected || service.peripheralStatus == .connecting {
            
            Button("Disconnect") {
                service.disconnectPeripheral(selected)
            }
            .padding()
            .background(Color.red)
            .foregroundStyle(.white)
            .cornerRadius(6)
            .padding(.bottom, 50)
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
