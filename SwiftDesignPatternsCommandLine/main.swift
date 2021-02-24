//
//  main.swift
//  SwiftDesignPatternsCommandLine
//
//  Created by 杨俊艺 on 2021/2/21.
//

import Foundation


// 对象模版模式       ObjectTemplate
// 原型模式          Prototype
// 单例模式         Singleton



var data: Int? = nil

var dataIsAvailable: Bool = false


func producer() {
    data = 42
    // 这里指令的顺序无法保证
    dataIsAvailable = true
    
}


func consumer() {
    while !dataIsAvailable {
        usleep(1000)
    }
    print(data)
}


// 这样才是对的即分配到相同的串行队列确保在相同的线程上执行
//func producer() {
//    serialDispatchQueue.async {
//        data = 42
//    }
//}
//
//
//func consumer() {
//    serialDispatchQueue.sync {
//        print(data)
//    }
//}


























