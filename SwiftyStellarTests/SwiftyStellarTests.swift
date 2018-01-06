//
//  SwiftyStellarTests.swift
//  SwiftyStellarTests
//
//  Created by Avi Shevin on 04/01/2018.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import XCTest
@testable import SwiftyStellar
@testable import Sodium

class SwiftyStellarTests: XCTestCase {
    let stellar = Stellar(baseURL: URL(string: "https://horizon-testnet.stellar.org")!)

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func keyPair() -> Sign.KeyPair {
        let publicKey = Data(base64Encoded: "gQpeQySd0WEDInBglocy8+qfLsWmvL7NPo94NO+PejA=")!
        let secretKey = Data(base64Encoded: "r8r3grK5KYpWo3oeTOHi13FVVVLYKZwzD3vdD1tQO+GBCl5DJJ3RYQMicGCWhzLz6p8uxaa8vs0+j3g07496MA==")!

        return Sign.KeyPair(publicKey: publicKey, secretKey: secretKey)
    }
    
    func testPayment() {
        let e = expectation(description: "")

        let destination = "GDGPI2AN6NVG2JMV7G7OV6XDXTD4NJ6TPL3RTLB3CJ36YWBXXSVBKS6K"

        stellar.payment(source: keyPair().publicKey,
                        destination: base32KeyToData(key: destination),
                        amount: Int64.max, //1229,
                        signingKey: keyPair().secretKey) { txHash, error in
                            defer {
                                e.fulfill()
                            }

                            if let error = error as? StellarError {
                                switch error {
                                case .unknownError (let data):
                                    if
                                        let data = data,
                                        let jsonOpt = try? JSONSerialization.jsonObject(with: data,
                                                                                    options: []) as? [String: Any],
                                        let json = jsonOpt {
                                        print(json)
                                    }
                                default:
                                    break
                                }

                                print("Error: \(error)")
                            }

                            guard let txHash = txHash else {
                                return
                            }

                            print(txHash)
        }

        wait(for: [e], timeout: 10)
    }

    func testBalance() {
        let e = expectation(description: "")

        stellar.balance(account: keyPair().publicKey) { amount, error in
            defer {
                e.fulfill()
            }

            if let error = error {
                print("Error: \(error)")
            }

            guard let amount = amount else {
                return
            }

            print(amount)

        }

        wait(for: [e], timeout: 10)
    }

    func test1() {
        let keys = Sodium().sign.keyPair()!

        let pk = PublicKey.PUBLIC_KEY_TYPE_ED25519(FixedLengthDataWrapper(keys.publicKey))

        print(pk.toXDR().base64EncodedString())

        print(keys.publicKey.base64EncodedString())
        print(keys.secretKey.base64EncodedString())
    }

    func test2() {
        let keys = keyPair()

        print(keys.publicKey.crc16)

        print(publicKeyToBase32(keys.publicKey))
        print(base32KeyToData(key: "GCAQUXSDESO5CYIDEJYGBFUHGLZ6VHZOYWTLZPWNH2HXQNHPR55DA6MT").hexString)
    }
}
