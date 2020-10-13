import UIKit

public protocol coordinator {
    func start()
    var complete : (_ needContinouse : Bool)->Void { get set }
}

public protocol coordinateMulnipulator {
    func next()
    func finish()
}

public protocol coordinatorStorage {
    associatedtype InputDataType
    var dataCache : InputDataType { get set }
}


public class BaseCoordinator<T> : coordinator, coordinateMulnipulator, coordinatorStorage {
    public var complete: (_ needContinouse : Bool) -> Void

    public typealias InputDataType = T?
    public var dataCache: T?

    public var subCoordinators : [BaseCoordinator<T>] = []
    init(subCoordinators : [BaseCoordinator<T>] = [], complete : @escaping (_ needContinouse : Bool) -> Void = {_ in}) {
        self.subCoordinators = subCoordinators
        self.complete = complete
    }
    public func start() {
        if let rootCoor = subCoordinators.first {
            rootCoor.dataCache = self.dataCache
            rootCoor.complete = {[weak self] needContinouse in
                print("\(type(of: self)) complete")
                self?.dataCache = rootCoor.dataCache
                if needContinouse {
                    self?.next()
                }else {
                    self?.finish()
                }

            }
            rootCoor.start()
        }else {
            self.complete(true)
        }
    }

    public func next() {
        print("\(type(of: self)) next")
        defer {objc_sync_exit(self)}
        objc_sync_enter(self)
        subCoordinators = Array(subCoordinators.dropFirst())
        if let nextCoor = subCoordinators.first {
            print("type of next : \(type(of: nextCoor))")
            nextCoor.dataCache = dataCache
            nextCoor.complete = {[weak self] needContinouse in
                print("\(type(of: self)) complete")
                self?.dataCache = nextCoor.dataCache
                if needContinouse {
                    self?.next()
                }else {
                    self?.finish()
                }

            }
            nextCoor.start()
        }else {
            self.complete(true)
        }

    }

    public func finish() {
        print("\(type(of: self)) finish")
        self.complete(true)
        //Do furthor custom action.
    }
}

public class JKGeneralFlowCoordinator : BaseCoordinator<[String:Any]> {

}

public class AFC : JKGeneralFlowCoordinator {
    public override func start() {
        print("AFC start, complete : \(String(describing: self.complete))")
        self.complete(true)
    }
}

public class BFC : JKGeneralFlowCoordinator {
    public override func start() {
        print("BFC start, complete : \(String(describing: self.complete))")
        self.complete(true)
    }
}

var a = AFC()
var b = BFC()
var root = JKGeneralFlowCoordinator(subCoordinators: [a,b]) { (needContinue) in
    print("done")
}

root.start()
