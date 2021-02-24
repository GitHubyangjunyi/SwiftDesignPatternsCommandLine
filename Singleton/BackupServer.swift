//
//  BackupServer.swift
//  Singleton
//
//  Created by 杨俊艺 on 2021/2/23.
//

import Foundation

class DataItem {
    
    enum ItemType: String {
        case Email = "Email Address"
        case Photo = "Telephone Number"
        case Card = "Credit Card Number"
    }
    
    var type: ItemType
    var data: String
    
    init(type: ItemType, data: String) {
        self.type = type
        self.data = data
    }

}

// 3.书本出版时swift还不支持类存储属性导致了这种实现单例的方法
// 更多关于Objective-C于Swift的单例模式如何实现可以查看WWDC2016-Thread Sanitizer和静态分析
final class BackupServer {
    var name: String
    private var data = [DataItem]()
    
    // 单例对象需要自己确保操作安全
    private let arrayQueue = DispatchQueue.init(label: "arrayQueue") // 默认生成串行队列
    
    private init(name: String) {
        self.name = name
        globalLogger.log(msg: "创建 \(name) 服务器")
    }
    
    func backup(item: DataItem) {
        arrayQueue.sync {
            sleep(1)
            data.append(item)
            globalLogger.log(msg: "\(name) 备份了一个\(item.type.rawValue)类型的日志")
        }
    }
    
    func getData() -> [DataItem] {
        return data
    }
    
    class var mainSever: BackupServer {
        struct SingletonWrapper {
            static let singleton = BackupServer(name: "MainServer")
        }
        return SingletonWrapper.singleton
    }
    
}


