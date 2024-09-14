// Adapted from https://github.com/CommanderBubble/sha1 @ 356ab4f3df3c1573a3a7a56f7181f63616e495a6

// The MIT License (MIT)
//
// Copyright (c) 2015 Michael Lloyd
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

internal struct SHA1 {
    public static let blockSize = 64
    public static let digestSize = 20

    var h = (UInt32.zero, UInt32.zero, UInt32.zero, UInt32.zero, UInt32.zero)
    /// Accumulates bytes until having a complete block to process
    var block = [UInt8]()
    var messageLength: UInt64 = 0

    public init() {
        block.reserveCapacity(Self.blockSize)
        reset()
    }

    public static func get(_ input: [UInt8]) -> [UInt8] {
        var sha1 = SHA1()
        sha1.process(input)
        return sha1.finalize()
    }

    public mutating func process<Bytes: Sequence>(_ input: Bytes) where Bytes.Element == UInt8 {
        for byte in input {
            block.append(byte)
            messageLength += 1
            if block.count == Self.blockSize {
                processBlock()
                block.removeAll()
            }
        }
    }

    public mutating func reset() {
        h = (0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476, 0xc3d2e1f0)
        block.removeAll()
        messageLength = 0
    }

    public mutating func finalize() -> [UInt8] {
        assert(block.count < Self.blockSize)
        block.append(0x80) // Begin padding

        // Pad until we have exactly 8 bytes left to write the message length
        while block.count != Self.blockSize - 8 {
            if block.count == Self.blockSize {
                processBlock()
                block.removeAll()
            }
            block.append(0x00)
        }

        // Append message length
        Self.appendBigEndianUInt32(&block, UInt32((messageLength >> 29) & 0xFFFFFFFF))
        Self.appendBigEndianUInt32(&block, UInt32((messageLength & 0x1FFFFFFF) << 3))
        processBlock()
        block.removeAll()

        // copy the digest bytes
        var digest = [UInt8]()
        Self.appendBigEndianUInt32(&digest, h.0)
        Self.appendBigEndianUInt32(&digest, h.1)
        Self.appendBigEndianUInt32(&digest, h.2)
        Self.appendBigEndianUInt32(&digest, h.3)
        Self.appendBigEndianUInt32(&digest, h.4)

        reset()

        return digest
    }

    private mutating func processBlock() {
        // copy and expand the message block
        var W = [UInt32](repeating: 0, count: 80)
        for t in 0..<16 {
            W[t] = (UInt32(block[t * 4]) << 24)
                | (UInt32(block[t * 4 + 1]) << 16)
                | (UInt32(block[t * 4 + 2]) << 8)
                | UInt32(block[t * 4 + 3])
        }

        for t in 16..<80 {
            W[t] = Self.rotateBitsLeft(W[t - 3] ^ W[t - 8] ^ W[t - 14] ^ W[t - 16], 1)
        }

        // main loop
        var a = h.0, b = h.1, c = h.2, d = h.3, e = h.4
        for t in 0..<80 {
            let K: UInt32, f: UInt32
            if (t < 20) {
                K = 0x5a827999
                f = (b & c) | ((b ^ 0xFFFFFFFF) & d) //TODO: try using ~
            } else if (t < 40) {
                K = 0x6ed9eba1
                f = b ^ c ^ d
            } else if (t < 60) {
                K = 0x8f1bbcdc
                f = (b & c) | (b & d) | (c & d)
            } else {
                K = 0xca62c1d6
                f = b ^ c ^ d
            }

            let temp = Self.rotateBitsLeft(a, 5) &+ f &+ e &+ W[t] &+ K
            e = d
            d = c
            c = Self.rotateBitsLeft(b, 30)
            b = a
            a = temp
        }

        // add variables
        h = (h.0 &+ a, h.1 &+ b, h.2 &+ c, h.3 &+ d, h.4 &+ e)
    }

    private static func rotateBitsLeft(_ data: UInt32, _ shift_bits: UInt32) -> UInt32 {
        (data << shift_bits) | (data >> (32 - shift_bits))
    }

    // Save a 32-bit unsigned integer to memory, in big-endian order
    private static func appendBigEndianUInt32(_ bytes: inout [UInt8], _ num: UInt32) {
        bytes.append(UInt8((num >> 24) & 0xFF))
        bytes.append(UInt8((num >> 16) & 0xFF))
        bytes.append(UInt8((num >> 8) & 0xFF))
        bytes.append(UInt8((num >> 0) & 0xFF))
    }
}