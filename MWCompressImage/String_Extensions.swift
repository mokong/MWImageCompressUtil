//
//  String_Extensions.swift
//  MWCompressImage
//
//  Created by Horizon on 24/05/2022.
//

import Foundation

public extension String {
    func tinyPNGAuthFormatStr() -> String {
        let needBase64Str = "api:" + self
        let authStr = "Basic " + needBase64Str.toBase64()
        return authStr
    }
    
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
