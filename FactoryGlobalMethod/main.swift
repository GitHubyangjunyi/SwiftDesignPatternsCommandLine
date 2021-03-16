//
//  main.swift
//  FactoryGlobalMethod
//
//  Created by 杨俊艺 on 2021/3/10.
//

import Foundation

// 当多个类同时遵循一个协议，而你需要从中选择一个类来进行实例化时就可以使用工厂方法

protocol RentalCar {
    var name: String { get }
    var passengers: Int { get }
    var pricePerDay: Float { get }
}


class Compact: RentalCar {
    var name: String = "Golf"
    var passengers: Int = 3
    var pricePerDay: Float = 20
}

class Sports: RentalCar {
    var name: String = "Porsche"
    var passengers: Int = 1
    var pricePerDay: Float = 100
}

class SUV: RentalCar {
    var name: String = "Cadillac"
    var passengers: Int = 8
    var pricePerDay: Float = 75
}

class CarSelector {
    class func selectCar(passengers: Int) -> String? {
        var car: RentalCar?
        switch passengers {
        case 0...1:
            car = Sports()
        case 2...3:
            car = Compact()
        case 4...8:
            car = SUV()
        default:
            car = nil
        }
        return car?.name
    }
}

var passengers = [1, 3, 5]

for p in passengers {
    print("\(String(describing: CarSelector.selectCar(passengers: p)))")
}


class MiniVan: RentalCar {
    var name: String = "Express"
    var passengers: Int = 14
    var pricePerDay: Float = 40
}
// 至此存在一个问题，由于需要实例化实现类所以CarSelector无法从Rental协议提供的抽象获益，相反的是没有带来任何益处
// 只需新增一个实现类就会带来问题变化点，switch判断又要修改了
// CarSelector如果想使用遵循Rental协议的类必须了解具体类，这与紧耦合还不太一样，因为CarSelector并不依赖于所使用的类的实现
// 问题在于CarSelector需要了解实现Rental协议的类的实现，一旦新增一个实现类就需要改动CarSelector
// 并且各个实现类的适用条件发生变化时也要更新CarSelector的判断逻辑，比如SUV适用人数一旦改变就需要修改CarSelector的判断逻辑

// 第二个问题是调用组件增加时选择实现类的逻辑会散布在各个角落
class PriceCalculator {
    class func calculatePrice(passengers: Int, days: Int) -> Float? {
        var car: RentalCar?
        switch passengers {
        case 0...1:
            car = Sports()
        case 2...3:
            car = Compact()
        case 4...8:
            car = SUV()
        default:
            car = nil
        }
        return car == nil ? nil : car!.pricePerDay * Float(days)
    }
}

// 最
func createRentalCar(passengers: Int) -> RentalCar? {
    var car: RentalCar?
    switch passengers {
    case 0...1:
        car = Sports()
    case 2...3:
        car = Compact()
    case 4...8:
        car = SUV()
    default:
        car = nil
    }
    return car
}

class CarSelectorX {
    class func selectCar(passengers: Int) -> String? {
        return createRentalCar(passengers: passengers)?.name
    }
}

// 现在CarSelectorX只对全局工厂方法和Rental协议存在依赖，无需了解实现类以及类之间的关系，只需要知道调用工厂方法可以获得一个遵循Rental协议的对象
// 这样可以避免决策逻辑散步于各个角落


// 全局函数会疏离协议及其设计的类，接下去改用基类
class BaseRentalCar {
    private var nameBV: String
    private var passengersBV: Int
    private var priceBV: Float
    
    fileprivate init(name: String, passengers: Int, price: Float) {
        self.nameBV = name
        self.passengersBV = passengers
        self.priceBV = price
    }
    
    final var name: String {
        return nameBV
    }
    
    final var passengers: Int {
        return passengersBV
    }
    
    final var pricePerDay: Float {
        return priceBV
    }
    
    class func createBaseRentalCar(passengers: Int) -> BaseRentalCar? {
        var car: BaseRentalCar?
        switch passengers {
        case 0...3:
            car = BaseCompact()
        case 4...8:
            car = BaseSUV()
        default:
            car = nil
        }
        return car
    }
}

class BaseCompact: BaseRentalCar {
    fileprivate init() {
        super.init(name: "Golf", passengers: 3, price: 20)
    }
}


class BaseSUV: BaseRentalCar {
    fileprivate init() {
        super.init(name: "Cadillac", passengers: 8, price: 75)
    }
}

// 以上实现最为接近抽象基类
// 为了让基类实现类似于协议对实现类进行约束进行了特别设计,子类必须在构造器中调用父类的构造器设置支持变量


class CarSelectorXX {
    class func selectCar(passengers: Int) -> String? {
        return BaseRentalCar.createBaseRentalCar(passengers: passengers)?.name
    }
}























