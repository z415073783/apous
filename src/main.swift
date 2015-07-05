//
//  main.swift
//  apous
//
//  Created by David Owens on 7/4/15.
//  Copyright © 2015 owensd.io. All rights reserved.
//

import Foundation


// 1. Check for Cartfile, build deps
// 2. Check for Portfile, build deps
// 3. Concat all .swift files into .apous.swift
// 4. swiftc .apous.swift

enum ErrorCodes: Int, ErrorType {
    case InvalidUsage = 1
    case PathNotFound
}

func printUsage() {
    print("that's cute... maybe one day")
}

func exit(code: ErrorCodes) {
    exit(Int32(code.rawValue))
}


func path(item: String) throws -> String {
    func extract() -> String {
        if item.pathExtension == "swift" {
            print("handle swift file")
            return item.stringByDeletingLastPathComponent
        }
        else {
            return item
        }
    }
    
    let path = extract().stringByStandardizingPath

    var isDirectory: ObjCBool = false
    if NSFileManager.defaultManager().fileExistsAtPath(path, isDirectory: &isDirectory) {
        print("isDirectory: \(isDirectory)")
        return path
    }

    throw ErrorCodes.PathNotFound
}

func filesAtPath(path: String) -> [String] {
    let items: [String] = {
        do {
            return try NSFileManager.defaultManager().contentsOfDirectoryAtPath(path)
        }
        catch {
            return []
        }
    }()
    
    return items
        .filter() { $0 != ".apous.swift" }
        .map() { path.stringByAppendingPathComponent($0) }
}


let arguments = NSProcessInfo.processInfo().arguments
if arguments.count != 2 {
    printUsage()
    exit(.InvalidUsage)
}

let p = try path(arguments[1])

let files = filesAtPath(p)

var script = ""

for f in files {
    script += try "// file: \(f)\n" + String(contentsOfFile: f, encoding: NSUTF8StringEncoding) + "\n"
}

let scriptPath = p.stringByAppendingPathComponent(".apous.swift")
try script.writeToFile(scriptPath, atomically: true, encoding: NSUTF8StringEncoding)


var swift = NSTask()
swift.launchPath = "/usr/bin/swift"
swift.arguments = [scriptPath]
swift.standardOutput = NSFileHandle.fileHandleWithStandardOutput()
swift.standardError = NSFileHandle.fileHandleWithStandardError()
swift.launch()
swift.waitUntilExit()