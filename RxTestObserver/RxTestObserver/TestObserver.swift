//
//  TestObserver.swift
//  RxTestObserver
//
//  Created by Gustavo Miyamoto on 9/12/19.
//  Copyright © 2019 Gustavo Luis Miyamoto. All rights reserved.
//

import Foundation
import RxSwift

///
/// An Observer that records events and allows making assertions about them.
///
public class TestObserver<T> {
    private(set) var values: [T] = []
    private(set) var error: Error? = nil
    private(set) var isCompleted = false {
        didSet {
            guard isCompleted else { return }
            completedHandler?()
        }
    }
    private(set) var isDisposed = false
    
    private var valueCountHandler: ((Int) -> ())?
    private var completedHandler: (() -> ())?
    private var disposeHandler: (() -> ())?
    
    var valueCount: Int {
        return values.count
    }
    
    private init(_ source: Observable<T>) {
        let disposable = source.subscribe(onNext: { [weak self] value in
            guard let self = self else { return }
            self.values.append(value)
            self.valueCountHandler?(self.valueCount)
            }, onError: { [weak self] error in
                guard let self = self else { return }
                self.error = error
            }, onCompleted: { [weak self] in
                guard let self = self else { return }
                self.isCompleted = true
        }) { [weak self] in
            guard let self = self else { return }
            self.isDisposed = true
        }
        
        disposeHandler = {
            disposable.dispose()
        }
    }
    
    public func dispose() {
        disposeHandler?()
    }
    
    static func create(_ observable: Observable<T>) -> TestObserver<T> {
        return TestObserver(observable)
    }
    
    /// Assert that this TestObserver received the specified number onNext events.
    ///
    /// - Parameters:
    ///   - expected: the expected number of onNext events
    ///   - message: an optional description of the failure
    /// - Returns: self
    @discardableResult
    public func assertValueCount(expected: Int, message: String = "", file: StaticString = #file, line: UInt = #line) -> Self {
        XCTAssertEqual(valueCount, expected, message, file: file, line: line)
        return self
    }
    
    /// Assert that this TestObserver has not received any onNext events.
    ///
    /// - Parameters:
    ///   - message: an optional description of the failure
    /// - Returns: self
    @discardableResult
    public func assertNoValues(message: String = "", file: StaticString = #file, line: UInt = #line) -> Self {
        XCTAssertTrue(values.isEmpty, message, file: file, line: line)
        return self
    }
    
    /// Assert that this TestObserver has received onError events.
    ///
    /// - Parameters:
    ///   - message: an optional description of the failure
    /// - Returns: self
    @discardableResult
    public func assertError(message: String = "", file: StaticString = #file, line: UInt = #line) -> Self {
        XCTAssertNotNil(error, message, file: file, line: line)
        return self
    }
    
    /// Assert that this TestObserver has not received any onError events.
    ///
    /// - Parameters:
    ///   - message: an optional description of the failure
    /// - Returns: self
    @discardableResult
    public func assertNoError(message: String = "", file: StaticString = #file, line: UInt = #line) -> Self {
        XCTAssertNil(error, message, file: file, line: line)
        return self
    }
    
    /// Assert that there is a single error and it has the given message.
    ///
    /// - Parameters:
    ///   - expected: the message expected
    ///   - message: an optional description of the failure
    /// - Returns: self
    @discardableResult
    public func assertErrorMessage(expected: String, message: String = "", file: StaticString = #file, line: UInt = #line) -> Self {
        XCTAssertEqual(error?.localizedDescription, expected, message, file: file, line: line)
        return self
    }
}

public extension TestObserver where T: Equatable {
    /// Assert that the TestObserver received only the specified values in the specified order.
    ///
    /// - Parameters:
    ///   - expected: the values expected
    ///   - message: an optional description of the failure
    /// - Returns: self
    @discardableResult
    public func assertValues(_ expected: T..., message: String = "", file: StaticString = #file, line: UInt = #line) -> Self {
        XCTAssertEqual(values, expected, message, file: file, line: line)
        return self
    }
    
    /// Assert that this TestObserver received an onNext value at the given index which is equal to the given value with respect to null-safe Equatable.
    ///
    /// - Parameters:
    ///   - index - the position to assert on
    ///   - expected: the value to expect
    ///   - message: an optional description of the failure
    /// - Returns: self
    @discardableResult
    public func assertValue(at index: Int, expected: T, message: String = "", file: StaticString = #file, line: UInt = #line) -> Self {
        let isIndexInValuesRange = 0..<values.count ~= index
        XCTAssertTrue(isIndexInValuesRange, message, file: file, line: line)
        guard isIndexInValuesRange else { return self }
        XCTAssertEqual(values[index], expected, message, file: file, line: line)
        return self
    }
}

public extension TestObserver where T: Hashable {
    /// Assert that the TestObserver/TestSubscriber received only items that are in the specified collection as well, irrespective of the order they were received.
    ///
    /// This helps asserting when the order of the values is not guaranteed, i.e., when merging asynchronous streams.
    ///
    /// To ensure that only the expected items have been received, no more and no less, in any order, apply assertValueCount(int) with expected.size().
    ///
    /// - Parameters:
    ///   - expected: the collection of values expected in any order
    ///   - message: an optional description of the failure
    /// - Returns: self
    @discardableResult
    public func assertValueSet(_ expected: Set<T>, message: String = "", file: StaticString = #file, line: UInt = #line) -> Self {
        expected.forEach { value in
            XCTAssertTrue(values.contains(value), message, file: file, line: line)
        }
        return self
    }
}

public extension TestObserver {
    /// Awaits the specified amount of time or until this TestObserver receives onComplete events.
    ///
    /// - Parameters:
    ///   - timeout: the waiting time
    /// - Returns: self
    public func await(timeout: Int? = nil) -> Self {
        guard !isCompleted else { return self }
        wait(timeout: timeout) { [weak self] semaphore in
            guard let self = self else { return }
            self.completedHandler = {
                semaphore.signal()
            }
        }
        return self
    }
    
    /// Await until the TestObserver receives the given number of items or terminates by  timeout
    ///
    /// - Parameters:
    ///   - max: the number of items expected at least
    ///   - timeout: the waiting time
    /// - Returns: self
    public func awaitCount(_ max: Int, timeout: Int? = nil) -> Self {
        guard !isCompleted, valueCount < max else { return self }
        wait(timeout: timeout) { [weak self] semaphore in
            guard let self = self else { return }
            self.valueCountHandler = { count in
                guard count >= max else { return }
                semaphore.signal()
            }
        }
        return self
    }
    
    /// Waits for, or decrements, a semaphore
    ///
    /// - Parameters:
    ///   - timeout: the waiting time
    ///   - run: closure to run until end of waiting time
    private func wait(timeout: Int? = nil, run: ((DispatchSemaphore) -> ())?) {
        let semaphore = DispatchSemaphore(value: 0)
        run?(semaphore)
        let wallTimeout: DispatchWallTime
        if let timeout = timeout {
            wallTimeout = .now() + .seconds(timeout)
        } else {
            wallTimeout = .distantFuture
        }
        _ = semaphore.wait(wallTimeout: wallTimeout)
    }
}

public extension ObservableType {
    public func test() -> TestObserver<E> {
        return TestObserver.create(self.asObservable())
    }
}

public extension Variable {
    public func test() -> TestObserver<Element> {
        return TestObserver.create(self.asObservable())
    }
}

