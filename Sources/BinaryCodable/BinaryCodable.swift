// Copyright 2019-present the BinaryCodable authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Note: the types described below are based off - but distinct from - Swift's Codable family of APIs.

import Foundation

/**
 A type that can convert itself into and out of an external binary representation.
 */
public typealias BinaryCodable = BinaryDecodable & BinaryEncodable

/**
 A user-defined key for providing context during binary encoding and decoding.
 */
public typealias BinaryCodingUserInfoKey = String

extension String: BinaryCodable {
  public init(from decoder: BinaryDecoder) throws {
    var container = decoder.container(maxLength: nil)
    var valueContainer = container.nestedContainer(maxLength: Int(try container.decode(Int64.self)))
    guard let string = String(data: try valueContainer.decodeRemainder(), encoding: .utf8) else {
      throw BinaryEncodingError.incompatibleStringEncoding(.init(debugDescription: "String Decoding Failed"))
    }
    self = string
  }

  public func encode(to encoder: BinaryEncoder) throws {
    var container = encoder.container()

    guard let data = data(using: .utf8) else {
      throw BinaryEncodingError.incompatibleStringEncoding(.init(debugDescription: "String Encoding Failed"))
    }

    try container.encode(Int64(data.count))
    try container.encode(sequence: data)
  }
}

extension Optional: BinaryCodable where Wrapped: BinaryCodable {
  public init(from decoder: BinaryDecoder) throws {
    var container = decoder.container(maxLength: nil)

    let hasValue = try container.decode(UInt8.self)
    if hasValue != 0 {
      self = try container.decode(Wrapped.self)
    } else {
      self = nil
    }
  }

  public func encode(to encoder: BinaryEncoder) throws {
    var container = encoder.container()

    if let value = self {
      try container.encode(1 as UInt8)
      try container.encode(value)
    } else {
      try container.encode(0 as UInt8)
    }
  }
}

extension Array: BinaryCodable where Element: BinaryCodable {
  public init(from decoder: BinaryDecoder) throws {
    var container = decoder.container(maxLength: nil)

    let elementCount = try container.decode(Int64.self)
    
    self = []
    for _ in 0 ..< elementCount {
      append(try container.decode(Element.self))
    }
  }

  public func encode(to encoder: BinaryEncoder) throws {
    var container = encoder.container()

    try container.encode(Int64(count))
    for element in self {
      try container.encode(element)
    }
  }
}

extension UUID: BinaryCodable {
  public init(from decoder: BinaryDecoder) throws {
    var container = decoder.container(maxLength: 16)
    self = try container.decodeRemainder().withUnsafeBytes {
      NSUUID(uuidBytes: $0.bindMemory(to: UInt8.self).baseAddress)
    } as UUID
  }

  public func encode(to encoder: BinaryEncoder) throws {
    var container = encoder.container()
    try container.encode(sequence: withUnsafeBytes(of: uuid, { Data($0) }))
  }
}
