//
//  main.swift
//  Singleton
//
//  Created by 杨俊艺 on 2021/2/23.
//

import Foundation

var server = BackupServer.mainSever

server.backup(item: DataItem(type: .Email, data: "aaa@qq.com"))
server.backup(item: DataItem(type: .Photo, data: "1234"))

globalLogger.log(msg: "备份了两个到\(server.name)")


var otherServer = BackupServer.mainSever

otherServer.backup(item: DataItem(type: .Email, data: "bbb@qq.com"))

globalLogger.log(msg: "备份了一个到\(otherServer.name)")


globalLogger.printLog()

print(otherServer === server)



// 读代码的顺序
// 读代码的顺序
// 读代码的顺序


// 创建一个并发队列
let queue = DispatchQueue.init(label: "workQueue", attributes: .concurrent)
// 将多个任务组织在一起创建成组方便所有的任务执行完成后收到通知
let group = DispatchGroup()

// 异步调用单例多次数
for count in 0...100 {
    queue.async(group: group, execute: DispatchWorkItem.init(block: {
        BackupServer.mainSever.backup(item: DataItem(type: .Email, data: "123123"))
    }))
}

// 阻塞当前线程直到所有任务执行完成
group.wait()

print(server.getData().count)


