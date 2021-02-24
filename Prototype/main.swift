//
//  main.swift
//  Prototype
//
//  Created by 杨俊艺 on 2021/2/21.
//

import Foundation

// 原型模式
class Sum {
    
    var firstValue: Int
    var secondValue: Int
    var resultsCache: [[Int]]
    
    var Result: Int {
        get {
            return firstValue < resultsCache.count && secondValue < resultsCache[firstValue].count ? resultsCache[firstValue][secondValue] : firstValue + secondValue
        }
    }
    
    init(first: Int, second: Int) {
        firstValue = first
        secondValue = second
        resultsCache = [[Int]](repeating: [Int](repeating: 0, count: 1000), count: 1000)
        for i in 0..<1000 {
            for j in 0..<1000 {
                resultsCache[i][j] = i + j
            }
        }
    }
    
}

print(NSDate())

var cal1 = Sum(first: 9, second: 5)
var cal2 = Sum(first: 45, second: 32)

print(cal1.Result)
print(cal2.Result)

print(NSDate())

// 👆的例子不精确测量就要花掉一分钟且占用内存很大(10000 * 10000的情况下)
// 未使用原型模式之前Sum类的初始化需要依赖于初始化器具
// 如果进行了👇这种改动就又要修改之前的初始化形式
// 这里使用一个新的类进行类比类中添加了一个参数的情况
class SumCustomCacheSize {
    
    var firstValue: Int
    var secondValue: Int
    var resultsCache: [[Int]]
    
    var Result: Int {
        get {
            return firstValue < resultsCache.count && secondValue < resultsCache[firstValue].count ? resultsCache[firstValue][secondValue] : firstValue + secondValue
        }
    }
    
    init(first: Int, second: Int, catchSize: Int) {
        resultsCache = [[Int]](repeating: [Int](repeating: 0, count: catchSize), count: catchSize)
        for i in 0..<catchSize {
            for j in 0..<catchSize {
                resultsCache[i][j] = i + j
            }
        }
        firstValue = first
        secondValue = second
    }
}


var cal3 = SumCustomCacheSize(first: 9, second: 5, catchSize: 100)
var cal4 = SumCustomCacheSize(first: 45, second: 32, catchSize: 100)

print(cal3.Result)
print(cal4.Result)

print(NSDate())

// 到这里可能就发现了设计问题，但是也可以不使用原型模式进行解决，模式并非是解决问题的唯一方案
// 可以定义一个便捷初始化器使其调用经过修改的指定初始化器将变化限制在类内部


// 提醒事项
class AppointmentC: NSObject, NSCopying {
    
    var name: String
    var day: String
    var place: String
    
    init(name: String, day: String, place: String) {
        self.name = name
        self.day = day
        self.place = place
    }
    
    func printDetails(label: String) {
        print("\(label) with \(name) on \(day) at \(place)")
    }
    
    // MARK: --NSCopying克隆协议
    func copy(with zone: NSZone? = nil) -> Any {
        return AppointmentC(name: self.name, day: self.day, place: self.place)
    }
    
}

// ⚠️必须使用copy方法而不是=进行直接赋值
var beerMeeting = AppointmentC(name: "啤酒", day: "2222-02-22", place: "Home")
var studyMeeting = beerMeeting.copy() as! AppointmentC
studyMeeting.name = "读书"

beerMeeting.printDetails(label: "")
studyMeeting.printDetails(label: "")


// 关于深复制还是浅复制
class Location {
    var name: String
    var address: String
    
    init(name: String, address: String) {
        self.name = name
        self.address = address
    }
    
}

class AppointmentCC: NSObject, NSCopying {
    
    var name: String
    var day: String
    var place: Location
    
    init(name: String, day: String, place: Location) {
        self.name = name
        self.day = day
        self.place = place
    }
    
    func printDetails(label: String) {
        print("\(label) with \(name) on \(day) at \(place.name) \(place.address)")
    }
    
    // MARK: --NSCopying克隆协议
    func copy(with zone: NSZone? = nil) -> Any {
        return AppointmentCC(name: self.name, day: self.day, place: self.place)
    }
    
}

print("----浅复制----")
var beer = AppointmentCC(name: "啤酒", day: "2222-02-22", place: Location(name: "Home", address: "China"))
var study = beer.copy() as! AppointmentCC
study.name = "读书"
// ⚠️不能使用整体替换
//study.place = Location(name: "oooo", address: "America")
study.place.name = "xxxx"
study.place.address = "America"

beer.printDetails(label: "")
study.printDetails(label: "")


print("----深复制----")
class LocationCopying: NSObject, NSCopying {
    
    var name: String
    var address: String
    
    init(name: String, address: String) {
        self.name = name
        self.address = address
    }
    
    // MARK: --NSCopying克隆协议
    func copy(with zone: NSZone? = nil) -> Any {
        return LocationCopying(name: self.name, address: self.address)
    }
}

class AppointmentCCC: NSObject, NSCopying {
    
    var name: String
    var day: String
    var place: LocationCopying
    
    init(name: String, day: String, place: LocationCopying) {
        self.name = name
        self.day = day
        self.place = place
    }
    
    func printDetails(label: String) {
        print("\(label) with \(name) on \(day) at \(place.name) \(place.address)")
    }
    
    // MARK: --NSCopying克隆协议
    func copy(with zone: NSZone? = nil) -> Any {
        return AppointmentCCC(name: self.name, day: self.day, place: self.place.copy() as! LocationCopying)
    }
    
}


var beerC = AppointmentCCC(name: "啤酒", day: "2222-02-22", place: LocationCopying(name: "Home", address: "China"))
var studyC = beerC.copy() as! AppointmentCCC
studyC.name = "读书"
studyC.place.name = "xxxx"
studyC.place.address = "America"

beerC.printDetails(label: "")
studyC.printDetails(label: "")




print("----实现对象数组的深复制----")
class Person: NSObject, NSCopying {
    
    var name: String
    var country: String
    
    init(name: String, country: String) {
        self.name = name
        self.country = country
    }
    
    // MARK: --NSCopying克隆协议
    func copy(with zone: NSZone? = nil) -> Any {
        return Person(name: self.name, country: self.country)
    }
}


var people = [Person(name: "Aoe", country: "USA"), Person(name: "Bob", country: "UK")]

func deepCopyArray(_ arr: [AnyObject]) -> [AnyObject] {
    return arr.map { (item) -> AnyObject in
        if item is NSObject && item is NSCopying {
            return item.copy() as AnyObject
        } else {
            return item
        }
    }
}

var otherPeople = deepCopyArray(people) as! [Person]
var otherPeopleNoDeep = people
people[0].name = "XXX"
print("otherPeople[0].name \(otherPeople[0].name)")
print("otherPeopleNoDeep[0].name \(otherPeopleNoDeep[0].name)")




print("----大内存直接转移----")
class SumCopying: NSObject, NSCopying {
    
    var firstValue: Int
    var secondValue: Int
    var resultsCache: [[Int]]
    
    var Result: Int {
        get {
            return firstValue < resultsCache.count && secondValue < resultsCache[firstValue].count ? resultsCache[firstValue][secondValue] : firstValue + secondValue
        }
    }
    
    init(first: Int, second: Int) {
        firstValue = first
        secondValue = second
        resultsCache = [[Int]](repeating: [Int](repeating: 0, count: 1000), count: 1000)
        for i in 0..<1000 {
            for j in 0..<1000 {
                resultsCache[i][j] = i + j
            }
        }
    }
    
    private init(first: Int, second: Int, cache: [[Int]]) {
        firstValue = first
        secondValue = second
        resultsCache = cache
    }
    
    // MARK: --NSCopying克隆协议
    func copy(with zone: NSZone? = nil) -> Any {
        return SumCopying(first: self.firstValue, second: self.secondValue, cache: self.resultsCache)
    }
    
}


print("开始生成原始对象\(Date())")
var prototype = SumCopying(first: 10, second: 10)
print("原始对象的结果\(prototype.Result)")
print("原始对象生成完毕并开始克隆\(Date())")
var clone = prototype.copy() as! SumCopying
clone.firstValue = 100
print("修改后的克隆对象的结果\(clone.Result)")
print("修改完克隆对象并生成新结果\(Date())")
print("原始对象的结果\(prototype.Result)")




print("----日志处理----")
class Message {
    var to: String
    var subject: String
    
    init(to: String, subject: String) {
        self.to = to
        self.subject = subject
    }
}


class MessageLooger {
    var messages: [Message] = []
    
    func logMessage(msg: Message) {
        messages.append(msg)
    }
    
    func processMessages(callBack: (Message) -> Void) {
        for msg in messages {
            callBack(msg)
        }
    }
}

var logger = MessageLooger()
var message = Message(to: "A", subject: "Hello")
logger.logMessage(msg: message)

message.to = "AA"
message.subject = "World"
logger.logMessage(msg: message)

logger.processMessages { (msg) in
    print("Message - To: \(msg.to) Subject: \(msg.subject)")
}

// 👆的例子导致引用重复对象
// 优化下
class MessageLoggerUseInit: MessageLooger {
    override func logMessage(msg: Message) {
        messages.append(Message.init(to: msg.to, subject: msg.subject))
    }
}

var loggeri = MessageLoggerUseInit()
var messagei = Message(to: "AA", subject: "Hello")
loggeri.logMessage(msg: messagei)

messagei.to = "AA"
messagei.subject = "World"
loggeri.logMessage(msg: messagei)

loggeri.processMessages { (msg) in
    print("Message - To: \(msg.to) Subject: \(msg.subject)")
}

// 👆的例子导致MessageLoggerUseInit类依赖于Message的初始化器
// 一旦需要集成Message类并创建更具体的对象时将导致依赖点全部要改动

class DetailMesssage: Message {
    var from: String
    
    init(to: String, subject: String, from: String) {
        self.from = from
        super.init(to: to, subject: subject)
    }
    
}

var loggerm = MessageLoggerUseInit()
var messagem = Message(to: "A", subject: "Hello")
loggerm.logMessage(msg: messagem)

loggerm.logMessage(msg: DetailMesssage(to: "D", subject: "D", from: "D"))
// 组件外优化，然而并没有什么卵用,将导致信息丢失
loggerm.processMessages { (msg) in
    if let detailed = msg as? DetailMesssage {
        print("Message - To: \(detailed.to) From: \(detailed.from) Subject: \(msg.subject)") // 永远没有机会执行导致信息丢失
    } else {
        print("Message - To: \(msg.to) Subject: \(msg.subject)")
    }
}


// 组件内优化，然而并没有什么卵用，导致内部持续有一个依赖点依赖于具体类的初始化器
class MessageLoggerOptimiseInside: MessageLooger {
    override func logMessage(msg: Message) {
        if let detailed = msg as? DetailMesssage {
            messages.append(DetailMesssage(to: detailed.to, subject: detailed.subject, from: detailed.from))
        } else {
            messages.append(Message.init(to: msg.to, subject: msg.subject))
        }
    }
}


// 在组件数据结构中做好对象原型模式收敛变化
class MessageCopying: NSObject, NSCopying {
    var to: String
    var subject: String
    
    init(to: String, subject: String) {
        self.to = to
        self.subject = subject
    }
    
    // MARK: --NSCopying克隆协议
    func copy(with zone: NSZone? = nil) -> Any {
        return MessageCopying(to: self.to, subject: self.subject)
    }
}

class DetailMessageCopying: MessageCopying {
    var from: String
    
    init(to: String, subject: String, from: String) {
        self.from = from
        super.init(to: to, subject: subject)
    }
    
    // MARK: --NSCopying克隆协议（重写）
    override func copy(with zone: NSZone? = nil) -> Any {
        return DetailMessageCopying(to: self.to, subject: self.subject, from: self.from)
    }
}

class MessageLoogerX {
    var messages: [MessageCopying] = []
    
    func logMessage(msg: MessageCopying) {
        messages.append(msg.copy() as! MessageCopying) // 组件内无需依赖于具体的类型以及具体类型的初始化器即可创建新的对象 抽象不应该依赖于细节 分离对象的创建方式和使用方式可以将对模版的依赖最小化
    }
    
    func processMessages(callBack: (MessageCopying) -> Void) {
        for msg in messages {
            callBack(msg)
        }
    }
}

var log = MessageLoogerX()
var m1 = MessageCopying(to: "CC", subject: "CC")
var m2 = DetailMessageCopying(to: "GG", subject: "GG", from: "GG")

log.logMessage(msg: m1)
log.logMessage(msg: m2)

log.processMessages { (msg) in
    if let detailed = msg as? DetailMessageCopying {
        print("Message - To: \(detailed.to) From: \(detailed.from) Subject: \(msg.subject)") // 永远没有机会执行导致信息丢失
    } else {
        print("Message - To: \(msg.to) Subject: \(msg.subject)")
    }
}




print("----Cocoa数组----")

class PersonC: NSObject, NSCopying {
    
    var name: String
    var country: String
    
    init(name: String, country: String) {
        self.name = name
        self.country = country
    }
    
    // MARK: --NSCopying克隆协议
    func copy(with zone: NSZone? = nil) -> Any {
        return PersonC(name: self.name, country: self.country)
    }
}

var data = NSMutableArray(objects: 10, "iOS", PersonC(name: "CCCC", country: "CCCC"))
//var copyData = data   // 直接复制顶层引用
//var copyData = data.mutableCopy() as! NSArray   // 浅复制
var copyData = NSMutableArray(array: data as! [Any], copyItems: true) // 深复制 如果copyItens设置为false将不会克隆实现了NSCopying的对象变成浅复制 不管深浅复制两个数组都是独立的引用




data[0] = 20.2
data[1] = "macOS"
(data[2] as! PersonC).name = "DDDD"

print("Is data === copyData \(data === copyData)")
print(copyData[0])
print(copyData[1])
print((copyData[2] as! PersonC).name)

// 因为NSMutableArray类型是class

//关于@NSCopying属性修饰符 可用于修饰任何存储属性 可以为继承于NSObject并实现了NSCopying协议的对象合成执行时会调用copy方法的setter方法
// 调用属性的setter方法时传入的值将作为原型被复制
// 局限性在于
// 1.对象初始化时的值不会被克隆
// 2.即使对象支持mutableCopy调用的方法也是copy
class LogItem {
    var from: String?
    @NSCopying var data: NSArray? // 浅复制
}

// NSMutableArray继承于NSObject并实现了NSCopying协议
var dataArray = NSMutableArray(array: [1, 2, 3, 4])

var logitem = LogItem()
logitem.from = "Alice"
logitem.data = dataArray;

dataArray[1] = 10
print("Value: \(logitem.data![1])")

// 成为了不可变对象不可修改
//logitem.data[2] = 33







