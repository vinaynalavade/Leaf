import Foundation

public enum PaymentMethod: String, Codable, CaseIterable, Sendable, Identifiable {
    public var id: String { rawValue }
    case cash = "CASH"
    case account = "ACCOUNT"
    case upi = "UPI"
    case card = "CARD"
    case cheque = "CHEQUE"
    case wallet = "WALLET"
    case unknown = "UNKNOWN"

    public static var bankTransfer: PaymentMethod { .account }

    public var displayName: String {
        switch self {
        case .cash: return "Cash"
        case .account: return "Account"
        case .upi: return "UPI"
        case .card: return "Card"
        case .cheque: return "Cheque"
        case .wallet: return "Wallet"
        case .unknown: return "Unknown"
        }
    }

    public var mappedLedger: PaymentMethod {
        switch self {
        case .cash, .wallet:
            return .cash
        case .account, .upi, .card, .cheque, .unknown:
            return .account
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawString = try? container.decode(String.self)
        self = PaymentMethod.fromString(rawString)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    public static func fromString(_ raw: String?) -> PaymentMethod {
        guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return .unknown
        }
        let normalized = raw.uppercased().replacingOccurrences(of: " ", with: "_")
        switch normalized {
        case "CASH":
            return .cash
        case "ACCOUNT", "BANK_ACCOUNT", "BANK", "NET_BANKING", "ONLINE", "UPI", "CARD", "CREDIT_CARD", "DEBIT_CARD":
            return .account
        case "CHEQUE", "CHECK":
            return .cheque
        case "WALLET":
            return .wallet
        default:
            return .unknown
        }
    }
}


