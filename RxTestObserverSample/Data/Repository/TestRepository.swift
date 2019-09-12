//
//  TestRepository.swift
//  RxSampleTest
//
//  Created by Gustavo Miyamoto on 9/7/19.
//  Copyright © 2019 Gustavo Miyamoto. All rights reserved.
//

import RxSwift

protocol TestRepository {
    func someRequest() -> Observable<Int>
}
