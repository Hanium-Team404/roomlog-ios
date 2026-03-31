//
//  NavigationRoutable.swift
//  Projects
//
//  Created by 김도연 on 3/26/26.
//

import Foundation

protocol NavigationRoutable {
    var destination: [NavigationDestination] { get set }
    func push(to view: NavigationDestination)
    func pop()
    func popToRootView()
}

@Observable
class NavigationRouter: NavigationRoutable {
    var destination: [NavigationDestination] = .init()
    
    func push(to view: NavigationDestination) {
        destination.append(view)
    }
    
    func pop() {
        _ = destination.popLast()
    }
    
    func popToRootView() {
        destination.removeAll()
    }
}
