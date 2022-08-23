//
//  String+Random.swift
//  mist-ios
//
//  Created by Adam Monterey on 8/6/22.
//

import Foundation

    
func randomStringOfNumbers(length: Int) -> String {
  let letters = "0123456789"
  return String((0..<length).map{ _ in letters.randomElement()! })
}
    
