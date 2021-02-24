//
//  Logger.swift
//  Singleton
//
//  Created by 杨俊艺 on 2021/2/23.
//

import Foundation

final class Logger {
    private var data = [String]()
    
    // 单例对象需要自己确保操作安全
    private let arrayQueue = DispatchQueue.init(label: "arrayQueue") // 默认生成串行队列
    
    fileprivate init() {}
    
    func log(msg: String) {
        arrayQueue.sync {
            data.append(msg)
        }
    }
    
    func printLog() {
        for msg in data {
            print("Log: \(msg)")
        }
    }
    
}


let globalLogger = Logger()


// 在Swift中实现
// 1.使用类型常量
class Singleton {
    static let sharedInstance = Singleton()
}

// 2.使用全局变量
let sharedInstance = Singleton()
func getSingleton() -> Singleton {
    return sharedInstance
}




