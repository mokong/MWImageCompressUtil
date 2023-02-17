//
//  TinyPNGUploadService.swift
//  MWCompressImage
//
//  Created by MorganWang on 24/05/2022.
//

import Foundation
import AppKit
import Alamofire

let kTinyPNGCompressHost: String = "https://api.tinify.com/shrink"

public struct TinyPNGUploadService {
    /// 上传图片
    /// - Parameter url: 待上传图片的 url
    static func uploadFile(with url: URL, apiKey: String, responseCallback: ((UploadResponseItem?) -> Void)?) {
        let authStr = apiKey.tinyPNGAuthFormatStr()
        let header: HTTPHeaders = [
            "Authorization": authStr,
        ]
        
        AF.upload(url, to: kTinyPNGCompressHost, method: .post, headers: header)
//        .responseString(completionHandler: { response in
//            print(response)
//            responseCallback?(nil)
//        })
        .responseDecodable(of: UploadResponseItem.self) { response in
            switch response.result {
            case .success(let item):
                responseCallback?(item)
            case .failure(let error):
                print(error)
                responseCallback?(nil)
            }
        }
    }
    
}
