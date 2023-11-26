//
//  File.swift
//  
//
//  Created by Philipp Wallrich on 01.11.23.
//

import Foundation

class IntcodeComputer {
    func copy() -> IntcodeComputer {
        return .init(program: program, ip: ip, relativeBase: relativeBase)
    }

    var ip: Int = 0
    var program: [Int: Int]
    private var relativeBase = 0

    init(program: [Int]) {
        self.program = Dictionary(uniqueKeysWithValues: program.enumerated().map { ($0.offset, $0.element) })
    }

    init(program: [Int: Int], ip: Int, relativeBase: Int) {
        self.program = program
        self.ip = ip
        self.relativeBase = relativeBase
    }

    func run(input: () async -> Int, output: (Int) -> Void) async {
        await performSteps(input: input, output: output)
    }

    private func splitOpcode(value: Int) -> (opcode: Int, parameterModes: [Int]) {
        let opcode = value % 100
        var temp = value / 100
        var parameters: [Int] = []
        while temp > 0 {
            parameters.append(temp % 10)
            temp /= 10
        }
        return (opcode, parameters)
    }

    private func getValueOrRelative(modes: [Int], ip: Int, idx: Int) -> Int {
        guard modes.count > idx else {
            return program[program[ip + idx + 1] ?? 0] ?? 0
        }
        if modes[idx] == 0 {
            return program[program[ip + idx + 1] ?? 0] ?? 0
        } else if modes[idx] == 1 {
            return program[ip + idx + 1] ?? 0
        } else if modes[idx] == 2 {
            return program[relativeBase + (program[ip + idx + 1] ?? 0)] ?? 0
        } else {
            fatalError()
        }
    }

    private func writeValue(modes: [Int], ip: Int, idx: Int, value: Int) {
        guard modes.count > idx else {
            program[program[ip + idx + 1] ?? 0] = value
            return
        }
        if modes[idx] == 0 {
            program[program[ip + idx + 1] ?? 0] = value
        } else if modes[idx] == 2 {
            program[relativeBase + (program[ip + idx + 1] ?? 0)] = value
        }
    }

    private func performSteps(input: () async -> Int, output: (Int) -> Void) async {
        while ip < program.count && program[ip] != 99 {
            let (opCode, pModes) = splitOpcode(value: program[ip]!)
            switch opCode {
            case 1:
                let firstValue = getValueOrRelative(modes: pModes, ip: ip, idx: 0)
                let secondValue = getValueOrRelative(modes: pModes, ip: ip, idx: 1)
                let res = firstValue + secondValue
                writeValue(modes: pModes, ip: ip, idx: 2, value: res)
                ip += 4
            case 2:
                let firstValue = getValueOrRelative(modes: pModes, ip: ip, idx: 0)
                let secondValue = getValueOrRelative(modes: pModes, ip: ip, idx: 1)
                let res = firstValue * secondValue
                writeValue(modes: pModes, ip: ip, idx: 2, value: res)
                ip += 4
            case 3:
                let value = await input()
                writeValue(modes: pModes, ip: ip, idx: 0, value: value)
                ip += 2
            case 4:
                let firstValue = getValueOrRelative(modes: pModes, ip: ip, idx: 0)
                ip += 2
                output(firstValue)

            case 5: // jump if true
                let firstValue = getValueOrRelative(modes: pModes, ip: ip, idx: 0)
                let secondValue = getValueOrRelative(modes: pModes, ip: ip, idx: 1)
                if firstValue != 0 {
                    ip = secondValue
                } else {
                    ip += 3
                }

            case 6: // jump if false
                let firstValue = getValueOrRelative(modes: pModes, ip: ip, idx: 0)
                let secondValue = getValueOrRelative(modes: pModes, ip: ip, idx: 1)
                if firstValue == 0 {
                    ip = secondValue
                } else {
                    ip += 3
                }

            case 7: // less than
                let firstValue = getValueOrRelative(modes: pModes, ip: ip, idx: 0)
                let secondValue = getValueOrRelative(modes: pModes, ip: ip, idx: 1)
                let res = firstValue < secondValue ? 1 : 0
                writeValue(modes: pModes, ip: ip, idx: 2, value: res)
                ip += 4

            case 8: // equals
                let firstValue = getValueOrRelative(modes: pModes, ip: ip, idx: 0)
                let secondValue = getValueOrRelative(modes: pModes, ip: ip, idx: 1)
                let res = firstValue == secondValue ? 1 : 0
                writeValue(modes: pModes, ip: ip, idx: 2, value: res)
                ip += 4
            case 9: // relative offset
                let firstValue = getValueOrRelative(modes: pModes, ip: ip, idx: 0)
                relativeBase += firstValue
                ip += 2
            default:
                fatalError()
            }
        }
        return
    }
}
