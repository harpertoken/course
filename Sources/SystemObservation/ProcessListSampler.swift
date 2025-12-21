import Foundation
import Darwin

/// Samples the list of running processes
public class ProcessListSampler {
    public struct ProcessInfo {
        public let pid: Int32
        public let ppid: Int32
        public let command: String
        public let uid: UInt32
    }

    public func sample() -> [ProcessInfo] {
        var mib = [CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0]
        var size: Int = 0

        // Get size
        var result = sysctl(&mib, u_int(mib.count), nil, &size, nil, 0)
        guard result == 0 else { return [] }

        let count = size / MemoryLayout<kinfo_proc>.stride
        var buffer = [kinfo_proc](repeating: kinfo_proc(), count: count)

        result = sysctl(&mib, u_int(mib.count), &buffer, &size, nil, 0)
        guard result == 0 else { return [] }

        return buffer.map { proc in
            let command = withUnsafeBytes(of: proc.kp_proc.p_comm) { bytes in
                String(cString: bytes.baseAddress!.assumingMemoryBound(to: CChar.self))
            }
            return ProcessInfo(
                pid: proc.kp_proc.p_pid,
                ppid: proc.kp_eproc.e_ppid,
                command: command,
                uid: proc.kp_eproc.e_ucred.cr_uid
            )
        }
    }
}