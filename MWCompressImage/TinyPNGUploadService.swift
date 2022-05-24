//
//  TinyPNGUploadService.swift
//  MWCompressImage
//
//  Created by Horizon on 24/05/2022.
//

import Foundation
import AppKit
import Alamofire

let kTinyPNGCompressHost: String = "https://api.tinify.com/shrink"

public struct TinyPNGUploadService {
    /// 上传图片
    /// - Parameter url: 待上传图片的 url
    static func uploadFile(with url: URL, apiKey: String, responseCallback: ((UploadResponseItem?) -> Void)?) {
        let needBase64Str = "api:" + apiKey
        let authStr = "Basic " + needBase64Str.toBase64()
        let header: HTTPHeaders = [
            "Authorization": authStr,
        ]
        
        AF.upload(url, to: kTinyPNGCompressHost, method: .post, headers: header)
        .responseString(completionHandler: { response in
            print(response)
        })
//        .responseDecodable(of: UploadResponseItem.self) { response in
//            switch response.result {
//            case .success(let item):
//                responseCallback?(item)
//            case .failure(let error):
//                print(error)
//                responseCallback?(nil)
//            }
//        }
    }
    
}

extension String {
    func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    func toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }

}
