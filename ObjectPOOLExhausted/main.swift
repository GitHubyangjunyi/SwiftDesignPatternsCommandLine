//
//  main.swift
//  ObjectPOOLExhausted
//
//  Created by 杨俊艺 on 2021/3/8.
//

import Foundation

@objc class Book: NSObject, PoolItem {
    
    let author: String
    let title: String
    let stockNumber: Int
    var reader: String?
    var checkoutCount = 0
    
    // 标题 作者 序列号 读者 借出次数
    init(author: String, title: String, stockNumber: Int) {
        self.author = author
        self.title = title
        self.stockNumber = stockNumber
    }
    
    var canReuse: Bool {
        get {
            let reusable = checkoutCount < 5
            if !reusable {
                print("废弃书本: \(stockNumber)")
            }
            return reusable
        }
    }
    
}

class BookSaller {
    class func buyBook(author: String, title: String, stockNumber: Int) -> Book {
        return Book(author: author, title: title, stockNumber: stockNumber)
    }
}

@objc protocol PoolItem {
    var canReuse: Bool { get }
}

class Pool<T: AnyObject> {
    private let semaphore: DispatchSemaphore
    private let arrayQ = DispatchQueue.init(label: "arrayQ")
    
    private var itemCount = 0
    private let maxItemCount: Int
    private var ejectedItems = 0
    private var poolExhausted = false
    private let itemFactory: () -> T
    private var data = [T]()
    
    init(maxItemCount: Int, itemFactory: @escaping () -> T) {
        self.maxItemCount = maxItemCount
        self.itemFactory = itemFactory
        semaphore = DispatchSemaphore.init(value: maxItemCount)
    }
    
    func getFromPool(maxWaitSeconds: Int = 5) -> T? {
        var result: T?
        let waitTime = (maxWaitSeconds == -1) ? DispatchTime.distantFuture : DispatchTime.now() + .seconds(maxWaitSeconds)
        // 双检查一 对象池枯竭发起请求直接返回
        if !poolExhausted {
            
            if semaphore.wait(timeout: waitTime) == .success {
                // 双检查二 配合flushQueue清退等待的组件
                if !poolExhausted {
                    arrayQ.sync {
                        
                        // 如果对象池中没有对象且还可以创建新对象就创建一个新对象直接返回
                        if data.count == 0 && itemCount < maxItemCount {
                            result = itemFactory()
                            itemCount += 1
                        } else {
                            result = data.remove(at: 0)
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
        return result
    }
    
    func returnPool(item: T) {
        arrayQ.async { [self] in
            // 有实现PoolItem协议
            if let pitem = item as AnyObject as? PoolItem {
                if pitem.canReuse {
                    data.append(item)
                    semaphore.signal()
                } else {
                    ejectedItems += 1
                    if ejectedItems == maxItemCount {
                        poolExhausted = true
                        // 对象池枯竭清退所有请求组件
                        flushQueue()
                    }
                }
            } else { // 没有实现PoolItem协议直接放回去
                data.append(item)
            }
        }
    }
    
    func flushQueue() {
        let dQueue = DispatchQueue.init(label: "drainer", attributes: .concurrent)
        var backlogCleared = false
        
        //GCD信号量可以让线程以先进先出的顺序执行,在前面等待的请求通过之前,GCD信号量不会让这个Block执行,但是下面的Block将会一直操作信号量,这样就可以清退之前那些在对象池枯竭之前尚未完成而一直等待的请求
        dQueue.async { [self] in
            semaphore.wait()
            backlogCleared = true
        }
        
        dQueue.async { [self] in
            while !backlogCleared {
                semaphore.signal()
            }
        }
    }
    
    func processPoolItems(callBack: ([T]) -> Void) {
        arrayQ.sync(flags: .barrier) {
            callBack(data)
        }
    }
}

class Library {
    
    static let singleton = Library(stockLevel: 5)
    private let pool: Pool<Book>
    
    private init(stockLevel: Int) {
        var stockId = 0
        pool = Pool<Book>(maxItemCount: stockLevel, itemFactory: { () -> Book in
            stockId += 1
            return BookSaller.buyBook(author: "Dickens Charles", title: "Happy Times", stockNumber: stockId)
        })
    }
    
    
    class func checkoutBook(reader: String) -> Book? {
        let book = singleton.pool.getFromPool()
        book?.reader = reader
        book?.checkoutCount += 1
        return book
    }
    
    class func returnBook(book: Book) {
        book.reader = nil
        singleton.pool.returnPool(item: book)
    }
    
    class func printReport() {
        singleton.pool.processPoolItems { (books) in
            for book in books {
                print("Book# \(book.stockNumber)")
                print("被借出次数 \(book.checkoutCount)")
                if book.reader != nil {
                    print("当前借出者 \(String(describing: book.reader))")
                } else {
                    print("本书未借出")
                }
            }
            print("有\(books.count)本书在池中")
        }
        
    }
    
}


var queue = DispatchQueue.init(label: "workQ", attributes: .concurrent)
var group = DispatchGroup.init()


for i in 1...35 {
    queue.async(group: group, qos: .default, flags: []) {
        let book = Library.checkoutBook(reader: "读者#\(i)")
        if book != nil {
            print("****\(String(describing: book?.reader)) 借出 \(String(describing: book?.stockNumber))书本")
            Thread.sleep(forTimeInterval: Double(arc4random() % 2))
            Library.returnBook(book: book!)
        } else {
            // 队列是并行队列且print函数不是线程安全的函数所以使用内存屏障
            queue.async(group: group, qos: .default, flags: [.barrier], execute: {() in
                print("Request \(i) failed")
                })
        }
    }
}

group.wait()
print("--------------------")
queue.async(group: nil, qos: .default, flags: [.barrier], execute: {() in
    print("All blocks complete")
    Library.printReport()
})
// 防止有时候Library.printReport()没有执行
Library.printReport()


