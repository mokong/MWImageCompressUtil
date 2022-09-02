image compress util mac desktop


# 图片批量压缩mac应用

图片批量压缩，主要用于包大小优化中图片压缩。

## 使用

下载工程，编译运行，选择项目文件夹，（注册TinyPNG的api key，注册免费，默认是我的，每个月有数量限制）点击开始压缩，会自动遍历项目中的所有图片，并压缩替换。

如果不想要替换，取消勾选[压缩后文件同目录替换]按钮即可。

## 背景

3年前有个项目[BatchProssImage](https://github.com/mokong/BatchProcessImage)，使用 Python 写的批量压缩图片的，最新再次使用时，发现忘记了怎么使用，所以就有了把这个Python 实现的工具，做成一个简单的 mac app 的想法。

<!--more-->

## 过程

想法很简单：印象中当时这个工具是使用 tinypng 的 api 压缩的，所以开发一个 mac客户端，调用压缩的接口，导出照片就可以。开始动工。


首先 mac 客户端的 UI 从哪里来？之前有个项目[OtoolAnalyse](https://github.com/mokong/OtoolAnalyse)——分析Mach-O文件中无用的类和方法，是借[LinkMap](https://github.com/huanxsd/LinkMap)UI 来实现的。这里想了想，嗯，还可以用这个方法。打开项目一看，OC 的，还是用 Swift 写一遍吧。

### UI 实现

想一下大致需要哪些功能，
- 选择文件 || 目录
- 选择导出目录
- 开始压缩
- 压缩进度显示
- 噢噢，还有一个，tinypng apikey 输入

再考虑一下，选择导出目录是否必要？之前笔者自己使用其他 APP 选择导出时，打断先有的操作且不说，对于选择困难来说，每次考虑要导出到哪里都是一个问题，要不要新建一个文件夹，还选择同目录会是什么效果等等。

改为 check 按钮，默认同目录直接替换，因为目标的使用场景是，选择项目文件夹，扫描文件夹中的图片，压缩，然后直接替换原文件；取消 check 选中时，则在选中目录下创建 output 文件夹，把压缩后的图片输出到output 中，这样就避免了选择导出目录的麻烦。

所以最终效果图如下：

![UI 效果图](https://raw.githubusercontent.com/mokong/BlogImages/main/img/screenshot-20220524-114121.png)

UI 描述：
1. 要压缩文件路径，用于显示选择路径的路径——如果选择多个文件，则显示已选择多个文件；如果选择单个文件或文件夹，则显示路径；
2. 选择路径按钮，选择文件或者目录；
3. TinyPng 的API Key，用于输入TinyPNG网站获取到的API key，接口调用使用。
4. 压缩后文件路径同目录替换按钮，(这个名字按钮起的有点长[捂脸])，默认选中，选中时压缩后的图片直接替换原图片；取消选中时，压缩后的图片输出到选择目录同级的output文件夹下；
5. indicator，用于开始压缩时表示正在压缩；
6. 开始压缩按钮，获取文件夹下的支持压缩的图片，调用开始压缩的接口压缩，压缩后输出；

### 代码实现

1. 选择路径按钮点击事件逻辑，支持多选，支持选择目录，选择完成后，更新文件路径的显示

``` Swift
    
 fileprivate var fileUrls: [URL]? // 选择的文件路径

 @IBAction func choosePathAction(_ sender: Any) {
     let panel = NSOpenPanel()
     panel.allowsMultipleSelection = true // 支持多选文件
     panel.canChooseDirectories = true // 可以选择目录
     panel.canChooseFiles = true // 可以选择文件
     panel.begin { response in
         if response == .OK {
             self.fileUrls = panel.urls
             self._privateUpdateFilePathLabelDisplay()
         }
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

```

2. 上传逻辑实现

上传逻辑首先需要知道tinypng上传的方式是什么样的，打开[tinypng api reference](https://tinypng.com/developers/reference)，可以看到支持`HTTP`、`RUBY`、`PHP`、`NODE.JS`、`PYTHON`、`JAVA`、`.NET`方式的上传，其中除了`HTTP`外，其他的都是提供已经编译好的库，所以，在这里只能用`HTTP`方式来上传。

先思考一下，之前做的项目的图片上传，都需要哪些字段，然后浏览文档，对比找到这些字段，然后验证。

确认了，上传的域名是`https://api.tinify.com/shrink`；上传需要认证，认证的方式是`HTTP Basic Auth`，格式是获取到的 APIKEY，加上 `api:APIKEY`，再通过base64 Encode 得到一个字符串xxx，再在字符串前拼接`Basic xxx`，最后放到 HTTPHeader 的 `Authorization`中；最后上传需要图片data 数据，放在 body 中。

在动手前，先验证一下，这个接口是不是这样工作的，能不能正常使用，打开 Postman，新建一个接口，接口链接为`https://api.tinify.com/shrink`，`post`格式，在 Headers 中 添加key 为`Authorization`， value 为`Basic Base64EncodeStr(api:YourAPIKey)`，如下：

![Postman 上传验证1](https://raw.githubusercontent.com/mokong/BlogImages/main/img/20220524151304.png)

然后切到 Body，选择 Binary，添加一张图片，点击 Send，可以看到接口返回成功了，如下：

![Postman 上传验证2](https://raw.githubusercontent.com/mokong/BlogImages/main/img/20220524151405.png)

说明上传压缩接口可以正常工作，然后在来到 APP 中实现类似的逻辑：

创建下载类`TinyPNGUploadService`，使用 `Alamofire`上传文件方法。

**注意一：**上传时，一直报错，`Domain=NSPOSIXErrorDomain Code=1 "Operation not permitted"`，排查后发现，需要mac app网络请求需在 Target——>Signing && Capabilities 中，勾选App Sandbox 下的Network 选项中的`Outgoing Connections(Client)`。

**注意二：**不能使用`AF.upload(multipartFormData..`的方法，否则会报错`Status Code: 415`，这里调试了好久。。。


``` Swift

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
            // Fixed-Me:
            responseCallback?(nil) 
        })
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

```

然后在点击开始压缩按钮时，调用封装的这个上传方法。

1. 上传前判断是否选择待压缩对象，
2. 判断是否输入 APIKEY，
3. 展示 indicator
4. 遍历选择的文件路径，如果是路径，则遍历路径下的文件；如果是文件，则直接判断
5. 判断文件是否是支持压缩的格式，tinyPNG 支持`png`、`jpg`、`jpeg`、`webp`格式的图片压缩，其他文件格式则不做处理
6. 如果是支持压缩的文件，则调用压缩方法，压缩成功后，更新进度到最底部的ContentTextView 中
7. 所有图片都压缩后，隐藏 indicator

``` Swift 

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
         self._privateIncatorAnimate(false)
     }
 }

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
            let str = url.absoluteString + "压缩已完成\n"
            self.resultOutput += str
            self.contentTextView.string = self.resultOutput

         callback?()
     })
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

     /// 弹窗
 fileprivate func _privateShowAlert(with str: String) {
     let alert = NSAlert()
     alert.messageText = str
     alert.addButton(withTitle: "确定")
     alert.beginSheetModal(for: NSApplication.shared.keyWindow!)
 }

```

运行后选择一张图片，点击开始压缩，最后效果如下：

![上传压缩演示效果](https://raw.githubusercontent.com/mokong/BlogImages/main/img/20220524162543.png)

嗯哼，已经完成了30%，上传压缩的部分完成了，但是来看下上传后接口返回的数据

``` JSON

{
    "input": {
        "size": 2129441,
        "type": "image/png"
    },
    "output": {
        "size": 185115,
        "type": "image/png",
        "width": 750,
        "height": 1334,
        "ratio": 0.0869,
        "url": "https://api.tinify.com/output/59dt7ar44cvau1tmnhpfhp42f35bdpd7"
    }
}

```

压缩后返回的数据中，input 是之前的图片大小和类型，output 是压缩后的图片数据，包含大小、类型、宽高、压缩比、图片链接。可以看到压缩后返回的是一个图片链接，所以剩下的部分，就是把压缩后的图片下载下来，保存到指定文件夹。

由于要用到返回的数据，所以声明一个 model 类用来解析返回的数据，如下：

``` Swift

import Foundation

struct UploadResponseItem: Codable {
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

```

然后修改上传类`TinyPNGUploadService`中的方法，改为解析成 model 类，回调 model 类，如下：

``` Swift

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

```

3. 下载逻辑的实现

然后来看下下载逻辑的实现，首先还是去[tinypng api reference](https://tinypng.com/developers/reference) 中，看到`Example download request`中，示例中下载还写了`Authorization`（虽然实际上不需要，因为直接复制 URL，到隐私浏览器，可以直接打开），但是保险起见，还是按照示例的，在 header 中添加`Authorization`。

由于都需要 `Authorization`，所以把生成`Authorization`的方法封装，放到 String的 Extension 中，又因为都需要上传和下载都需要调用这个方法，所以把 Extension 单独抽成一个类`String_Extensions`，如下：

``` Swift

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

```

然后把上传类中，生成 authStr的地方修改成如下：

``` Swift
        
        let authStr = apiKey.tinyPNGAuthFormatStr()

```

再来创建下载类，`TinyPNGDownloadService`，下载方法需要三个参数，要下载图片的 URL，下载后保存的地址，以及 tiny png 的 apikey，

1. 注意下载后保存地址如果存在同文件则移除。
2. 注意需要设置HTTPHeader 中`Content-Type`为`application/json`，如果不设置，最后下载会错误，提示 contentType 不对。
3. 注意下载返回不能用 responseString 打印，因为 string 是 pngdata，打印一长串看不懂的字符。

最终代码如下：

``` Swift

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

```

然后来考虑调用下载的时机；需要在上传完成后可以获取到要下载的链接，输出显示已完成前，应该先下载到本地。

下载文件目录，根据check 按钮是否选中，如果选中则是替换，直接返回当前文件 url 即可；如果未选中，则按照同目录添加 output 目录，保存在 output 下。

代码如下：

``` Swift
    fileprivate var isSamePath: Bool = true // 默认是相同路径

    /// check 按钮的选中与否
    @IBAction func checkBtnAction(_ sender: NSButton) {
        print(sender.state)
        isSamePath = (sender.state == .on)
    }


/// 调用 API 压缩图片
    fileprivate func _privateCompressImage(with url: URL, apiKey: String, callback: (() -> Void)?) {
        TinyPNGUploadService.uploadFile(with: url, apiKey: apiKey, responseCallback: { uploadResItem in
            if let tempUrlStr = uploadResItem?.output.url,
               let tempUrl = URL(string: tempUrlStr) {
                let destinationUrl = self._privateGetDownloadDestinationPath(from: url)
                TinyPNGDownloadService.downloadFile(with: tempUrl,
                                                    to: destinationUrl,
                                                    apiKey: apiKey) {
                    self._privateUpdateContentOutDisplay(with: url)
                    callback?()
                }
            }
            else {
                self._privateUpdateContentOutDisplay(with: url)
                callback?()
            }
        })
    }
    
    /// 更新输出显示
    fileprivate func _privateUpdateContentOutDisplay(with url: URL) {
        let str = url.absoluteString + "压缩已完成\n"
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

```

运行调试，首先是同文件替换的情况，发现下载成功，但是保存报错`downloadedFileMoveFailed(error: Error Domain=NSCocoaErrorDomain Code=513 "“IMG_2049.PNG” couldn’t be removed because you don’t have permission to access it."`，没有权限写入本地文件，同样还是需要修改Target——>Signing && Capabilities 中，修改App Sandbox 下的 File Access 选项中的`User Selected File`，权限改为`Read/Write`，如下：

![打开读写权限示意图](https://raw.githubusercontent.com/mokong/BlogImages/main/img/20220524172239.png)

再次尝试，发现同文件替换可以成功了。

再来尝试，保存到 output目录的情况。发现又报错`downloadedFileMoveFailed(error: Error Domain=NSCocoaErrorDomain Code=513 "You don’t have permission to save the file “output” in the folder “CompressTestFolder”."`，同样是没有权限，这个卡住了好久，一直不能创建文件夹，查了很久资料发现这个答案(Cannot Create New Directory in MacOS app)[https://stackoverflow.com/questions/50817375/cannot-create-new-directory-in-macos-app]，Mac app 在 Sandbox模式下，不能自动创建目录，给出的解决办法有下面这些：
> Depending on your use case you can
- disable the sandbox mode——禁用安全模式
- let the user pick a folder by opening an "Open" dialog (then you can write to this)——让用户自己指定写入目录，即提供选择路径按钮，选择文件或者目录；
- enable read/write in some other protected user folder (like Downloads, etc.) or——换个目录，比如 Downloads 文件夹，开启读写权限
- create the TestDir directly in your home directory without using any soft linked folder——直接在主目录中创建文件夹

按照给出的解决办法，采用最简单的，删除了 Sandbox 模式，Target——>Signing && Capabilities 中，删除App Sandbox模块，再次调试，即可创建文件夹成功。

优化，上面步骤完成后，整体的效果已经可以实现了，但是对于使用者来说，不太直观。一方面：中间包含了两步，上传和下载，用户可能更偏向于每一步都有反馈；另一方面，对于最终压缩的效果，没有一个直观的感受，只看到了某一步完成，但是压缩的程度没有显现出来。已经知道了上传成功后会返回原始图片和压缩后图片的大小和压缩比，所以可以进一步优化一下。

- 上传压缩后，显示压缩已完成，压缩了xx%的大小
- 下载保存到文件夹后，显示写入已完成，最终大小约为:xxKb 
- 保存每一步的原始图片大小，和压缩后大小的差值，最后所有都压缩完成后，总体显示相比之前压缩掉了xxKb

``` Swift
    fileprivate var totalCompressSize: CLongLong = 0 // 共计压缩掉的大小

    @IBAction func compressAction(_ sender: Any) {
        
        ...

        group.notify(queue: DispatchQueue.main) {
            self.resultOutput += String(format: "\n 总计：相比之前共压缩掉了%ldKb", self.totalCompressSize/1024)
            self.contentTextView.string = self.resultOutput
            self._privateIncatorAnimate(false)
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

```

完整效果如下：

![PageCallback.gif](https://s2.loli.net/2022/05/24/ZVcg9yz32bDCeqw.gif)


完整代码已放到Github：[MWImageCompressUtil](https://github.com/mokong/MWImageCompressUtil)，链接：https://github.com/mokong/MWImageCompressUtil


## 参考

- [tinypng api reference](https://tinypng.com/developers/reference)
- (关于Error Domain=NSPOSIXErrorDomain Code=1 "Operation not permitted")[https://www.cnblogs.com/xiaoqiangink/p/12197761.html]
- (Cannot Create New Directory in MacOS app)[https://stackoverflow.com/questions/50817375/cannot-create-new-directory-in-macos-app]

