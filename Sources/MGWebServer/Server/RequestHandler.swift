//
//  RequestHandler.swift
//  WebServer
//
//  Created by Muhammed Mortgy on 05.06.24.
//

import Foundation
import Network

class RequestHandler {
    private let routeManager: RouteManager
    private weak var server: MGWebServer?

    init(routeManager: RouteManager, server: MGWebServer) {
        self.routeManager = routeManager
        self.server = server
    }

    func handleConnection(_ connection: NWConnection) {
        connection.stateUpdateHandler = { [weak self] newState in
            switch newState {
            case .ready:
                print("Client connected: \(connection.endpoint)")
                self?.receive(on: connection)
            case let .failed(error):
                print("Client connection failed: \(error)")
                connection.cancel()
            default:
                break
            }
        }
        connection.start(queue: .main)
    }

    private func receive(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                self?.handleRequest(data: data, on: connection)
            }
            if isComplete || error != nil {
                connection.cancel()
            } else {
                self?.receive(on: connection)
            }
        }
    }

    private func handleRequest(data: Data, on connection: NWConnection) {
        guard let request = HTTPRequest(data: data) else {
            let response = HTTPResponse(
                statusCode: 400,
                headers: ["Content-Type": "text/plain"],
                body: "Bad Request".data(using: .utf8)
            )
            connection.send(content: response.buildResponse(), completion: .contentProcessed({ _ in
                connection.cancel()
            }))
            return
        }

        // Use the asynchronous `handleRequest` function from RouteManager
        routeManager.handleRequest(request) { response in
            connection.send(content: response.buildResponse(), completion: .contentProcessed({ _ in
                connection.cancel()
            }))
        }
    }
}
