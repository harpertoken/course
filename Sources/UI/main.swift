// SPDX-License-Identifier: MIT

import SwiftUI
import Core
import ControlPlane
import SystemInterfaces
import SystemObservation

@main
struct SystemManagerUI: App {
    @StateObject private var viewModel = SystemManagerViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
    }
}

@MainActor
class SystemManagerViewModel: ObservableObject {
    @Published var processes: [UUID: RuntimeProcess.State] = [:]
    @Published var selectedProcess: UUID?

    private let runtimeManager = RuntimeManager()
    private let taskMetricsSampler = TaskMetricsSampler()
    private let systemMetricsSampler = SystemMetricsSampler()
    private var supervisor: Supervisor?

    init() {
        supervisor = Supervisor(
            runtimeManager: runtimeManager,
            taskMetricsSampler: taskMetricsSampler,
            systemMetricsSampler: systemMetricsSampler
        )
        supervisor?.start()
        loadProcesses()
    }

    func loadProcesses() {
        Task {
            let procs = await runtimeManager.list()
            await MainActor.run {
                processes = procs
            }
        }
    }

    func runProcess(command: String, arguments: [String]) {
        Task {
            let descriptor = TaskDescriptor(command: command, arguments: arguments)
            do {
                _ = try await runtimeManager.spawn(descriptor: descriptor)
                loadProcesses()
            } catch {
                print("Error: \(error)")
            }
        }
    }

    func stopProcess(id: UUID) {
        Task {
            do {
                try await runtimeManager.stop(id: id)
                loadProcesses()
            } catch {
                print("Error: \(error)")
            }
        }
    }

    func getMetrics(for id: UUID) async -> [String: String]? {
        return await runtimeManager.metrics(for: id)
    }
}

struct ContentView: View {
    @ObservedObject var viewModel: SystemManagerViewModel
    @State private var command = "/bin/echo"
    @State private var arguments = "hello"

    var body: some View {
        VStack {
            Text("SystemManager Dashboard")
                .font(.title)
                .padding()

            HStack {
                TextField("Command", text: $command)
                TextField("Arguments (comma-separated)", text: $arguments)
                Button("Run") {
                    let args = arguments.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
                    viewModel.runProcess(command: command, arguments: args)
                }
            }
            .padding()

            List(viewModel.processes.sorted(by: { $0.key.uuidString < $1.key.uuidString }), id: \.key) { (id, state) in
                HStack {
                    Text(id.uuidString)
                    Text(state.description)
                    Button("Stop") {
                        viewModel.stopProcess(id: id)
                    }
                    .disabled(!state.canStop)
                }
            }

            Button("Refresh") {
                viewModel.loadProcesses()
            }
            .padding()
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}
