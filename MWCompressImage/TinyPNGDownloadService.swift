//
//  TinyPNGDownloadService.swift
//  MWCompressImage
//
//  Created by MorganWang on 24/05/2022.
//

import Foundation
import AppKit
import Alamofire

public struct TinyPNGDownloadService {
    
    /// 下载图片
    /// - Parameters:
    ///   - url: 要下载的图片链接
    ///   - destinationURL: 下载后图片的保存位置
    ///   - apiKey: tinypng 的 APIKey
    ///   - responseCallback: 回调结果
    static func downloadFile(with url: URL, to destinationURL: URL, apiKey: String, responseCallback: (() -> Void)?) {
        let authStr = apiKey.tinyPNGAuthFormatStr()
        let header: HTTPHeaders = [
            "Authorization": authStr,
            "Content-type": "application/json"
        ]
        
        let destination: DownloadRequest.Destination = { _, _ in
         return (destinationURL, [.createIntermediateDirectories, .removePreviousFile])
        }

        AF.download(url, method: .post, headers: header, to: destination)
            .response { response in
                switch response.result {
                case .success(_):
                    responseCallback?()
                case .failure(let error):
                    print(error)
                    responseCallback?()
                }
            }
    }
}
