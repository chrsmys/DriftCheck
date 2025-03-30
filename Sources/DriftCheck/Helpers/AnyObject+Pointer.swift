//
//  AnyObject+Pointer.swift
//  DriftCheck
//
//  Created by Chris Mays on 3/26/25.
//

import Foundation

func hexAddress(_ obj: AnyObject) -> String {
    "\(Unmanaged.passUnretained(obj).toOpaque())".replacingOccurrences(of: "^0x0+", with: "0x", options: .regularExpression)
}
