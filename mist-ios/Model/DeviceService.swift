//
//  DeviceService.swift
//  mist-ios
//
//  Created by Adam Monterey on 9/3/22.
//

import Foundation

class DeviceService: NSObject {
    
    static var shared = DeviceService()
    private let LOCAL_FILE_APPENDING_PATH = "device.json"
    private var localFileLocation: URL!
    private var device: Device!
    
    //MARK: - Initializer
    
    //private initializer because there will only ever be one instance of UserService, the singleton
    private override init() {
        super.init()
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        localFileLocation = documentsDirectory.appendingPathComponent(LOCAL_FILE_APPENDING_PATH)
        if FileManager.default.fileExists(atPath: localFileLocation.path) {
            loadFromFilesystem()
        } else {
            device = Device()
            Task { await saveToFilesystem() }
        }
    }
    
    //MARK: - Getters
    
    func hasBeenShowedGuidelines() -> Bool { return device?.hasBeenShownGuidelines ?? true } //if they load in the app and start it up too quickly, the app was crashing here for invalida access bc still nil...
    func hasBeenOfferedNotificationsAfterPost() -> Bool { return device.hasBeenOfferedNotificationsAfterPost }
    func hasBeenOfferedNotificationsAfterDM() -> Bool { return device.hasBeenOfferedNotificationsAfterDM }
    func hasBeenRequestedARating() -> Bool { return device.hasBeenRequestedARating }

    //MARK: - Doers
    
    func showGuidelinesForFirstTime() {
        device.hasBeenShownGuidelines = true
        Task { await saveToFilesystem() }
    }
    func showedNotificationRequestAfterPost() {
        device.hasBeenOfferedNotificationsAfterPost = true
        Task { await saveToFilesystem() }
    }
    func showedNotificationRequestAfterDM() {
        device.hasBeenOfferedNotificationsAfterDM = true
        Task { await saveToFilesystem() }
    }
    func showRatingRequest() {
        device.hasBeenRequestedARating = true
        Task { await saveToFilesystem() }
    }
    
    //MARK: - Filesystem
    
    func saveToFilesystem() async {
        do {
            let encoder = JSONEncoder()
            let data: Data = try encoder.encode(device)
            let jsonString = String(data: data, encoding: .utf8)!
            try jsonString.write(to: self.localFileLocation, atomically: true, encoding: .utf8)
        } catch {
            print("COULD NOT SAVE: \(error)")
        }
    }

    func loadFromFilesystem() {
        do {
            let data = try Data(contentsOf: self.localFileLocation)
            device = try JSONDecoder().decode(Device.self, from: data)
        } catch {
            print("COULD NOT LOAD: \(error)")
        }
    }
    
    func eraseData() {
        do {
            try FileManager.default.removeItem(at: self.localFileLocation)
        } catch {
            print("\(error)")
        }
    }
}
