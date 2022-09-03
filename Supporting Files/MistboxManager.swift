//
//  MistboxCountdownManager.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/29/22.
//

import Foundation

class MistboxManager: NSObject {
    
    static var shared = MistboxManager()
    private let LOCAL_FILE_APPENDING_PATH = "mistbox.json"
    private var localFileLocation: URL!
    
    private var mistboxes = [Mistbox]()
    
    private var NEXT_MISTBOX_RELEASE_DATE: Date! //for coutndown
    private var CURRENT_MISTBOX_RELEASE_DATE: Date! //for displaying the current date at the top, and for determining which mistbox to dsiplay
    private var LAST_MISTBOX_OPEN_DATE: Date? = nil //for checking if user has opened current mistbox
    
    private let MISTBOX_RELEASE_HOUR = 21
    private var tenAMToday: Date {
        return Calendar.current.date(bySettingHour: MISTBOX_RELEASE_HOUR, minute: 0, second: 0, of: Date())!
    }
    private var tenAMTomorrow: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: tenAMToday)!
    }

    var currentMistboxDateFormatted: String? {
        guard let date = CURRENT_MISTBOX_RELEASE_DATE else { return nil }
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.dateFormat = "EEEE, MMMM d"
        return dateFormatter.string(from: date).lowercased() + daySuffix(from: date)
    }
    
    var hasUserActivatedMistbox: Bool {
        return !mistboxes.isEmpty
    }
    
    var hasUnopenedMistbox: Bool {
        return LAST_MISTBOX_OPEN_DATE ?? Date.distantFuture < CURRENT_MISTBOX_RELEASE_DATE
    }
    
    var timeUntilNextMistbox: ElapsedTime {
        return NEXT_MISTBOX_RELEASE_DATE.timeIntervalSince1970.getElapsedTime(since: Date().timeIntervalSince1970)
    }
    
    var percentUntilNextMistbox: Float {
        let secondsIn24Hours = 86400.0
        return 1 - Float(NEXT_MISTBOX_RELEASE_DATE.timeIntervalSinceNow / secondsIn24Hours)
    }
    
    //MARK: - Initializer
    
    //private initializer because there will only ever be one instance of UserService, the singleton
    private override init() {
        super.init()
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        localFileLocation = documentsDirectory.appendingPathComponent(LOCAL_FILE_APPENDING_PATH)
        if FileManager.default.fileExists(atPath: localFileLocation.path) {
            loadFromFilesystem()
        }
        updateMistboxReleaseDates()
    }
    
    //MARK: - Fetchers
    
    func fetchMistboxes() async throws {
        mistboxes = try await PostAPI.fetchMistboxes()
    }
    
    //MARK: - Public API
    
    func openMistbox() {
        LAST_MISTBOX_OPEN_DATE = Date()
        Task { await self.saveToFilesystem() }
    }
    
    func getMostRecentMistboxPosts() -> [Post] {
        updateMistboxReleaseDates()
        return mistboxes.first { mistbox in
            Calendar.current.component(.day, from: Date(timeIntervalSince1970: mistbox.creation_time)) == Calendar.current.component(.day, from: CURRENT_MISTBOX_RELEASE_DATE)
        }?.posts ?? []
    }
    
    func updateMistboxReleaseDates() {
        let hour = Calendar.current.component(.hour, from: Date())
        NEXT_MISTBOX_RELEASE_DATE = hour < MISTBOX_RELEASE_HOUR ? tenAMToday : tenAMTomorrow
        CURRENT_MISTBOX_RELEASE_DATE = NEXT_MISTBOX_RELEASE_DATE.dayBefore
    }
    
    //MARK: - Filesystem
    
    func saveToFilesystem() async {
        do {
            let encoder = JSONEncoder()
            let data: Data = try encoder.encode(LAST_MISTBOX_OPEN_DATE)
            let jsonString = String(data: data, encoding: .utf8)!
            try jsonString.write(to: self.localFileLocation, atomically: true, encoding: .utf8)
        } catch {
            print("COULD NOT SAVE: \(error)")
        }
    }

    func loadFromFilesystem() {
        do {
            let data = try Data(contentsOf: self.localFileLocation)
            LAST_MISTBOX_OPEN_DATE = try JSONDecoder().decode(Date.self, from: data)
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
