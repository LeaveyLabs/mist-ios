//
//  Validate.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/6/22.
//

import Foundation

struct Validate {
    
    //TODO: display notice during auth that they can only use these characters
    static func validateUsername(_ username: String) -> Bool {
        var usernamePermittedCharacters: CharacterSet = [".", "_"]
        usernamePermittedCharacters.formUnion(.alphanumerics)
        let isValidUsername = usernamePermittedCharacters.isSuperset(of: CharacterSet(charactersIn: username)) && username.count > 3
        
        return isValidUsername
    }
    
    static func validateName(_ name: String) -> Bool {
        var usernamePermittedCharacters: CharacterSet = .letters
        let isValidName = usernamePermittedCharacters.isSuperset(of: CharacterSet(charactersIn: name)) && name.count > 0
        return isValidName
    }
    
}
