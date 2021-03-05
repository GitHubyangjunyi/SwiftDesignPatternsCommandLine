//
//  main.swift
//  ObjectPOOLLazy
//
//  Created by 杨俊艺 on 2021/3/5.
//

import Foundation

class Book {
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
    
}

class BookSaller {
    class func buyBook(author: String, title: String, stockNumber: Int) -> Book {
        return Book(author: author, title: title, stockNumber: stockNumber)
    }
}

class Pool<T> {
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
    
    func getFromPool() -> T? {
        var result: T?
        semaphore.wait()
        arrayQ.sync {
            // 如果对象池中没有对象且还可以创建新对象就创建一个新对象直接返回
            if data.count == 0 && itemCount < maxItemCount {
                result = itemFactory()
                itemCount += 1
            } else {
                result = data.remove(at: 0)
            }
        }
        return result
    }
    
    func returnPool(item: T) {
        arrayQ.async { [self] in
            data.append(item)
            print("\((item as! Book).stockNumber) 回到图书馆!")
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
    
    static let singleton = Library(stockLevel: 200)
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


for i in 1...10 {
    queue.async(group: group, qos: .default, flags: []) {
        let book = Library.checkoutBook(reader: "读者#\(i)")
        if book != nil {
            print("****\(String(describing: book?.reader)) 借出 \(String(describing: book?.stockNumber))书本")
            Thread.sleep(forTimeInterval: Double(arc4random() % 2))
            Library.returnBook(book: book!)
        }
    }
}

group.wait()
print("--------------------")
Library.printReport()





