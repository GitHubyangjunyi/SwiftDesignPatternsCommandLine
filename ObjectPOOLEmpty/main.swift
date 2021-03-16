//
//  main.swift
//  ObjectPOOLEmpty
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
        
        if semaphore.wait(timeout: waitTime) == .success {
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
        return result
    }
    
    func returnPool(item: T) {
        arrayQ.async { [self] in
            let pitem = item as AnyObject as? PoolItem
            // 如果pitem没有实现协议或者实现了协议且可以重用就返回给对象池
            if pitem == nil || pitem!.canReuse {
                data.append(item)
                print("\((item as! Book).stockNumber) 回到图书馆!")
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

// 请求次数增加将会失败
for i in 1...50 {
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


