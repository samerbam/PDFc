//
//  Units.swift
//  PDFc
//
//  Created by Sam Ryan on 2021-07-23.
//
// Source: https://gist.github.com/fethica/52ef6d842604e416ccd57780c6dd28e6

import Foundation

public struct Units {
  
  public let bytes: Int64
  
  public var kilobytes: Double {
    return Double(bytes) / 1_024
  }
  
  public var megabytes: Double {
    return kilobytes / 1_024
  }
  
  public var gigabytes: Double {
    return megabytes / 1_024
  }
  
  public init(bytes: Int64) {
    self.bytes = bytes
  }
  
  public func getReadableUnit() -> String {
    
    switch bytes {
    case 0..<1_024:
      return "\(bytes) bytes"
    case 1_024..<(1_024 * 1_024):
      return "\(String(format: "%.2f", kilobytes)) kb"
    case 1_024..<(1_024 * 1_024 * 1_024):
      return "\(String(format: "%.2f", megabytes)) mb"
    case (1_024 * 1_024 * 1_024)...Int64.max:
      return "\(String(format: "%.2f", gigabytes)) gb"
    case (-1_024)..<0:
      return "\(bytes) bytes"
    case (-1_024 * 1_024)..<(-1_024):
      return "\(String(format: "%.2f", kilobytes)) kb"
    case (-1_024 * 1_024 * 1_024)..<(-1_024):
      return "\(String(format: "%.2f", megabytes)) mb"
    case (-Int64.max)...(-1_024 * 1_024 * 1_024):
      return "\(String(format: "%.2f", gigabytes)) gb"
    default:
      return "\(bytes) bytes"
    }
  }
}
