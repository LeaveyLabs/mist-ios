//
//  ProfilePic.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/06/11.
//

import Foundation

// A wrapper class for UIImage

struct ProfilePicWrapper: Codable {
    
    var image: UIImage
    var blurredImage: UIImage
    
    init(image: UIImage, withCompresssion: Bool) {
        if withCompresssion {
            print("Bit size before vs after image compression;")
            print(image.jpegData(compressionQuality: 1)!.count)
            self.image = UIImage(data: image.compress(toMaxKBs: 1000))!
            self.blurredImage = self.image.blur()
            print(self.image.jpegData(compressionQuality: 1)!.count)
        } else {
            self.image = image
            self.blurredImage = image.blur()
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case data
        case scale
        case blurredData
        case blurredScale
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.decode(Data.self, forKey: .data)
        let scale = try container.decode(CGFloat.self, forKey: .scale)
        let blurredData = try container.decode(Data.self, forKey: .blurredData)
        let blurredScale = try container.decode(CGFloat.self, forKey: .blurredScale)
        image = UIImage(data: data, scale: scale)!
        blurredImage = UIImage(data: blurredData, scale: blurredScale)!
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(image.pngData(), forKey: .data)
        try container.encode(image.scale, forKey: .scale)
        try container.encode(blurredImage.pngData(), forKey: .blurredData)
        try container.encode(blurredImage.scale, forKey: .blurredScale)
    }
}
