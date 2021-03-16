//
//  main.swift
//  ObjectPOOLElastic
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
        print("BookSeller.buyBook() Book#\(stockNumber)")
        return Book(author: author, title: title, stockNumber: stockNumber)
    }
}

class LibraryNetwork {
    class func borrowBook(author: String, title: String, stockNumber: Int) -> Book {
        print("LibraryNetWork.borrowBook for \(stockNumber)")
        return Book(author: author, title: title, stockNumber: stockNumber)
    }
    
    class func returnBook(book: Book) {
        print("LibraryNetWork.returnBook for \(book.stockNumber)")
    }
    
}

@objc protocol PoolItem {
    var canReuse: Bool { get }
}

class Pool<T: AnyObject> {
    private let semaphore: DispatchSemaphore
    private let arrayQ = DispatchQueue.init(label: "arrayQ")
    
    private let itemFactory: () -> T
    private let peakFactory: () -> T
    private let peakReaper: (T) -> Void // 用来销毁多余对象
    
    private var createdCount = 0
    private let normalCount: Int
    private let peakCount: Int
    private let returnCount: Int
    private let waitTime: Int
    private var data = [T]()
    
    init(itemCount: Int, peakCount: Int, returnCount: Int, waitTime: Int = 2, itemFactory: @escaping () -> T, peakFactory: @escaping () -> T, peakReaper: @escaping (T) -> Void) {
        self.normalCount = itemCount
        self.peakCount = peakCount
        self.waitTime = waitTime
        self.returnCount = returnCount
        self.itemFactory = itemFactory
        self.peakFactory = peakFactory
        self.peakReaper = peakReaper
        semaphore = DispatchSemaphore.init(value: itemCount)
    }
    
    func getFromPool(maxWaitSeconds: Int = 5) -> T? {
        var result: T?
        
        let expiryTime = DispatchTime.now() + .seconds(waitTime)
        
        if semaphore.wait(timeout: expiryTime) == .success {
            arrayQ.sync {
                if data.count == 0 {
                    result = itemFactory()
                    createdCount += 1
                } else {
                    result = data.remove(at: 0)
                }
            }
        } else { // 实在等不及了就去借书过来
            arrayQ.sync {
                result = peakFactory()
                createdCount += 1
            }
        }
        return result
    }
    
    func returnPool(item: T) {
        arrayQ.async { [self] in
            // 如果需求下降到50%且创建次数大于平时设定的值就开始销毁对象
            if data.count > returnCount && createdCount > normalCount {
                peakReaper(item)
                createdCount -= 1
            } else {
                data.append(item)
                semaphore.signal()
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
        pool = Pool<Book>(itemCount: stockLevel, peakCount: stockLevel * 2, returnCount: stockLevel / 2, itemFactory: { () -> Book in
            stockId += 1
            return BookSaller.buyBook(author: "Dickens Charles", title: "Happy Times", stockNumber: stockId)
        }, peakFactory: { () -> Book in
            stockId += 1
            return LibraryNetwork.borrowBook(author: "Dckens, Charles", title: "Hard Times", stockNumber: stockId)
        }, peakReaper: { (Book) in
            LibraryNetwork.returnBook(book: Book)
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




