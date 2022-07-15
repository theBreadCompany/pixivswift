//
//  PixivDownloader+Metadata.swift
//  
//
//  Created by Fabio Mauersberger on 15.07.22.
//

import Foundation
import ImageIO
import pixivswift

#if canImport(UIKit)
let kUTTypePNG = "public.png" as CFString
let kUTTypeGIF = "com.compuserve.gif" as CFString
let kUTTypeJPEG = "public.jpeg" as CFString
#endif

// MARK: Metadata handling
extension PixivDownloader {
    
    /**
     Update the metadata of an image
     
     - Parameter metadata: PixivIllustration object containing metadata that should be aplied to the image
     - Parameter illust_path: path to the image
     - Parameter illust_data: Data object containing image data that should be update (illust_path is nescessary anyway as this function also writes the new data)
     */
    open func meta_update(metadata: PixivIllustration, illust_url: URL, illust_data: Data? = nil){
        let file_url: URL = illust_url
        let image: CGImageSource = illust_data != nil
        ? CGImageSourceCreateWithData(illust_data! as CFData, nil)!
        : CGImageSourceCreateWithURL(file_url as CFURL, nil)!
        
        var properties = CGImageSourceCopyPropertiesAtIndex(image, 0, nil) as? Dictionary<String, Any> ?? [:]
        
        let translations = metadata.tags.map({ $0.translatedName != nil ? $0.translatedName! : $0.name })
        
        properties.updateValue(properties["{IPTC}"] ?? [:], forKey: "{IPTC}")
        
        properties.updateValue([
            "Keywords": translations,
            "ObjectName": metadata.title,
            "ObjectType": metadata.type == .illust ? "illustration" : metadata.type.rawValue,
            "Caption/Abstract": metadata.caption,
            "Source": metadata.illustrationURLs.first!.original.deletingLastPathComponent().appendingPathComponent(illust_url.lastPathComponent)
        ] as [String: Any], forKey: "{IPTC}")
        
        properties.updateValue([
            "Artist": metadata.user.name,
            "DateTime": metadata.creationDate
        ] as [String:Any], forKey: "{TIFF}")
        
        var img_type: CFString
        switch metadata.illustrationURLs.first!.original.pathExtension {
        case "png":
            img_type = kUTTypePNG
        case "jpg":
            img_type = kUTTypeJPEG
        case "gif":
            img_type = kUTTypeGIF
            //try JSONSerialization.data(withJSONObject: JSONSerialization.jsonObject(with: Data(properties.description.utf8), options: []), options: .prettyPrinted).write(to: illust_url.appendingPathExtension("txt"))
        default:
            fatalError("unexpected image type")
        }
        let new_image = CGImageDestinationCreateWithURL(file_url as CFURL, img_type, CGImageSourceGetCount(image), nil)
        CGImageDestinationAddImageFromSource(new_image!, image, 0, properties as CFDictionary)
        CGImageDestinationFinalize(new_image!)
    }
    
    
}
