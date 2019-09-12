//
//  MockTestDataSource.swift
//  RxSampleTestTests
//
//  Created by Gustavo Miyamoto on 9/7/19.
//  Copyright © 2019 Gustavo Miyamoto. All rights reserved.
//

import RxSwift

@testable import RxTestObserverSample

class MockTestDataSource {
    private var count = 0
}

extension MockTestDataSource: TestRepository {
    func someRequest() -> Observable<Int> {
        count += 1
        return Observable.just(count)
    }
}
