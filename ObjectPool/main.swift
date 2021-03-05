//
//  main.swift
//  ObjectPool
//
//  Created by 杨俊艺 on 2021/3/4.
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


class Pool<T> {
    private var data = [T]()
    
    private let semaphore: DispatchSemaphore
    private let arrayQ = DispatchQueue.init(label: "arrayQ")
    
    init(items: [T]) {
        data.reserveCapacity(data.count)
        for item in items {
            data.append(item)
        }
        semaphore = DispatchSemaphore.init(value: items.count)
    }
    
    func getFromPool() -> T? {
        var result: T?
        semaphore.wait()
        if data.count > 0 {
            arrayQ.sync {
                result = data.remove(at: 0)
            }
        }
        return result
    }
    
    func returnPool(item: T) {
        arrayQ.async { [self] in
            data.append(item)
            print("\((item as! Book).stockNumber) 回到图书馆!")    //为了测试还的是哪本书,这里不该引入Book类型信息,导致耦合
            semaphore.signal()
        }
    }
}


class Library {
    private var books: [Book]
    private let pool: Pool<Book>
    
    private init(stockLevel: Int) {
        books = [Book]()
        for count in 1...stockLevel {
            books.append(Book(author: "Dickens, Charles", title: "Happy Times", stockNumber: count))
        }
        pool = Pool<Book>(items: books)
    }
    
    private class var singleton: Library {
        struct SingletonWrapper {
            static let singleton = Library(stockLevel: 2)
        }
        return SingletonWrapper.singleton
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
        for book in singleton.books {
            print("Book# \(book.stockNumber)")
            print("被借出次数 \(book.checkoutCount)")
            if book.reader != nil {
                print("当前借出者 \(String(describing: book.reader))")
            } else {
                print("本书未借出")
            }
        }
    }
    
}


var queue = DispatchQueue.init(label: "workQ", attributes: .concurrent)
var group = DispatchGroup.init()


for i in 1...20 {
    queue.async(group: group, qos: .default, flags: []) {
        let book = Library.checkoutBook(reader: "读者#\(i)")
        if book != nil {
            print("****\(String(describing: book?.reader)) 借出 \(String(describing: book?.stockNumber))")
            Thread.sleep(forTimeInterval: Double(arc4random() % 2))
            Library.returnBook(book: book!)
        }
        
    }
}

group.wait()
print("--------------------")
Library.printReport()



