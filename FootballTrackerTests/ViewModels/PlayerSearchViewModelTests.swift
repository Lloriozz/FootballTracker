import XCTest
@testable import FootballTracker

@MainActor
final class PlayerSearchViewModelTests: XCTestCase {
    
    var viewModel: PlayerSearchViewModel!
    var mockPlayerRepo: MockPlayerRepository!
    
    override func setUp() async throws {
        try await super.setUp()
        mockPlayerRepo = MockPlayerRepository()
        viewModel = PlayerSearchViewModel(playerRepo: mockPlayerRepo)
    }
    
    override func tearDown() async throws {
        viewModel = nil
        mockPlayerRepo = nil
        try await super.tearDown()
    }
    
    func testSearchPlayersSuccess() async {
        // Given
        let players = [
            Player(id: "1", name: "Lionel Messi", photo: nil, nationality: "Argentina", age: 36, injured: false, statistics: [])
        ]
        mockPlayerRepo.searchPlayersResult = .success(players)
        
        viewModel.searchQuery = "Messi"
        
        // When
        viewModel.onQueryChanged()
        
        // Wait for debounce (600ms) and search task
        try? await Task.sleep(for: .milliseconds(700))
        
        // Then
        if case .loaded(let results) = viewModel.state {
            XCTAssertEqual(results.count, 1)
            XCTAssertEqual(results.first?.name, "Lionel Messi")
        } else {
            XCTFail("Expected state to be .loaded, got \(viewModel.state)")
        }
    }
    
    func testSearchPlayersEmpty() async {
        // Given
        mockPlayerRepo.searchPlayersResult = .success([])
        viewModel.searchQuery = "UnknownPlayer"
        
        // When
        viewModel.onQueryChanged()
        
        // Wait for debounce and search task
        try? await Task.sleep(for: .milliseconds(700))
        
        // Then
        if case .empty = viewModel.state {
            // Success
        } else {
            XCTFail("Expected state to be .empty, got \(viewModel.state)")
        }
    }
    
    func testSearchPlayersError() async {
        // Given
        mockPlayerRepo.searchPlayersResult = .failure(URLError(.notConnectedToInternet))
        viewModel.searchQuery = "Messi"
        
        // When
        viewModel.onQueryChanged()
        
        // Wait for debounce and search task
        try? await Task.sleep(for: .milliseconds(700))
        
        // Then
        if case .error(let message) = viewModel.state {
            XCTAssertFalse(message.isEmpty)
        } else {
            XCTFail("Expected state to be .error, got \(viewModel.state)")
        }
    }
}
