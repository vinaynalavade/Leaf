import Foundation

/// UseCase responsible for validating and inserting or updating a SplitGroup.
public final class SaveSplitGroupUseCase: Sendable {

    private let splitRepository: SplitRepositoryProtocol

    public init(splitRepository: SplitRepositoryProtocol) {
        self.splitRepository = splitRepository
    }

    public enum GroupError: LocalizedError {
        case emptyName

        public var errorDescription: String? {
            switch self {
            case .emptyName: return "Group name cannot be blank."
            }
        }
    }

    @discardableResult
    public func execute(
        id: Int64 = 0,
        name: String,
        iconName: String = "person.3.fill",
        colorHex: String = "#10B981"
    ) async throws -> Int64 {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            throw GroupError.emptyName
        }

        let group = SplitGroup(
            id: id,
            name: trimmed,
            iconName: iconName,
            colorHex: colorHex
        )

        if id > 0 {
            try await splitRepository.updateSplitGroup(group)
            return id
        } else {
            return try await splitRepository.insertSplitGroup(group)
        }
    }
}

