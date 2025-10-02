//
//  Bundle.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 02.10.25.
//

import SwiftUI

// Thanks to Andrew: https://stackoverflow.com/a/68912269
extension Bundle {
    public var appBuild: String          { getInfo("CFBundleShortVersionString") }
    fileprivate func getInfo(_ str: String) -> String { infoDictionary?[str] as? String ?? "Unknown" }
}
