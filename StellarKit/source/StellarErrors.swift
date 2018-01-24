//
//  StellarErrors.swift
//  StellarKit
//
//  Created by Kin Foundation
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import Foundation

public enum StellarError: Error {
    case missingAccount
    case missingPublicKey
    case missingHash
    case missingSequence
    case missingBalance
    case urlEncodingFailed
    case dataEncodingFailed
    case signingFailed
    case destinationNotReadyForAsset (Error, Asset)
    case parseError (Data?)
    case unknownError ([String: Any]?)
}

public enum TransactionError: Int32, Error {
    case txFAILED = -1               // one of the operations failed (none were applied)

    case txTOO_EARLY = -2            // ledger closeTime before minTime
    case txTOO_LATE = -3             // ledger closeTime after maxTime
    case txMISSING_OPERATION = -4    // no operation was specified
    case txBAD_SEQ = -5              // sequence number does not match source account

    case txBAD_AUTH = -6             // too few valid signatures / wrong network
    case txINSUFFICIENT_BALANCE = -7 // fee would bring account below reserve
    case txNO_ACCOUNT = -8           // source account not found
    case txINSUFFICIENT_FEE = -9     // fee is too small
    case txBAD_AUTH_EXTRA = -10      // unused signatures attached to transaction
    case txINTERNAL_ERROR = -11      // an unknown error occured
}

public enum CreateAccountError: Int32, Error {
    case CREATE_ACCOUNT_MALFORMED = -1     // invalid destination
    case CREATE_ACCOUNT_UNDERFUNDED = -2   // not enough funds in source account
    case CREATE_ACCOUNT_LOW_RESERVE = -3   // would create an account below the min reserve
    case CREATE_ACCOUNT_ALREADY_EXIST = -4 // account already exists
}

public enum PaymentError: Int32, Error {
    case PAYMENT_MALFORMED = -1          // bad input
    case PAYMENT_UNDERFUNDED = -2        // not enough funds in source account
    case PAYMENT_SRC_NO_TRUST = -3       // no trust line on source account
    case PAYMENT_SRC_NOT_AUTHORIZED = -4 // source not authorized to transfer
    case PAYMENT_NO_DESTINATION = -5     // destination account does not exist
    case PAYMENT_NO_TRUST = -6           // destination missing a trust line for asset
    case PAYMENT_NOT_AUTHORIZED = -7     // destination not authorized to hold asset
    case PAYMENT_LINE_FULL = -8          // destination would go above their limit
    case PAYMENT_NO_ISSUER = -9          // missing issuer on asset
}

func errorFromResponse(response: [String: Any]) -> Error? {
    let dict: [String: Any]
    if let extras = response["extras"] as? [String: Any] {
        dict = extras
    } else {
        dict = response
    }

    if
        let resultXDRStr = dict["result_xdr"] as? String,
        var resultXDRData = Data(base64Encoded: resultXDRStr) {
        let result = TransactionResult(xdrData: &resultXDRData, count: 0)
        switch result.result {
        case .txSUCCESS:
            break
        case .txERROR (let code):
            if let transactionError = TransactionError(rawValue: code) {
                return transactionError
            }

            return StellarError.unknownError(response)
        case .txFAILED (let opResults):
            guard let opResult = opResults.first else {
                return StellarError.unknownError(response)
            }

            switch opResult {
            case .opINNER(let tr):
                switch tr {
                case .PAYMENT (let paymentResult):
                    switch paymentResult {
                    case .failure (let code):
                        if let paymentError = PaymentError(rawValue: code) {
                            return paymentError
                        }

                        return StellarError.unknownError(response)

                    default:
                        break
                    }
                case .CREATE_ACCOUNT (let createAccountResult):
                    switch createAccountResult {
                    case .failure (let code):
                        if let createAccountError = CreateAccountError(rawValue: code) {
                            return createAccountError
                        }

                        return StellarError.unknownError(response)

                    default:
                        break
                    }

                default:
                    break
                }

            default:
                break
            }
        }
    } else {
        return StellarError.unknownError(response)
    }

    return nil
}
