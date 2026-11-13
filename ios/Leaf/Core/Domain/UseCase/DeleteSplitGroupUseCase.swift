import Foundation

/// UseCase responsible for deleting a SplitGroup.
public final class DeleteSplitGroupUseCase: Sendable {

    private let splitRepository: SplitRepositoryProtocol

    public init(splitRepository: SplitRepositoryProtocol) {
        self.splitRepository = splitRepository
    }

    public func execute(id: Int64) async throws {
        try await splitRepository.deleteSplitGroup(id: id)
    }
}

