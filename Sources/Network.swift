import Foundation

struct Network {
    private let initialProgram: [Int]
    private let queues: MessageQueues

    init(program: [Int]) throws {
        self.initialProgram = program
        self.queues = .init(count: 50)
    }

    func run() async {
        let computers = createComputers()
        await withTaskGroup(of: Void.self) { taskGroup in
            for computer in computers {
                taskGroup.addTask {
                    await computer.run()
                }
            }

            var finished = 0
            for await _ in taskGroup {
                finished += 1
            }
        }
    }

    private func createComputers() -> [Computer] {
        (0..<50).map { Computer(queues: queues, idx: $0, program: initialProgram) }
    }
}

class Computer {
    private let queues: MessageQueues
    private let idx: Int
    private let program: IntcodeComputer
    init(queues: MessageQueues, idx: Int, program: [Int]) {
        self.queues = queues
        self.idx = idx
        self.program = IntcodeComputer(program: program)
    }

    func run() async {
        print("starting program \(idx)")
        var cachedOutputs: [Int] = []

        func updateOutputs() {
            assert(cachedOutputs.count == 3)
            let values = cachedOutputs
//            print("sending values \(values) from \(idx)")
            cachedOutputs = []
            if idx == 24 {
                print("24 is sending \(values)")
            }
            Task {
                await queues.set(values: Array(values[1...]), at: values[0])
            }
        }

        await program.run(input: {
//            print("computer \(idx) is reading value")
            if !cachedOutputs.isEmpty {
                print("\(idx) reading input but still having output \(cachedOutputs)")
            }
            return await queues.getValue(at: idx)
        }, output: {
            if idx == 24 {
                print("24 output \($0)")
            }
            cachedOutputs.append($0)
            if cachedOutputs.count >= 3 {
                updateOutputs()
            }
        })
    }
}

actor MessageQueues {
    // TODO: Use Dequeue
    private var queues: [[Int]]
    var cached255: [Int] = []
    var lastWrite: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()

    init(count: Int) {
        self.queues = (0..<count).map { [$0] }
    }

    func getValue(at idx: Int) -> Int {
        guard !queues[idx].isEmpty else {
            if CFAbsoluteTimeGetCurrent() - (lastWrite) >= 0.05, !cached255.isEmpty {
                self.queues[0] = cached255
                cached255 = []
            }
            return -1
        }
        print("\(idx) read non")
        return queues[idx].removeFirst()
    }

    func set(values: [Int], at idx: Int) {
        lastWrite = CFAbsoluteTimeGetCurrent()
        if idx == 255 {
            cached255 = values
            return
        }
        guard idx < queues.count else {
            return
        }
        print("set \(values) for \(idx)")
        queues[idx].append(contentsOf: values)
    }

}
