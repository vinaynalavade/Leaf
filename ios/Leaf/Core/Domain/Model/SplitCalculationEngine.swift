import Foundation

public struct CustomSplitValidation: Hashable, Sendable {
    public let isValid: Bool
    public let allocatedAmount: Amount
    public let remainingAmount: Amount
    public let overallocatedAmount: Amount
    public let errorMessage: String?

    public init(
        isValid: Bool,
        allocatedAmount: Amount,
        remainingAmount: Amount,
        overallocatedAmount: Amount,
        errorMessage: String? = nil
    ) {
        self.isValid = isValid
        self.allocatedAmount = allocatedAmount
        self.remainingAmount = remainingAmount
        self.overallocatedAmount = overallocatedAmount
        self.errorMessage = errorMessage
    }
}

public struct ParticipantShareDetail: Hashable, Sendable {
    public let participantName: String
    public let itemizedShare: Amount
    public let sharedRemainingShare: Amount
    public let totalShare: Amount
    public let itemBreakdown: [(name: String, amount: Amount)]

    public init(
        participantName: String,
        itemizedShare: Amount,
        sharedRemainingShare: Amount,
        totalShare: Amount,
        itemBreakdown: [(name: String, amount: Amount)] = []
    ) {
        self.participantName = participantName
        self.itemizedShare = itemizedShare
        self.sharedRemainingShare = sharedRemainingShare
        self.totalShare = totalShare
        self.itemBreakdown = itemBreakdown
    }

    public static func == (lhs: ParticipantShareDetail, rhs: ParticipantShareDetail) -> Bool {
        lhs.participantName == rhs.participantName &&
        lhs.itemizedShare == rhs.itemizedShare &&
        lhs.sharedRemainingShare == rhs.sharedRemainingShare &&
        lhs.totalShare == rhs.totalShare &&
        lhs.itemBreakdown.count == rhs.itemBreakdown.count
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(participantName)
        hasher.combine(itemizedShare)
        hasher.combine(sharedRemainingShare)
        hasher.combine(totalShare)
    }
}

public struct ItemizedSplitCalculationResult: Sendable {
    public let isValid: Bool
    public let totalBill: Amount
    public let totalAllocatedAmount: Amount
    public let itemizedTotalAmount: Amount
    public let unallocatedRemainingAmount: Amount
    public let overallocatedAmount: Amount
    public let isOverallocated: Bool
    public let isUnderallocated: Bool
    public let participantShares: [String: Amount]
    public let participantDetails: [ParticipantShareDetail]
    public let baselineEqualShare: Amount
    public let errorMessage: String?

    public init(
        isValid: Bool,
        totalBill: Amount,
        totalAllocatedAmount: Amount,
        itemizedTotalAmount: Amount,
        unallocatedRemainingAmount: Amount,
        overallocatedAmount: Amount,
        isOverallocated: Bool,
        isUnderallocated: Bool,
        participantShares: [String: Amount],
        participantDetails: [ParticipantShareDetail],
        baselineEqualShare: Amount = .zero,
        errorMessage: String? = nil
    ) {
        self.isValid = isValid
        self.totalBill = totalBill
        self.totalAllocatedAmount = totalAllocatedAmount
        self.itemizedTotalAmount = itemizedTotalAmount
        self.unallocatedRemainingAmount = unallocatedRemainingAmount
        self.overallocatedAmount = overallocatedAmount
        self.isOverallocated = isOverallocated
        self.isUnderallocated = isUnderallocated
        self.participantShares = participantShares
        self.participantDetails = participantDetails
        self.baselineEqualShare = baselineEqualShare
        self.errorMessage = errorMessage
    }
}

/// Pure calculation engine for Leaf's Split & Collect module.
/// Operates strictly on integer currency subunits (paise / cents) with zero floating-point error.
public enum SplitCalculationEngine {

    /// Calculates equal shares among all participants with deterministic penny / paisa reconciliation.
    ///
    /// For example, ₹100.00 (10,000 paise) divided among 3 participants:
    /// - Participant 0: 3,334 paise (₹33.34)
    /// - Participant 1: 3,333 paise (₹33.33)
    /// - Participant 2: 3,333 paise (₹33.33)
    /// Sum of shares: 3334 + 3333 + 3333 = 10,000 paise (₹100.00) exactly.
    public static func calculateEqualSplit(
        totalAmount: Amount,
        participants: [String],
        payerName: String = "Me",
        currentUserName: String = "Me"
    ) -> [SplitParticipant] {
        if participants.isEmpty || totalAmount.subunits <= 0 {
            return []
        }

        let count = Int64(participants.count)
        let baseSubunits = totalAmount.subunits / count
        let remainder = totalAmount.subunits % count

        return participants.enumerated().map { index, name in
            let extra: Int64 = Int64(index) < remainder ? 1 : 0
            let finalSubunits = baseSubunits + extra
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let isCurrentUser = trimmedName.caseInsensitiveCompare(currentUserName) == .orderedSame ||
                trimmedName.caseInsensitiveCompare("Me") == .orderedSame ||
                trimmedName.caseInsensitiveCompare("You") == .orderedSame

            return SplitParticipant(
                name: trimmedName,
                isCurrentUser: isCurrentUser,
                amount: Amount(subunits: finalSubunits),
                settlementStatus: .pending
            )
        }
    }

    /// Calculates the share of an individual item for a specific participant.
    public static func calculateItemShareForParticipant(item: SplitItem, participantName: String) -> Amount {
        let matches = item.participantNames.contains { $0.caseInsensitiveCompare(participantName) == .orderedSame }
        if !matches { return .zero }
        if item.amount.subunits <= 0 { return .zero }

        if item.isCustomAllocation {
            if let matchedKey = item.customAllocations.keys.first(where: { $0.caseInsensitiveCompare(participantName) == .orderedSame }) {
                return item.customAllocations[matchedKey] ?? .zero
            }
            return .zero
        }

        let count = Int64(item.participantNames.count)
        if count == 0 { return .zero }

        guard let index = item.participantNames.firstIndex(where: { $0.caseInsensitiveCompare(participantName) == .orderedSame }) else {
            return .zero
        }

        let baseSubunits = item.amount.subunits / count
        let remainder = item.amount.subunits % count
        let extra: Int64 = Int64(index) < remainder ? 1 : 0
        return Amount(subunits: baseSubunits + extra)
    }

    /// Evaluates itemized custom bill splitting with item consumers, custom allocation,
    /// base/shared bill distribution, and exact penny/paisa reconciliation.
    public static func calculateItemizedSplit(
        totalBill: Amount,
        participants: [String],
        items: [SplitItem],
        sharedRemainingParticipants: [String]
    ) -> ItemizedSplitCalculationResult {
        var seen = Set<String>()
        var distinctParticipants: [String] = []
        for p in participants {
            let trimmed = p.trimmingCharacters(in: .whitespacesAndNewlines)
            let lower = trimmed.lowercased()
            if !seen.contains(lower) && !trimmed.isEmpty {
                seen.insert(lower)
                distinctParticipants.append(trimmed)
            }
        }

        let baselineEqualShare: Amount
        if !distinctParticipants.isEmpty && totalBill.subunits > 0 {
            baselineEqualShare = Amount(subunits: totalBill.subunits / Int64(distinctParticipants.count))
        } else {
            baselineEqualShare = .zero
        }

        if distinctParticipants.isEmpty || totalBill.subunits <= 0 {
            var emptyShares: [String: Amount] = [:]
            var emptyDetails: [ParticipantShareDetail] = []
            for p in distinctParticipants {
                emptyShares[p] = .zero
                emptyDetails.append(ParticipantShareDetail(participantName: p, itemizedShare: .zero, sharedRemainingShare: .zero, totalShare: .zero))
            }
            return ItemizedSplitCalculationResult(
                isValid: false,
                totalBill: totalBill,
                totalAllocatedAmount: .zero,
                itemizedTotalAmount: .zero,
                unallocatedRemainingAmount: totalBill,
                overallocatedAmount: .zero,
                isOverallocated: false,
                isUnderallocated: totalBill.subunits > 0,
                participantShares: emptyShares,
                participantDetails: emptyDetails,
                baselineEqualShare: baselineEqualShare,
                errorMessage: totalBill.subunits <= 0 ? "Please enter an amount greater than 0." : "Please add participants."
            )
        }

        var participantItemSubunits: [String: Int64] = [:]
        var participantBreakdowns: [String: [(name: String, amount: Amount)]] = [:]
        for p in distinctParticipants {
            participantItemSubunits[p] = 0
            participantBreakdowns[p] = []
        }

        var totalItemsSubunits: Int64 = 0

        // 1. Calculate each item's shares
        for item in items {
            let itemSubunits = item.amount.subunits
            if itemSubunits <= 0 { continue }

            let validConsumers = item.participantNames
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { consumer in distinctParticipants.contains { $0.caseInsensitiveCompare(consumer) == .orderedSame } }

            if validConsumers.isEmpty { continue }

            if item.isCustomAllocation {
                var customTotal: Int64 = 0
                for consumer in validConsumers {
                    guard let pName = distinctParticipants.first(where: { $0.caseInsensitiveCompare(consumer) == .orderedSame }) else { continue }
                    let customSubunits = item.customAllocations.first(where: { $0.key.caseInsensitiveCompare(consumer) == .orderedSame })?.value.subunits ?? 0
                    participantItemSubunits[pName] = (participantItemSubunits[pName] ?? 0) + customSubunits
                    customTotal += customSubunits
                    if customSubunits > 0 {
                        let itemName = item.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Item" : item.name
                        participantBreakdowns[pName]?.append((name: itemName, amount: Amount(subunits: customSubunits)))
                    }
                }
                totalItemsSubunits += (customTotal > 0 ? customTotal : itemSubunits)
            } else {
                totalItemsSubunits += itemSubunits
                let count = Int64(validConsumers.count)
                let base = itemSubunits / count
                let rem = itemSubunits % count

                for (idx, consumer) in validConsumers.enumerated() {
                    guard let pName = distinctParticipants.first(where: { $0.caseInsensitiveCompare(consumer) == .orderedSame }) else { continue }
                    let share = base + (Int64(idx) < rem ? 1 : 0)
                    participantItemSubunits[pName] = (participantItemSubunits[pName] ?? 0) + share
                    let itemName = item.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Item" : item.name
                    participantBreakdowns[pName]?.append((name: itemName, amount: Amount(subunits: share)))
                }
            }
        }

        let diff = totalBill.subunits - totalItemsSubunits
        let isOverallocated = diff < 0
        let overallocatedAmount = isOverallocated ? Amount(subunits: -diff) : .zero

        var participantSharedSubunits: [String: Int64] = [:]
        for p in distinctParticipants {
            participantSharedSubunits[p] = 0
        }

        let validSharedParticipants = sharedRemainingParticipants
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { p in distinctParticipants.contains { $0.caseInsensitiveCompare(p) == .orderedSame } }

        var remainingAfterDistribution = diff > 0 ? diff : 0

        // 2. Distribute remaining shared amount
        if diff > 0 && !validSharedParticipants.isEmpty {
            let count = Int64(validSharedParticipants.count)
            let base = diff / count
            let rem = diff % count

            for (idx, pName) in validSharedParticipants.enumerated() {
                guard let canonicalName = distinctParticipants.first(where: { $0.caseInsensitiveCompare(pName) == .orderedSame }) else { continue }
                let sharedShare = base + (Int64(idx) < rem ? 1 : 0)
                participantSharedSubunits[canonicalName] = sharedShare
            }
            remainingAfterDistribution = 0
        }

        let isUnderallocated = remainingAfterDistribution > 0
        let totalAllocatedSubunits = isOverallocated ? totalItemsSubunits : (totalItemsSubunits + (diff - remainingAfterDistribution))
        let isValid = !isOverallocated && !isUnderallocated && totalAllocatedSubunits == totalBill.subunits

        var participantShares: [String: Amount] = [:]
        var participantDetails: [ParticipantShareDetail] = []

        for p in distinctParticipants {
            let itemShare = participantItemSubunits[p] ?? 0
            let sharedShare = participantSharedSubunits[p] ?? 0
            let totalShare = itemShare + sharedShare
            participantShares[p] = Amount(subunits: totalShare)

            participantDetails.append(
                ParticipantShareDetail(
                    participantName: p,
                    itemizedShare: Amount(subunits: itemShare),
                    sharedRemainingShare: Amount(subunits: sharedShare),
                    totalShare: Amount(subunits: totalShare),
                    itemBreakdown: participantBreakdowns[p] ?? []
                )
            )
        }

        let errorMessage: String?
        if isOverallocated {
            errorMessage = "Overallocated: Items exceed total bill by \(overallocatedAmount.format(currency: .inr))"
        } else if isUnderallocated {
            errorMessage = "Remaining to allocate: \(Amount(subunits: remainingAfterDistribution).format(currency: .inr))"
        } else {
            errorMessage = nil
        }

        return ItemizedSplitCalculationResult(
            isValid: isValid,
            totalBill: totalBill,
            totalAllocatedAmount: Amount(subunits: totalAllocatedSubunits),
            itemizedTotalAmount: Amount(subunits: totalItemsSubunits),
            unallocatedRemainingAmount: Amount(subunits: remainingAfterDistribution),
            overallocatedAmount: overallocatedAmount,
            isOverallocated: isOverallocated,
            isUnderallocated: isUnderallocated,
            participantShares: participantShares,
            participantDetails: participantDetails,
            baselineEqualShare: baselineEqualShare,
            errorMessage: errorMessage
        )
    }

    /// Validates that manually entered custom shares exactly reconcile with the total expense amount.
    public static func validateCustomSplit(
        totalAmount: Amount,
        allocatedSubunits: Int64
    ) -> CustomSplitValidation {
        let diff = totalAmount.subunits - allocatedSubunits
        if diff == 0 {
            return CustomSplitValidation(
                isValid: true,
                allocatedAmount: Amount(subunits: allocatedSubunits),
                remainingAmount: .zero,
                overallocatedAmount: .zero,
                errorMessage: nil
            )
        } else if diff > 0 {
            return CustomSplitValidation(
                isValid: false,
                allocatedAmount: Amount(subunits: allocatedSubunits),
                remainingAmount: Amount(subunits: diff),
                overallocatedAmount: .zero,
                errorMessage: "Remaining: \(Amount(subunits: diff).format(currency: .inr))"
            )
        } else {
            return CustomSplitValidation(
                isValid: false,
                allocatedAmount: Amount(subunits: allocatedSubunits),
                remainingAmount: .zero,
                overallocatedAmount: Amount(subunits: -diff),
                errorMessage: "Overallocated: \(Amount(subunits: -diff).format(currency: .inr))"
            )
        }
    }

    /// Checks if all non-payer participants have the exact same share amount.
    public static func hasEqualNonPayerShares(participants: [SplitParticipant]) -> Bool {
        let nonPayers = participants.filter { !$0.isCurrentUser }
        if nonPayers.isEmpty { return false }
        let distinctAmounts = Set(nonPayers.map { $0.amount.subunits })
        return distinctAmounts.count == 1
    }

    /// Calculates shares based on specified percentages per participant, reconciling pennies/paise.
    public static func calculatePercentageSplit(
        totalAmount: Amount,
        participants: [(name: String, percentage: Double)],
        payerName: String = "Me",
        currentUserName: String = "Me"
    ) -> [SplitParticipant] {
        if participants.isEmpty || totalAmount.subunits <= 0 {
            return []
        }

        var baseAllocations: [Int64] = []
        var totalAllocated: Int64 = 0

        for (_, pct) in participants {
            let portion = Int64(floor(Double(totalAmount.subunits) * (pct / 100.0)))
            baseAllocations.append(portion)
            totalAllocated += portion
        }

        var remainder = totalAmount.subunits - totalAllocated

        // Distribute remaining subunits 1-by-1 to participants
        var index = 0
        while remainder > 0 && index < baseAllocations.count {
            baseAllocations[index] += 1
            remainder -= 1
            index += 1
        }

        return participants.enumerated().map { idx, item in
            let trimmedName = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
            let isCurrentUser = trimmedName.caseInsensitiveCompare(currentUserName) == .orderedSame ||
                trimmedName.caseInsensitiveCompare("Me") == .orderedSame ||
                trimmedName.caseInsensitiveCompare("You") == .orderedSame

            return SplitParticipant(
                name: trimmedName,
                isCurrentUser: isCurrentUser,
                amount: Amount(subunits: baseAllocations[idx]),
                settlementStatus: .pending
            )
        }
    }

    /// Creates participants for direct custom amount entry.
    public static func calculateExactCustomSplit(
        totalAmount: Amount,
        participants: [(name: String, amount: Amount)],
        payerName: String = "Me",
        currentUserName: String = "Me"
    ) -> [SplitParticipant] {
        return participants.map { item in
            let trimmedName = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
            let isCurrentUser = trimmedName.caseInsensitiveCompare(currentUserName) == .orderedSame ||
                trimmedName.caseInsensitiveCompare("Me") == .orderedSame ||
                trimmedName.caseInsensitiveCompare("You") == .orderedSame

            return SplitParticipant(
                name: trimmedName,
                isCurrentUser: isCurrentUser,
                amount: item.amount,
                settlementStatus: .pending
            )
        }
    }
}

