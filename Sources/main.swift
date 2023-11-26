// The Swift Programming Language
// https://docs.swift.org/swift-book
import Foundation

let packageURL = URL(fileURLWithPath: #file).deletingLastPathComponent()
let fileURL = packageURL.appendingPathComponent("program.txt");

let program = try String(contentsOf: fileURL)
    .split(separator: ",")
    .map { Int($0)! }

let network = try Network(program: program)

await network.run()



