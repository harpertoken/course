import Foundation
import Core
import ControlPlane
import SystemObservation

@main
struct SystemManager {
    static func main() async {
        let args = CommandLine.arguments

        guard args.count >= 2 else {
            printUsage()
            return
        }

        let command = args[1]

        let runtimeManager = RuntimeManager()
        let taskMetricsSampler = TaskMetricsSampler()
        let supervisor = Supervisor(runtimeManager: runtimeManager, taskMetricsSampler: taskMetricsSampler)

        // Start supervisor
        supervisor.start()

        switch command {
        case "run":
            guard args.count >= 3 else {
                print("Usage: sysman run <json_config>")
                return
            }
            let json = args[2]
            await handleRun(json: json, runtimeManager: runtimeManager)
        case "list":
            await handleList(runtimeManager: runtimeManager)
        case "stop":
            guard args.count >= 3 else {
                print("Usage: sysman stop <id>")
                return
            }
            let idString = args[2]
            await handleStop(idString: idString, runtimeManager: runtimeManager)
        case "stats":
            guard args.count >= 3 else {
                print("Usage: sysman stats <id>")
                return
            }
            let idString = args[2]
            await handleStats(idString: idString, runtimeManager: runtimeManager)
        case "daemon":
            await handleDaemon(runtimeManager: runtimeManager, taskMetricsSampler: taskMetricsSampler)
        default:
            print("Unknown command: \(command)")
            printUsage()
        }

        // Stop supervisor after command
        supervisor.stop()
    }

    static func printUsage() {
        print("""
        Usage: sysman <command> [args]

        Commands:
          run <json_config>    Run a process with JSON config
          list                 List running processes
          stop <id>            Stop process by ID
          stats <id>           Show stats for process by ID
          daemon               Start daemon mode for background monitoring

        JSON config example: {"command": "/bin/echo", "arguments": ["hello"]}
        """)
    }

    static func handleRun(json: String, runtimeManager: RuntimeManager) async {
        do {
            let data = json.data(using: .utf8)!
            let decoder = JSONDecoder()
            let descriptor = try decoder.decode(TaskDescriptor.self, from: data)
            let id = try await runtimeManager.spawn(descriptor: descriptor)
            print("Started process with ID: \(id)")

            // Wait up to 30 seconds for process to finish or timeout
            try await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
            print("Process may still be running. Use 'list' or 'stats' to check.")
        } catch {
            print("Error running process: \(error)")
        }
    }

    static func handleList(runtimeManager: RuntimeManager) async {
        let processes = await runtimeManager.list()
        if processes.isEmpty {
            print("No running processes")
        } else {
            for (id, state) in processes {
                print("\(id): \(state)")
            }
        }
    }

    static func handleStop(idString: String, runtimeManager: RuntimeManager) async {
        guard let id = UUID(uuidString: idString) else {
            print("Invalid ID: \(idString)")
            return
        }
        do {
            try await runtimeManager.stop(id: id)
            print("Stopped process \(id)")
        } catch {
            print("Error stopping process: \(error)")
        }
    }

    static func handleStats(idString: String, runtimeManager: RuntimeManager) async {
        guard let id = UUID(uuidString: idString) else {
            print("Invalid ID: \(idString)")
            return
        }
        if let metrics = await runtimeManager.metrics(for: id) {
            print("Metrics for \(id):")
            for (key, value) in metrics {
                print("  \(key): \(value)")
            }
        } else {
            print("Process not found: \(id)")
        }
    }

    static func handleDaemon(runtimeManager: RuntimeManager, taskMetricsSampler: TaskMetricsSampler) async {
        let supervisor = Supervisor(runtimeManager: runtimeManager, taskMetricsSampler: taskMetricsSampler)
        supervisor.start()
        print("Daemon started. Press Ctrl+C to stop.")
        // Keep running
        while true {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        }
    }
}
