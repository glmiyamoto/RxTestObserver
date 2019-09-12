//
//  RxTestObserverSampleTests.swift
//  RxTestObserverSampleTests
//
//  Created by Gustavo Miyamoto on 9/12/19.
//  Copyright © 2019 Gustavo Luis Miyamoto. All rights reserved.
//

import XCTest
import RxTestObserver

@testable import RxTestObserverSample

class RxTestObserverSampleTests: XCTestCase {
    private let repository: TestRepository = MockTestDataSource()
    private var viewModel: ViewModel!
    
    override func setUp() {
        super.setUp()
        
        viewModel = ViewModel(repository: repository)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testExample1() {
        let testObserver = viewModel.result.test()
        
        viewModel.fetchTest()
        
        testObserver.assertNoError()
            .assertValueCount(expected: 1)
            .assertValues("Test 1")
            .dispose()
    }
    
    func testExample1_2() {
        let testObserver = viewModel.result.test()
        
        viewModel.fetchTest()
        viewModel.fetchTest()
        
        testObserver.assertNoError()
            .assertValueCount(expected: 2)
            .assertValues("Test 1", "Test 2")
            .dispose()
    }
    
    func testExample2() {
        let testObserver = viewModel.result2.test()
        
        viewModel.fetchTest2()
        
        testObserver.assertNoError()
            .assertValueCount(expected: 2)
            .assertValue(at: 1, expected: "Test 1")
            .dispose()
    }
    
    func testExample3() {
        let testObserver = viewModel.result3.test()
        
        viewModel.fetchTest3()
        
        testObserver.assertNoError()
            .assertValueCount(expected: 2)
            .assertValue(at: 1, expected: "Test 1")
            .dispose()
    }
    
    func testExample4() {
        let testObserver = viewModel.fetchTest4().test()
        
        testObserver.await()
            .assertNoError()
            .assertValues("Test 1")
            .dispose()
    }
    
    func testExample5() {
        let testObserver = viewModel.result.test()
        
        viewModel.fetchTest5()
        
        testObserver.awaitCount(1)
            .assertNoError()
            .assertValues("Test 1")
            .dispose()
    }
}
