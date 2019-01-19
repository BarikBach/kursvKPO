//
//  GameScene.swift
//  kursv2
//
//  Created by Артем on 29/11/2018.
//  Copyright © 2018 Артем. All rights reserved.
//

import SpriteKit
import GameplayKit
import MessageUI

final class Statistic{ // singletone
    
    // Элементы настройки
    /// Количество разбиений на дистанции
    public var countDistance: Int {
        willSet(newCount){
            gradationDistance2.removeAll()
            gradationDistance2.append(0)
            for i in 1..<newCount {
                gradationDistance2.append(gradationDistance2[i - 1] + maxDistance2 / CGFloat(newCount))
            }
            for _ in 0..<countDistance {
                statisticDist.append(SectorTime())
            }
        }
    }
    public var rowDisplay :Int {
        didSet(oldRow) {
            statisticSector.removeAll()
            for _ in 0..<rowDisplay {
                var tmp : Array <Sector> = []
                for _ in 0..<columnDisplay {
                    tmp.append(Sector())
                }
                statisticSector.append(tmp)
            }
        }
    }
    public var columnDisplay :Int{
        didSet(oldColumn) {
            statisticSector.removeAll()
            for _ in 0..<rowDisplay {
                var tmp : Array <Sector> = []
                for _ in 0..<columnDisplay {
                    tmp.append(Sector())
                }
                statisticSector.append(tmp)
            }
        }
    }
    
    
    // Сама статистика
    private var numHit :Int = 0
    private var numDie :Int = 0
    private var sumTimeReaction :TimeInterval = 0.0
    private var statisticDist :Array <SectorTime>
    private var statisticDistance2 :Array <Array <Array <Array <SectorTime>>>>
    private var statisticSector :Array <Array<Sector>>
    
    // Функции предоставляющие работу со статистикой
    
    
    /// Функция должна вызываться при удачном попадании
    ///
    /// - Parameters:
    ///   - location: Координаты текущего попадания
    ///   - previousLocation: Координаты предыдущего **нажатия**
    ///   - time: Время между двумя нажатиями
    
    func hits(location: CGPoint, previousLocation: CGPoint, time: TimeInterval){
        
        /// location - координаты текущего попадания
        /// previousLocation - координаты предыдущего нажатия
        numHit += 1
        
        // Время реакции пользователя (Время затраченное на нажатие)
        sumTimeReaction += time
        
        // Статистика по дистанции попадания
        let distance2 = pow(location.x - previousLocation.x, 2) + pow(location.y - previousLocation.y, 2)
        for i in 1..<countDistance {
            print("dist", distance2, gradationDistance2[i])
            if distance2 > gradationDistance2[i - 1] && distance2 < gradationDistance2[i] {
                print("OK")
                statisticDist[i ].sumTime += time
                statisticDist[i ].num += 1
            }
        }
        // Расширенная статистика по дистанции попадания (Среднее время переноса от предыдущего касания)
        let (currentRow, currentColumn) = calcCell(location: location)
        let (previousRow, previousColumn) = calcCell(location: previousLocation)
        print("13;dfmv", currentRow, currentColumn, previousRow, previousColumn)
        statisticDistance2[currentRow][currentColumn][previousRow][previousColumn].num += 1
        statisticDistance2[currentRow][currentColumn][previousRow][previousColumn].sumTime += time
        
        // Статистика по "сетке"
        statisticSector[currentRow][currentColumn].hit += 1
    }
    /// Функция которая вызывается после смерти объекта (исчезновения без нажатия на него)
    ///
    /// - Parameter dieObjLocation: Координаты того объекта, который исчез
    func dieObj (dieObjLocation :CGPoint){
        numDie += 1
        var currentRow :Int = 0
        var currentColumn :Int = 0
        (currentRow, currentColumn) = calcCell(location: dieObjLocation)
        statisticSector[currentRow][currentColumn].miss += 1
    }
    
    func getProcentHit() -> Double {
        return round(Double(numHit) / Double(numHit + numDie) * 1000) / 10
    }
    func getAvgReact() -> TimeInterval {
        return sumTimeReaction / Double(numHit)
    }
    func getStatisticAvgReactFromDistance() -> (Array<TimeInterval>, Array<CGFloat>) {
        var avgReac : Array<TimeInterval> = []
        for item in statisticDist {
            avgReac.append(item.sumTime / TimeInterval(item.num))
        }
        return (avgReac, gradationDistance2)
    }
    func getStatisticAVGReactFromDistanceAdvanced() -> Array <Array <Array <Array <TimeInterval>>>> {
        var result : Array <Array <Array <Array <TimeInterval>>>> = []
        for i in 0..<rowDisplay {
            var tmp1 : Array<Array<Array<TimeInterval>>> = []
            for j in 0..<columnDisplay {
                var tmp2 : Array<Array<TimeInterval>> = []
                for k in 0..<rowDisplay{
                    var tmp3: Array<TimeInterval> = []
                    for l in 0..<columnDisplay {
                        tmp3.append(statisticDistance2[i][j][k][l].sumTime / TimeInterval(statisticDistance2[i][j][k][l].num))
                    }
                    tmp2.append(tmp3)
                }
                tmp1.append(tmp2)
            }
            result.append(tmp1)
        }
        return result
    }
    func getProcentFromSector() -> Array<Array<Double>> {
        var ProcentFromSector: Array<Array<Double>> = []
        for i in 0..<rowDisplay {
            var tmp : Array <Double> = []
            for j in 0..<columnDisplay {
                tmp.append(round(Double(statisticSector[i][j].hit) / Double (statisticSector[i][j].miss + statisticSector[i][j].hit) * 1000 ) / 10)
            }
            ProcentFromSector.append(tmp)
        }
        return ProcentFromSector
    }
    
    func cloudStatistic(){
        let mailController = MFMailComposeViewController()
        if !MFMailComposeViewController.canSendMail(){
            return
        }
        
        mailController.setToRecipients(["akseart@icloud.com"])
        mailController.setSubject("Результаты исследования")
        mailController.setMessageBody("\(getProcentHit()) \n \(getAvgReact()) \n \(getStatisticAvgReactFromDistance()) \n \(getStatisticAVGReactFromDistanceAdvanced()) \n \(getProcentFromSector()) ", isHTML: false)
    }
    
    static let statistic = Statistic()
    
    // Всопомогаельные поля и функции
    private var gradationDistance2 : Array <CGFloat> = []
    private init () {
        countDistance = 5
        
        rowDisplay = 10
        columnDisplay = 10
        
        // Так как координаты (0, 0) в центре экрана
        stepRowDisplay = UIScreen.main.bounds.height * 2 / CGFloat(rowDisplay)
        stepColumnDisplay = UIScreen.main.bounds.width * 2 / CGFloat(columnDisplay)
        
        numHit = 0
        numDie = 0
        sumTimeReaction = 0.0
        statisticDist = []
        for _ in 0..<countDistance {
            statisticDist.append(SectorTime())
        }
        statisticDistance2 = []
        for _ in 0..<rowDisplay {
            var tmp1 : Array<Array<Array<SectorTime>>> = []
            for _ in 0..<columnDisplay {
                var tmp2 : Array<Array<SectorTime>> = []
                for _ in 0..<rowDisplay{
                    var tmp3: Array<SectorTime> = []
                    for _ in 0..<columnDisplay {
                        tmp3.append(SectorTime())
                    }
                    tmp2.append(tmp3)
                }
                tmp1.append(tmp2)
            }
            statisticDistance2.append(tmp1)
        }
        statisticSector = []
        for _ in 0..<rowDisplay {
            var tmp : Array <Sector> = []
            for _ in 0..<columnDisplay {
                tmp.append(Sector())
            }
            statisticSector.append(tmp)
        }
        gradationDistance2.removeAll()
        gradationDistance2.append(0)
        for i in 1..<countDistance {
            gradationDistance2.append(gradationDistance2[i - 1] + maxDistance2 / CGFloat(countDistance))
        }
        for _ in 0..<countDistance {
            statisticDist.append(SectorTime())
        }
    }
    struct Sector {
        var hit  :Int = 0
        var miss :Int = 0
    }
    struct SectorTime {
        var sumTime  :TimeInterval = 0
        var num :Int = 0
    }
    private let maxDistance2 = pow(UIScreen.main.bounds.width, 2) + pow(UIScreen.main.bounds.height, 2)
    /// Очистка статистики, то есть все настройки остаются с такими же значениями, однако вся информация будет затерта
    private func clearStatistic() {
        numHit = 0
        numDie = 0
        sumTimeReaction = 0.0
        statisticDist = []
        for _ in 0..<countDistance {
            statisticDist.append(SectorTime())
        }
        statisticDistance2 = []
        for _ in 0..<rowDisplay {
            var tmp1 : Array<Array<Array<SectorTime>>> = []
            for _ in 0..<columnDisplay {
                var tmp2 : Array<Array<SectorTime>> = []
                for _ in 0..<rowDisplay{
                    var tmp3: Array<SectorTime> = []
                    for _ in 0..<columnDisplay {
                        tmp3.append(SectorTime())
                    }
                    tmp2.append(tmp3)
                }
                tmp1.append(tmp2)
            }
            statisticDistance2.append(tmp1)
        }
        statisticSector = []
        for _ in 0..<rowDisplay {
            var tmp : Array <Sector> = []
            for _ in 0..<columnDisplay {
                tmp.append(Sector())
            }
            statisticSector.append(tmp)
        }
    }
    private let stepRowDisplay : CGFloat
    private let stepColumnDisplay : CGFloat
    private func calcCell (location : CGPoint) -> (Int, Int){
        
        let cellX = Int(floor((UIScreen.main.bounds.width  + location.x) / stepColumnDisplay))
        let cellY = Int(floor((UIScreen.main.bounds.height + location.y) / stepRowDisplay))
        return (cellX, cellY)
    }
}


class Object{
    var object :SKShapeNode
    init(width: CGFloat, height: CGFloat, safeZone: UIEdgeInsets) {
        let radius = CGFloat.random(in: 40...50)
        object = SKShapeNode.init(circleOfRadius: radius)
        object.fillColor = randColor()
        object.zPosition = 1.0
        object.position = CGPoint(x: CGFloat.random(in: -width/2 + safeZone.bottom...width/2 - safeZone.top), y: CGFloat.random(in: -height/2 + safeZone.left...height/2-safeZone.right))
        object.name = "object"
        object.userData = ["Radius": Float(radius), "Lifetime": Float(200), "TimeBirth": NSDate()]
        
    }
    private func randColor() -> SKColor {
        return SKColor.init(red: CGFloat.random(in: 0...1), green: CGFloat.random(in: 0...1), blue: CGFloat.random(in: 0...1), alpha: CGFloat.random(in: 0...1))
    }
}

class GameScene: SKScene {
    
    private var object :SKShapeNode?
    private var timer = Timer()
    private var statis = Statistic.statistic
    
    
    @objc  func newObject () {
        object = Object.init(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height, safeZone: (self.view?.safeAreaInsets)!).object
        self.addChild(object!)
        timer = Timer.scheduledTimer(timeInterval: TimeInterval.random(in: 0.5...1.5), target: self, selector: #selector(self.newObject), userInfo: nil, repeats: false)
    }
    override func didMove(to view: SKView) {
        newObject() //Вызывается один раз
    }
    
    public func isOverlap(obj: SKShapeNode, touch :UITouch) -> Bool { //Костыль
        let touched = touch.location(in: obj)
        let radius = obj.userData!["Radius"] as! Float // Ещё один костыль
        if  Float(touched.x * touched.x + touched.y * touched.y) <= radius*radius  { // Вообще велосипед изобрел занаво
            return true
        }
        return false
    }
    
    var previousTouchLocation: CGPoint = CGPoint(x: 0, y: 0)
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch: UITouch in touches {
            let touchesCircle = SKShapeNode(circleOfRadius: 3)
            touchesCircle.position = touch.location(in: self)
            touchesCircle.fillColor = UIColor.red
            touchesCircle.strokeColor = UIColor.yellow
            addChild(touchesCircle)
            enumerateChildNodes(withName: "object") { (object, stop) in
                if self.isOverlap(obj: object as! SKShapeNode, touch: touch) {
                    
                    self.statis.hits(location: touch.location(in: self), previousLocation: self.previousTouchLocation, time: -(object.userData!["TimeBirth"] as! NSDate).timeIntervalSinceNow)
                    object.removeFromParent()
                }
            }
            previousTouchLocation = touch.location(in: self)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        //Истекло время
        enumerateChildNodes(withName: "object") { (obj, stop) in //Ещё больший костыль
            obj.userData!["Lifetime"] = (obj.userData!["Lifetime"] as! Float) - 1
            if abs( 0 - (obj.userData!["Lifetime"] as! Float)) < 0.00001 {
                self.statis.dieObj(dieObjLocation: obj.position)
                obj.removeFromParent()
            }
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("_______________________________ \n")
        print (" Procent: \(statis.getProcentHit()) \n AngReact: \(statis.getAvgReact()) \n StatisticFrom Distance \(statis.getStatisticAvgReactFromDistance()) \n  \n \(statis.getProcentFromSector()) ")//\(statis.getStatisticAVGReactFromDistanceAdvanced())
    }
}
