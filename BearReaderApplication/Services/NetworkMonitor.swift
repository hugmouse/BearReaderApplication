//
//  NetworkMonitor.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 04.09.25.
//
//  Copyright 2025 Iaroslav Angliuster
//


import Foundation
import Network
import SwiftUI
import Observation

@MainActor
@Observable class NetworkMonitor {
    static let shared = NetworkMonitor()

    var isConnected = true
    var connectionType: NWInterface.InterfaceType?

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    private init() {
        startMonitoring()
    }

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
                self?.connectionType = path.availableInterfaces.first?.type
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }

    static func isNetworkError(_ error: Error) -> Bool {
        if let nsError = error as NSError? {
            return nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorNotConnectedToInternet
        }
        return false
    }
}
