//
//  main.swift
//  ObjectTemplate
//
//  Created by 杨俊艺 on 2021/2/21.
//

import Foundation

// 对象模版
var products = [
    ("Human Chess Board", "A fun game for the family", "Chess", 100.0, 2),
    ("Bling-Bling King", "Gold-plated, diamond-studded King", "Chess", 1200.0, 4)
    ]

func calculateTax(product: (String, String, String, Double, Int)) -> Double {
    return product.3 * 0.2
}

func calculateStockValue(tuples: [(String, String, String, Double, Int)]) -> Double {
    return tuples.reduce(0) { (total, item) in
        total + (item.3 * Double(item.4))
    }
}

print("\(products[0]) 商品的税为: \(calculateTax(product: products[0]))")
print("商品总价值为: \(calculateStockValue(tuples: products))")

// 👆的例子紧耦合了
// 一旦改动product中的元组的数据顺序那么计算函数必须做出相应的改变
// 👇的例子使用对象模版
// 即使修改了Product类的一个属性仅仅需要修改自己的初始化器而不会影响到外部代码
class Product {
    private var stockBackingValue: Int = 0
    
    var name: String
    var description: String
    var price: Double
    var stock: Int {
        get {
            stockBackingValue
        }
        set {
            stockBackingValue = max(0, newValue)
        }
    }
    
    init(name: String, description: String, price: Double, stock: Int) {
        self.name = name
        self.description = description
        self.price = price
        self.stock = stock
    }
}

var productss = [
    Product.init(name: "Human Chess Board", description: "A fun game for the family", price: 100, stock: 2),
    Product.init(name: "Bling-Bling King", description: "Gold-plated, diamond-studded King", price: 1200, stock: 4)
]

func calculateTaxs(product: Product) -> Double {
    return product.price * 0.2
}

func calculateStockValues(products: [Product]) -> Double {
    return products.reduce(0) { (total, item) in
        total + item.price * Double(item.stock)
    }
}


print("\(products[0]) 商品的税为: \(calculateTaxs(product: productss[0]))")
print("商品总价值为: \(calculateStockValues(products: productss))")


// 更进一步集成功能代码进行设计演化
class ProductX: Product {
    // 价值
    var stockValue: Double {
        return price * Double(stock)
    }
    
    // 计算税费
    func calculateTax(rate: Double) -> Double {
        return self.price * rate
    }
}

class ProductXX: ProductX {
    // 最大税费为10块，外部不可见逻辑
    override func calculateTax(rate: Double) -> Double {
        return min(10, self.price * rate)
    }
}

print("-50库存数量的商品总价值为: \(calculateStockValues(products: [ProductXX.init(name: "0000", description: "0000", price: 100, stock: -50)]))")







