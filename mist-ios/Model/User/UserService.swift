//
//  UserService.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import Foundation
import FirebaseAnalytics

class UserService: NSObject {
    
    //MARK: - Properties
    
    static var singleton = UserService()
    
    private var frontendCompleteUser: FrontendCompleteUser?
    private var authedUser: FrontendCompleteUser { //a wrapper for the real underlying frontendCompleteUser. if for some unknown reason, frontendCompleteUser is nil, instead of the app crashing with a force unwrap, we kick them to the home screen and log them out
        get {
            guard let authedUser = frontendCompleteUser else {
                kickUserToHomeScreenAndLogOut()
                return FrontendCompleteUser.nilUser
            }
            return authedUser
        }
        set {
            frontendCompleteUser = newValue
        }
    }

    //add a local device storage object
    private let LOCAL_FILE_APPENDING_PATH = "myaccount.json"
    private var localFileLocation: URL!
    
    private var SLEEP_INTERVAL:UInt32 = 30
    
    //MARK: - Initializer
    
    //private initializer because there will only ever be one instance of UserService, the singleton
    private override init() {
        super.init()
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        localFileLocation = documentsDirectory.appendingPathComponent(LOCAL_FILE_APPENDING_PATH)
        
        if FileManager.default.fileExists(atPath: localFileLocation.path) {
            self.loadUserFromFilesystem()
            setupFirebaseAnalyticsProperties()
        }
        
//        Task {
//            while let latitude = frontendCompleteUser?.latitude,
//                  let longitude = frontendCompleteUser?.longitude,
//                  let id = frontendCompleteUser?.id {
//                let _ = try await UserAPI.patchLatitudeLongitude(latitude: latitude, longitude: longitude, id: id)
//                let _ = try await UserAPI.fetchNearbyUsers()
//                Task.sleep(SLEEP_INTERVAL)
//            }
//        }
    }
    
    //MARK: - Getters
    
    // Called on startup so that the singleton is created and isLoggedIn is properly initialized
    func isLoggedIn() -> Bool {
        return frontendCompleteUser != nil
    }
    
    //User
    func getUser() -> FrontendCompleteUser { return authedUser }
    func getUserAsReadOnlyUser() -> ReadOnlyUser {
        return ReadOnlyUser(id: authedUser.id,
                            username: authedUser.username,
                            first_name: authedUser.first_name,
                            last_name: authedUser.last_name,
                            picture: authedUser.picture)
    }
    func getUserAsFrontendReadOnlyUser() -> FrontendReadOnlyUser {
        return FrontendReadOnlyUser(readOnlyUser: getUserAsReadOnlyUser(),
                                    profilePic: authedUser.profilePicWrapper.image,
                                    blurredPic: authedUser.profilePicWrapper.blurredImage)
    }
    
    //Properties
    func getId() -> Int { return authedUser.id }
    func getUsername() -> String { return authedUser.username }
    func getFirstName() -> String { return authedUser.first_name }
    func getLastName() -> String { return authedUser.last_name }
    func getFirstLastName() -> String { return authedUser.first_name + " " + authedUser.last_name }
    func getEmail() -> String { return authedUser.email }
    func getPhoneNumber() -> String? { return authedUser.phone_number }
    func getPhoneNumberPretty() -> String? { return authedUser.phone_number?.asNationalPhoneNumber }
    func getProfilePic() -> UIImage { return authedUser.profilePicWrapper.image }
    func getBlurredPic() -> UIImage { return authedUser.profilePicWrapper.blurredImage }
    func isVerified() -> Bool { return false }
    
    //MARK: - Login and create user
    
    // No need to return new user from createAccount() bc new user is globally updated within this function
    func createUser(username: String,
                    firstName: String,
                    lastName: String,
                    profilePic: UIImage,
                    email: String,
                    phoneNumber: String,
                    dob: String) async throws {
        let newProfilePicWrapper = ProfilePicWrapper(image: profilePic, withCompresssion: true)
        let compressedProfilePic = newProfilePicWrapper.image
        let token = try await AuthAPI.createUser(username: username,
                                            first_name: firstName,
                                            last_name: lastName,
                                            picture: compressedProfilePic,
                                            email: email,
                                            phone_number: phoneNumber,
                                            dob: dob)
        setGlobalAuthToken(token: token)
        let completeUser = try await UserAPI.fetchAuthedUserByToken(token: token)
        
        Task { try await waitAndRegisterDeviceToken(id: completeUser.id) }
        frontendCompleteUser = FrontendCompleteUser(completeUser: completeUser,
                                                    profilePic: newProfilePicWrapper,
                                                    token: token)
        setupFirebaseAnalyticsProperties()
        Task { await self.saveUserToFilesystem() }
    }
    
//    func logIn(json: Data) async throws {
//        let token = try await AuthAPI.fetchAuthToken(json: json)
//        setGlobalAuthToken(token: token)
//        let completeUser = try await UserAPI.fetchAuthedUserByToken(token: token)
//        Task { try await waitAndRegisterDeviceToken(id: completeUser.id) }
//        let profilePicUIImage = try await UserAPI.UIImageFromURLString(url: completeUser.picture)
//        frontendCompleteUser = FrontendCompleteUser(completeUser: completeUser,
//                                                    profilePic: ProfilePicWrapper(image: profilePicUIImage,
//                                                                                  withCompresssion: false),
//                                                    token: token)
//        setupFirebaseAnalyticsProperties()
//        Task { await self.saveUserToFilesystem() }
//    }
    
    func logInWith(authToken token: String) async throws {
        setGlobalAuthToken(token: token)
        let completeUser = try await UserAPI.fetchAuthedUserByToken(token: getGlobalAuthToken())
        Task { try await waitAndRegisterDeviceToken(id: completeUser.id) }
        let profilePicUIImage = try await UserAPI.UIImageFromURLString(url: completeUser.picture)
        frontendCompleteUser = FrontendCompleteUser(completeUser: completeUser,
                                                    profilePic: ProfilePicWrapper(image: profilePicUIImage,
                                                                                  withCompresssion: false),
                                                    token: token)
        setupFirebaseAnalyticsProperties()
        Task { await self.saveUserToFilesystem() }
    }
    
    //MARK: - Update user
    
    // No need to return new profilePic bc it is updated globally
    func updateUsername(to newUsername: String) async throws {
        guard let frontendCompleteUser = frontendCompleteUser else { return }
        
        let updatedCompleteUser = try await UserAPI.patchUsername(username: newUsername, id: frontendCompleteUser.id)
        self.authedUser.username = updatedCompleteUser.username
        Task {
            await self.saveUserToFilesystem()
            await UsersService.singleton.updateCachedUser(updatedUser: self.getUserAsFrontendReadOnlyUser())
        }
    }
    
    func updateFirstName(to newFirstName: String) async throws {
        guard let frontendCompleteUser = frontendCompleteUser else { return }
        
        let updatedCompleteUser = try await UserAPI.patchFirstName(firstName: newFirstName, id: frontendCompleteUser.id)
        self.authedUser.first_name = updatedCompleteUser.first_name
        Task {
            await self.saveUserToFilesystem()
            await UsersService.singleton.updateCachedUser(updatedUser: self.getUserAsFrontendReadOnlyUser())
        }
    }
    
    func updateLastName(to newLastName: String) async throws {
        guard let frontendCompleteUser = frontendCompleteUser else { return }
        
        let updatedCompleteUser = try await UserAPI.patchLastName(lastName: newLastName, id: frontendCompleteUser.id)
        self.authedUser.last_name = updatedCompleteUser.last_name
        Task {
            await self.saveUserToFilesystem()
            await UsersService.singleton.updateCachedUser(updatedUser: self.getUserAsFrontendReadOnlyUser())
        }
    }
    
    // No need to return new profilePic bc it is updated globally
    func updateProfilePic(to newProfilePic: UIImage) async throws {
        guard let frontendCompleteUser = frontendCompleteUser else { return }
        
        let newProfilePicWrapper = ProfilePicWrapper(image: newProfilePic, withCompresssion: true)
        let compressedNewProfilePic = newProfilePicWrapper.image
        let updatedCompleteUser = try await UserAPI.patchProfilePic(image: compressedNewProfilePic,
                                                                    id: frontendCompleteUser.id,
                                                                    username: frontendCompleteUser.username)
        self.authedUser.profilePicWrapper = newProfilePicWrapper
        self.authedUser.picture = updatedCompleteUser.picture
        
        Task {
            await self.saveUserToFilesystem()
            await UsersService.singleton.updateCachedUser(updatedUser: self.getUserAsFrontendReadOnlyUser())
        }
    }
    
//    func updatePassword(to newPassword: String) async throws {
//        guard let frontendCompleteUser = frontendCompleteUser else { return }
//
//        let _ = try await UserAPI.patchPassword(password: newPassword, id: frontendCompleteUser.id)
//        //no need for a local update, since we don't actually save the password locally
//    }
    
    //MARK: - Logout and delete user
    
    func logOut()  {
        eraseUserFromFilesystem()
        frontendCompleteUser = nil
        setGlobalAuthToken(token: "")
    }
    
    func kickUserToHomeScreenAndLogOut() {
        logOut()
        DispatchQueue.main.async {
            transitionToAuth()
        }
    }
    
    func deleteMyAccount() async throws {
        guard let frontendCompleteUser = frontendCompleteUser else { return }
        try await UserAPI.deleteUser(user_id: frontendCompleteUser.id)
        logOut()
    }
    
    //MARK: - Firebase
    
    func setupFirebaseAnalyticsProperties() {
        //if we decide to use firebase ad support framework in the future, gender, age, and interest will automatically be set
        guard let age = frontendCompleteUser?.age else { return }
        var ageBracket = ""
        if age < 25 {
            ageBracket = "18-24"
        } else if age < 35 {
            ageBracket = "25-35"
        } else if age < 45 {
            ageBracket = "35-45"
        } else if age < 55 {
            ageBracket = "45-55"
        } else if age < 65 {
            ageBracket = "55-65"
        } else {
            ageBracket = "65+"
        }
        Analytics.setUserProperty(authedUser.sex, forName: "sex")
        Analytics.setUserProperty(ageBracket, forName: "age")
    }
    
    //MARK: - Filesystem
    
    func saveUserToFilesystem() async {
        do {
            guard var frontendCompleteUser = frontendCompleteUser else { return }
            frontendCompleteUser.token = getGlobalAuthToken() //this shouldn't be necessary, but to be safe
            let encoder = JSONEncoder()
            let data: Data = try encoder.encode(frontendCompleteUser)
            let jsonString = String(data: data, encoding: .utf8)!
            try jsonString.write(to: self.localFileLocation, atomically: true, encoding: .utf8)
        } catch {
            print("COULD NOT SAVE: \(error)")
        }
    }
    
    func loadUserFromFilesystem() {
        do {
            let data = try Data(contentsOf: self.localFileLocation)
            frontendCompleteUser = try JSONDecoder().decode(FrontendCompleteUser.self, from: data)
            guard let frontendCompleteUser = frontendCompleteUser else { return }
            setGlobalAuthToken(token: frontendCompleteUser.token) //this shouldn't be necessary, but to be safe
            Task { try await waitAndRegisterDeviceToken(id: frontendCompleteUser.id) }
        } catch {
            print("COULD NOT LOAD: \(error)")
        }
    }
    
    func eraseUserFromFilesystem() {
        do {
            setGlobalAuthToken(token: "")
            try FileManager.default.removeItem(at: self.localFileLocation)
        } catch {
            print("\(error)")
        }
    }
    
    // MARK: - Device Notifications
    
    func waitAndRegisterDeviceToken(id:Int) async throws {
        while AUTHTOKEN == "" || DEVICETOKEN == "" {
            try await Task.sleep(nanoseconds: NSEC_PER_SEC * UInt64(SLEEP_INTERVAL))
        }
        try await DeviceAPI.registerCurrentDeviceWithUser(user: id)
    }
}
