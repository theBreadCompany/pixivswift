//
//  PixivDownloader+Metadata.swift
//  
//
//  Created by theBreadCompany on 15.07.22.
//
// TODO: Use a custom metadata section to store the full illustration metadata in the image

import Foundation
#if os(macOS)
import ImageIO
#else
#endif
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
    public func meta_update(metadata: PixivIllustration, illust_url: URL, illust_data: Data? = nil){
#if os(macOS)
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
        ] as [String: Any], forKey: "{TIFF}")
        
        properties.updateValue([
            "metadata": try! JSONEncoder().encode(metadata)
        ] as [String: Any], forKey: "{Pixiv}")
        
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
#endif
    }
    
    /**
     Extract metadata from file
     
     - Parameter file: The URL to the source file
     - Parameter identifyByFileName: try to identify the image by the file name
     - returns: The extracted image identity or `nil` if the extraction failed
     
     identifyByFileName is kind of unsafe because the name can be changed and lost easily and may be considered unsafe.
     If it is allowed anyway and identification fails, all the other identification methods are tried as well.
     */
    public func metaExtract(from file: URL, identifyByFileName: Bool = false) -> PixivIllustration? {
#if os(macOS)
        guard FileManager.default.fileExists(atPath: file.path), let source = CGImageSourceCreateWithURL(file as CFURL, nil) else { return nil }
#endif
        // The "unsafe" way: Check if the filename has the correct format to may be a pixiv illustration
        if identifyByFileName {
            let components = file.lastPathComponent.components(separatedBy: "_")
            if components.count == 2, let id = Int(components.first!), String(id).count >= 5 && String(id).count <= 9 {
                return try? self.illustration(illust_id: id)
            }
        }
        
#if os(macOS)
        guard let properties = CGImageSourceCopyProperties(source, nil) as? Dictionary<String, Any>,
              let iptcData = properties["{IPTC}"] as? [String: Any] else { return nil }
        
        // If there is a correct URL you can basically reconstruct all the metadata and verify that this image is from pixiv
        guard let url = iptcData["Source"] as? URL, url.host == "pixiv.net" else { return nil }
        
        if let pixivData = properties["{Pixiv}"] as? [String:Any], let illustData = pixivData["metadata"] as? Data {
            return try? JSONDecoder().decode(PixivIllustration.self, from: illustData)
        } else {
            return try? self.illustration(illust_id: Int(url.lastPathComponent.components(separatedBy: "_").first ?? "") ?? 0)
        }
#else
        
#endif
    }
}
