////
////  BluetoothService.swift
////  bleapp
////
////  Created by Michael Rosol on 6/21/25.
////

import Foundation
import CoreBluetooth

enum ConnectionStatus: String {
    case connected
    case disconnected
    case scanning
    case connecting
    case error
}

let dataService: CBUUID = CBUUID(string: "4998E78C-5B56-4D31-BAA0-B46EDDC6E573")
let capacitanceCharacteristic: CBUUID = CBUUID(string: "861a4d03-44e2-4877-8557-671e08abb546")

class BluetoothService: NSObject, ObservableObject {

    private var centralManager: CBCentralManager!
    @Published var discoveredPeripherals: [CBPeripheral] = [] // used to actually create a list of connectable peripherals

    var capacitanceSensorPeripheral: CBPeripheral?
    @Published var peripheralStatus: ConnectionStatus = .disconnected
    @Published var capacitanceValue: UInt16 = 0

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func scanForPeripherals() {
        peripheralStatus = .scanning
        centralManager.scanForPeripherals(withServices: nil)
    }
    
    func connectToPeripheral(_ peripheral: CBPeripheral) {
        capacitanceSensorPeripheral = peripheral
        peripheralStatus = .connecting
        centralManager.connect(peripheral)
    }
    
    func disconnectPeripheral(_ peripheral: CBPeripheral) {
        if (peripheralStatus == .connected || peripheralStatus == .connecting) {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    func rescanPeripherals() {
        discoveredPeripherals.removeAll()
        centralManager?.stopScan()
        centralManager?.scanForPeripherals(withServices: nil)
    }


}

extension BluetoothService: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("CB Powered On")
            scanForPeripherals()
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {

        // this prevents duplicate devices
        if !discoveredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
                discoveredPeripherals.append(peripheral)
            }
        
        
//        if peripheral.name == "Temperature Beacon" {
//            print("Discovered \(peripheral.name ?? "no name")")
//            capacitanceSensorPeripheral = peripheral
//            centralManager.connect(capacitanceSensorPeripheral!)
//            peripheralStatus = .connecting
//        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheralStatus = .connected

        peripheral.delegate = self
        peripheral.discoverServices([dataService])
        centralManager.stopScan()
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        peripheralStatus = .disconnected
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        peripheralStatus = .error
        print(error?.localizedDescription ?? "no error")
    }

}

extension BluetoothService: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services ?? [] {
            if service.uuid == dataService {
                print("found service for \(dataService)")
                peripheral.discoverCharacteristics([capacitanceCharacteristic], for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics ?? [] {
            peripheral.setNotifyValue(true, for: characteristic)
            print("found characteristic, waiting on values.")
        }
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
                print("Failed to enable notify:", error)
                return
            }
            print("Notification state for \(characteristic.uuid): \(characteristic.isNotifying)")
    }
    
    
    // there is likely a notify/read setting that needs to be fixed before values can be updated

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == capacitanceCharacteristic {
            guard let data = characteristic.value else {
                print("No data received for \(characteristic.uuid.uuidString)")
                return
            }

//            let sensorData: Int = data.withUnsafeBytes { $0.pointee }
            let sensorData: UInt16 = data.withUnsafeBytes {
                $0.load(as: UInt16.self)
            }

            
            
            capacitanceValue = sensorData
        }
    }

}
