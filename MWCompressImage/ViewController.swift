//
//  ViewController.swift
//  MWCompressImage
//
//  Created by MorganWang on 23/05/2022.
//

import Cocoa
import Alamofire

class ViewController: NSViewController {

    // MARK: - properties    
    @IBOutlet weak var filePath: NSTextField! // 文件路径显示
    @IBOutlet weak var chooseFilePathBtn: NSButton! // 选择文件路径按钮
    @IBOutlet weak var checkSamePathBtn: NSButton! // 勾选表示同目录直接替换，否则在原目录下新建 output 文件夹用于存放压缩后的照片
    @IBOutlet weak var indicatorView: NSProgressIndicator! // 开始压缩后进度显示
    @IBOutlet weak var keyTF: NSTextField! // tinyPNG 的 APIKey
    @IBOutlet weak var compressBtn: NSButton! // 压缩按钮
    @IBOutlet var contentTextView: NSTextView! // 压缩进度显示
    
    
    fileprivate var fileUrls: [URL]? // 选择的文件路径
    fileprivate var resultOutput: String = "" // 结果
    fileprivate var isSamePath: Bool = true // 默认是相同路径
    fileprivate var destinationUrl: URL? // 下载文件目录
    fileprivate var totalCompressSize: CLongLong = 0 // 共计压缩掉的大小
    
    let kApiKey: String = "Fd1tMB3NY9QrjCM7wnFCsrPYkwLjG8P4" // 建议自己去申请，https://tinypng.com/developers，每个月免费500张
    let kDefaultOutputStr = """
使用方式：\n
1. 点击选择路径：选择要压缩的文件路径或文件夹路径\n
2. 默认勾选压缩后文件同目录替换，即，压缩后的图片输出目录是当前目录，直接替换原文件；取消勾选则压缩后输出文件会在原目录下 output 文件夹下\n
3. 输入tinypng 获取到的 key，获取地址如下：https://tinypng.com/developers\n
4. 点击开始压缩，开始压缩，下面会输出压缩内容
"""
    
    // MARK: - view life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        setup()
    }

    
    // MARK: - init
    fileprivate func setup() {
        indicatorView.isHidden = true
        
        contentTextView.isEditable = false
        
        contentTextView.string = kDefaultOutputStr
        keyTF.stringValue = kApiKey
    }
    
    // MARK: - utils
    
    
    // MARK: - action
    
    @IBAction func choosePathAction(_ sender: Any) {
        _privateIncatorAnimate(false)
        
        totalCompressSize = 0
        contentTextView.string = kDefaultOutputStr
        resultOutput = ""
        
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true // 支持多选文件
        panel.canChooseDirectories = true // 可以选择目录
        panel.canChooseFiles = true // 可以选择文件
        panel.canCreateDirectories = true
        panel.begin { response in
            if response == .OK {
                self.fileUrls = panel.urls
                self._privateUpdateFilePathLabelDisplay()
            }
        }
    }
    
    @IBAction func checkBtnAction(_ sender: NSButton) {
        print(sender.state)
        isSamePath = (sender.state == .on)
    }
    
    @IBAction func compressAction(_ sender: Any) {
        guard let urls = fileUrls, urls.count > 0 else {
            _privateShowAlert(with: "请选择要压缩的路径")
            return
        }

        let apiKey = keyTF.stringValue
        guard apiKey.count > 0 else {
            _privateShowAlert(with: "请输入 TinyPNG 的 APIKey")
            return
        }
        
        _privateIncatorAnimate(true)
        
        let group = DispatchGroup()
        
        let fileManager = FileManager.default
        for url in urls {
            let urlStr = url.absoluteString
            if urlStr.hasSuffix("/") {
                // "/"结尾说明是目录
                let dirEnumator = fileManager.enumerator(at: url, includingPropertiesForKeys: nil)
                while let subFileUrl = dirEnumator?.nextObject() as? URL {
                    print(subFileUrl)
                    if _privateIsSupportImageType(subFileUrl.pathExtension) {
                        group.enter()
                        _privateCompressImage(with: subFileUrl, apiKey: apiKey) {
                            
                            group.leave()
                        }
                    }
                }
            }
            else if _privateIsSupportImageType(url.pathExtension) {
                print(url)
                group.enter()
                _privateCompressImage(with: url, apiKey: apiKey) {
                    
                    group.leave()
                }
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            self.resultOutput += String(format: "\n 总计：相比之前共压缩掉了%ldKb", self.totalCompressSize/1024)
            self.contentTextView.string = self.resultOutput
            self._privateIncatorAnimate(false)
        }
    }
    
    
    // MARK: - other
    
    /// 加载 view 的展示和隐藏
    fileprivate func _privateIncatorAnimate(_ isShow: Bool) {
        indicatorView.isHidden = !isShow
        if isShow {
            indicatorView.startAnimation(self)
        }
        else {
            indicatorView.stopAnimation(self)
        }
    }
    
    /// 调用 API 压缩图片
    fileprivate func _privateCompressImage(with url: URL, apiKey: String, callback: (() -> Void)?) {
        TinyPNGUploadService.uploadFile(with: url, apiKey: apiKey, responseCallback: { uploadResItem in
            let compressSize = (uploadResItem?.input.size ?? 0) - (uploadResItem?.output.size ?? 0)
            self.totalCompressSize += compressSize
            
            self._privateUpdateContentOutDisplay(with: url, isCompressCompleted: false, item: uploadResItem?.output)
            if let tempUrlStr = uploadResItem?.output.url,
               let tempUrl = URL(string: tempUrlStr) {
                let destinationUrl = self._privateGetDownloadDestinationPath(from: url)
                TinyPNGDownloadService.downloadFile(with: tempUrl,
                                                    to: destinationUrl,
                                                    apiKey: apiKey) {
                    self._privateUpdateContentOutDisplay(with: url, isCompressCompleted: true, item: uploadResItem?.output)
                    callback?()
                }
            }
            else {
                callback?()
            }
        })
    }
    
    /// 更新输出显示
    fileprivate func _privateUpdateContentOutDisplay(with url: URL, isCompressCompleted: Bool, item: UploadResponseOutputItem?) {
        var suffixStr: String = ""
        if let outputItem = item {
            let ratio = 1.0 - outputItem.ratio
            suffixStr = "压缩已完成，压缩了: " + String(format: "%.0f", ratio*100) + "%的大小\n"
            if isCompressCompleted {
                suffixStr = String(format: "写入已完成，最终大小约为:%.ldKb \n", outputItem.size/1024)
            }
        }
        else {
            suffixStr = "压缩已完成\n"
            if isCompressCompleted {
                suffixStr = "写入已完成\n"
            }
        }

        let str = url.absoluteString + suffixStr
        self.resultOutput += str
        self.contentTextView.string = self.resultOutput
    }
    
    /// 获取下载文件保存的目录
    fileprivate func _privateGetDownloadDestinationPath(from url: URL) -> URL {
        if isSamePath {
            // 直接替换原文件
            return url
        }
        else {
            // 在文件目录中新建 output 文件夹，放入 output 下
            let fileName = url.lastPathComponent
            let subFolderPath = String(format: "output/%@", fileName)
            let destinationUrl = URL(fileURLWithPath: subFolderPath, relativeTo: url)
            return destinationUrl
        }
    }
    
    /// 判断是否是支持压缩的图片格式
    fileprivate func _privateIsSupportImageType(_ typeStr: String) -> Bool {
        let supportLists: [String] = [
            "jpeg",
            "JPEG",
            "jpg",
            "JPG",
            "png",
            "PNG",
            "webp",
            "WEBP",
        ]
        
        if supportLists.contains(typeStr) {
            return true
        }
        else {
            return false
        }
    }
    
    /// 更新路径显示 label 的文字
    fileprivate func _privateUpdateFilePathLabelDisplay() {
        guard let fileUrls = fileUrls else {
            // 默认展示
            filePath.stringValue = "要压缩文件路径"
            return
        }

        if fileUrls.count == 1 {
            // 说明选择的是单个文件 || 文件夹
            filePath.stringValue = "已选择：" + (fileUrls.first?.absoluteString ?? "")
        }
        else {
            filePath.stringValue = "已选择多个文件"
        }
    }
    
    /// 弹窗
    fileprivate func _privateShowAlert(with str: String) {
        let alert = NSAlert()
        alert.messageText = str
        alert.addButton(withTitle: "确定")
        alert.beginSheetModal(for: NSApplication.shared.keyWindow!)
    }


}

