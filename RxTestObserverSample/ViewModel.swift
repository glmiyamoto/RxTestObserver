//
//  ViewModel.swift
//  RxSampleTest
//
//  Created by Gustavo Miyamoto on 9/7/19.
//  Copyright © 2019 Gustavo Miyamoto. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

class ViewModel {
    private let repository: TestRepository
    private let disposeBag = DisposeBag()
    
    var result = PublishRelay<String>()
    var result2 = BehaviorRelay<String>(value: "")
    var result3 = Variable<String>("")
    var result4: Single<String>?
    
    init(repository: TestRepository) {
        self.repository = repository
    }
    
    func fetchTest() {
        repository.someRequest().subscribe(onNext: { [weak self] value in
            guard let self = self else { return }
            self.result.accept("Test \(value)")
        }).disposed(by: disposeBag)
    }
    
    func fetchTest2() {
        repository.someRequest().subscribe(onNext: { [weak self] value in
            guard let self = self else { return }
            self.result2.accept("Test \(value)")
        }).disposed(by: disposeBag)
    }
    
    func fetchTest3() {
        repository.someRequest().subscribe(onNext: { [weak self] value in
            guard let self = self else { return }
            self.result3.value = "Test \(value)"
        }).disposed(by: disposeBag)
    }
    
    func fetchTest4() -> Observable<String> {
        return self.repository.someRequest().map({ value in "Test \(value)" })
    }
    
    func fetchTest5() {
        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(3), execute: { [weak self] in
            guard let self = self else { return }
            self.repository.someRequest().subscribe(onNext: {value in
                self.result.accept("Test \(value)")
            }).disposed(by: self.disposeBag)
        })
    }
}
