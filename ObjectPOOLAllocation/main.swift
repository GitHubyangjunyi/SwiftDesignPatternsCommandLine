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
    private var data = [T]()
    private let arrayQ = DispatchQueue.init(label: "arrayQ")
    private let semaphore: DispatchSemaphore
    private var createdCount: Int = 0
    private let maxItemCount: Int
    private let itemFactory: () -> T
    private let itemAllocator: ([T]) -> Int
    
    init(itemCount: Int, itemFactory: @escaping () -> T, itemAllocator: @escaping ([T]) -> Int) {
        self.maxItemCount = itemCount
        self.itemFactory = itemFactory
        self.itemAllocator = itemAllocator
        semaphore = DispatchSemaphore(value: itemCount)
    }
    
    func getFromPool(maxWaitSeconds: Int = 5) -> T? {
        var result: T?
        
        if semaphore.wait(timeout: DispatchTime.distantFuture) == .success {
            arrayQ.sync {
                if data.count == 0 {
                    result = itemFactory()
                    createdCount += 1
                } else {
                    result = data.remove(at: itemAllocator(data))
                }
            }
        }
        return result
    }
    
    func returnPool(item: T) {
        arrayQ.async { [self] in
            data.append(item)
            semaphore.signal()
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
        pool = Pool<Book>(itemCount: stockLevel, itemFactory: {() in
            stockId += 1
            return BookSaller.buyBook(author: "Dckens, Charles", title: "Hard Times", stockNumber: stockId)
        }, itemAllocator: {(books) in return 0})    // 策略闭包返回数组第一个对象,也就是先进先出策略
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




