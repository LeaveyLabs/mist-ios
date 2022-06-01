//
//  NewPostContext.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/05/30.
//

import Foundation

struct NewPostContext {
    static var annotation: PostAnnotation?
    static var timestamp: Double?
    static var title: String?
    static var body: String?
    
    static func clear() {
        annotation = nil
        timestamp = nil
        title = nil
        body = nil
    }
}
