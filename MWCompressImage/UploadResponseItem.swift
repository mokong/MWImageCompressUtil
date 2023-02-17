//
//  UploadResponseItem.swift
//  MWCompressImage
//
//  Created by MorganWang on 24/05/2022.
//

import Foundation

struct UploadResponseItem: Codable {
//    {"input":{"size":2129441,"type":"image/png"},"output":{"size":185115,"type":"image/png","width":750,"height":1334,"ratio":0.0869,"url":"https://api.tinify.com/output/59dt7ar44cvau1tmnhpfhp42f35bdpd7"}}

    var input: UploadReponseInputItem
    var output: UploadResponseOutputItem
}

struct UploadReponseInputItem: Codable {
    var size: CLongLong
    var type: String
}

struct UploadResponseOutputItem: Codable {
    var size: CLongLong
    var type: String
    var width: CLongLong
    var height: CLongLong
    var ratio: Double
    var url: String
}
