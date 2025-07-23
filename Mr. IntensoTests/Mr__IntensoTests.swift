//
//  Mr__IntensoTests.swift
//  Mr. IntensoTests
//
//  Created by Lars Schneider on 17.03.2025.
//

import XCTest
@testable import Mr__Intenso

final class Mr__IntensoTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testPriorityQueue() throws {
        var pq = PriorityQueue<ObjectInformation>()
        for i in 0..<10 {
            var obj = ObjectInformation()
            obj.object = "\(i)"
            obj.favourite = (i % 2 == 0)
            obj.lastSpotted = Int64(i)
            pq.push(obj)
        }
        print(pq.description)
        
        for i in 0..<5 {
            let popped = pq.pop()!
            XCTAssert(popped.favourite && popped.object == "\(8 - (2 * i))")
        }
        for i in 0..<5 {
            let popped = pq.pop()!
            XCTAssert(!popped.favourite && popped.object == "\(9 - (2 * i))")
        }
        XCTAssert(pq.size() == 0)
    }
    
    func testObjectCache() throws {
        let objectCache = ObjectCache()
        for i in 0..<10 { // Fill cache with 10 objects
            var obj = ObjectInformation()
            obj.object = "\(i % 2)"
            obj.lastSpotted = Int64(10 - i)
            obj.detailedDescription = [PlaceholderObject()] // Otherwise will not be added. I made that mistake.
            objectCache.addObject(obj)
        }
        
        var test1 = ObjectInformation()
        test1.object = "1"
        // We will get the first "1" which is within the threshold
        print(objectCache.description)
        XCTAssert(objectCache.getCachedObject(test1)?.lastSpotted == Int64(1)) // Realistically this is the most recent seen object
        XCTAssert(objectCache.getCachedCount() == 2) // We are adding the same object to the cache basically. Therefore its two.
        objectCache.removeAll(where: { $0.lastSpotted < 3 })
        XCTAssert(objectCache.getCachedCount() == 0)
    }
    
    /**
            This tests the functionality of deleting entries if cache is full.
            Beware, that this test depends on the MAX_CACHE_SIZE in Constants.swift
     */
    func testObjectCacheLimit() throws {
        let objectCache = ObjectCache()
        var obj1 = ObjectInformation()
        obj1.object = "1"
        obj1.favourite = false
        obj1.lastSpotted = Int64(1)
        obj1.detailedDescription = [PlaceholderObject()]
        objectCache.addObject(obj1)
        
        var obj2 = ObjectInformation()
        obj2.object = "2"
        obj2.lastSpotted = Int64(2)
        obj2.favourite = true
        obj2.detailedDescription = [PlaceholderObject()]
        objectCache.addObject(obj2)
        
        var obj3 = ObjectInformation()
        obj3.object = "1"
        obj3.lastSpotted = Int64(3)
        obj3.favourite = false
        obj3.detailedDescription = [PlaceholderObject()]
        objectCache.addObject(obj3)
        
        var obj4 = ObjectInformation()
        obj4.object = "3"
        obj4.lastSpotted = Int64(4)
        obj4.favourite = false
        obj4.detailedDescription = [PlaceholderObject()]
        objectCache.addObject(obj4)
        
        XCTAssert(objectCache.getCachedCount() == 3) // limit set by Constants.swift
        XCTAssert(objectCache.getFirst(where: { $0.id == obj1.id }) == nil) // This element should have been removed
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
}
