import Foundation

/**
    This file contains the datastructures I am using in this project.
 */

struct PriorityQueue<T: Comparable> {
    private var heap = Heap<T>()
    
    func size() -> Int {
        return heap.size()
    }
    
    mutating func clear() {
        heap.clear()
    }
    
    mutating func push(_ element: T) {
        heap.insert(element)
    }
    
    mutating func pop() -> T? {
        return heap.remove()
    }
    
    func peek() -> T? {
        return heap.peek()
    }
    
    mutating func removeAll(where predicate: (T) -> Bool) {
        heap.removeAll(where: predicate)
    }
    
    func retrieveFirstObject(where predicate: (T) -> Bool) -> T? {
        heap.retrieveFirstObject(where: predicate)
    }
    
    func getAll(where predicate: (T) -> Bool) -> [T] {
        return heap.filter(predicate)
    }
    
    var isEmpty: Bool {
        heap.isEmpty
    }
    
    var description: String {
        return heap.heap.map { "\($0)" }.joined(separator: "\n")
    }
}

// https://www.geeksforgeeks.org/heap-data-structure-implementation-in-swift/

struct Heap<T: Comparable> {
    var heap: [T] = []
    var count: Int = 0
    
    mutating func insert(_ element: T) {
        heap.append(element)
        count+=1
        var idx = heap.count - 1
        while idx > 0 && heap[idx] > heap[(idx-1) / 2] {
            heap.swapAt(idx, (idx - 1) / 2)
            idx = (idx - 1) / 2
        }
    }
    
    func size() -> Int {
        return count
    }
    
    /**
            We will most likely not be using that in hindsight.
     */
    mutating func remove() -> T? {
        guard !heap.isEmpty else { return nil }
        count-=1
        let root = heap[0]
        
        if heap.count == 1 {
            heap.removeFirst()
        } else {
            heap[0] = heap.removeLast()
            heapifyDown(from: 0)
        }
        return root
    }
    
    func peek() -> T? {
        return heap.first
    }
      
    var isEmpty: Bool {
        return heap.isEmpty
    }
    
    mutating func clear() {
        heap.removeAll()
        count = 0
    }
    
    private mutating func heapifyDown(from index: Int) {
        var idx = index
        while true {
            let left = 2 * idx + 1
            let right = 2 * idx + 2
            var maxIndex = idx
            if left < heap.count && heap[left] > heap[maxIndex] {
                maxIndex = left
            }
            if right < heap.count && heap[right] > heap[maxIndex] {
                maxIndex = right
            }
            if maxIndex == idx {
                break
            }
            heap.swapAt(idx, maxIndex)
            idx = maxIndex
        }
    }
    
    func filter(_ predicate: (T) -> Bool) -> [T] {
        return heap.filter(predicate)
    }
    
    /**
            This method is used for cache hits.
     */
    func retrieveFirstObject(where predicate: (T) -> Bool) -> T? {
        for obj in heap {
            if predicate(obj) { return obj }
        }
        return nil
    }
    
    /**
            This method is used to throw out objects which are kind of just littering the cached objects.
     */
    mutating func removeAll(where predicate: (T) -> Bool) {
        var idx = 0
        while idx < heap.count {
            if predicate(heap[idx]) {
                let _ = heap.remove(at: idx)
                count-=1
                heapifyDown(from: idx)
            } else {
                idx+=1
            }
        }
    }
}
