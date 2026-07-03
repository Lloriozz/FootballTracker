import XCTest
@testable import FootballTracker

@MainActor
final class TeamsTabViewModelTests: XCTestCase {
    
    var viewModel: TeamsTabViewModel!
    var mockTeamRepo: MockTeamRepository!
    var mockLeagueRepo: MockLeagueRepository!
    
    override func setUp() async throws {
        try await super.setUp()
        mockTeamRepo = MockTeamRepository()
        mockLeagueRepo = MockLeagueRepository()
        
        viewModel = TeamsTabViewModel(
            teamRepo: mockTeamRepo,
            leagueRepo: mockLeagueRepo
        )
    }
    
    override func tearDown() async throws {
        viewModel = nil
        mockTeamRepo = nil
        mockLeagueRepo = nil
        try await super.tearDown()
    }
    
    func testLoadLeagues() async {
        // Given
        let leagues = [LeagueInfo(id: "1", name: "Premier League", country: "England", icon: nil, flag: nil)]
        mockLeagueRepo.listLeaguesResult = .success(leagues)
        
        // When
        await viewModel.loadLeagues()
        
        // Then
        XCTAssertEqual(viewModel.leagues.count, 1)
        XCTAssertEqual(viewModel.leagues.first?.name, "Premier League")
    }
    
    func testLoadTeamsForLeague() async {
        // Given
        let teams = [FootballTeam(id: "1", name: "Arsenal", country: "England", logo: nil, shortName: "ARS", emblem: "emblem")]
        mockTeamRepo.listTeamsResult = .success(teams)
        
        // When
        await viewModel.loadTeams(for: "1")
        
        // Then
        XCTAssertEqual(viewModel.leagueTeams["1"]?.count, 1)
        XCTAssertEqual(viewModel.leagueTeams["1"]?.first?.name, "Arsenal")
    }
    
    func testSearchTeamsFiltersOutYouthAndWomenTeams() async {
        // Given
        let teams = [
            FootballTeam(id: "1", name: "Arsenal", country: "England", logo: nil, shortName: "ARS", emblem: ""),
            FootballTeam(id: "2", name: "Arsenal U21", country: "England", logo: nil, shortName: "ARS21", emblem: ""),
            FootballTeam(id: "3", name: "Arsenal Women", country: "England", logo: nil, shortName: "ARS W", emblem: ""),
            FootballTeam(id: "4", name: "Arsenal B", country: "England", logo: nil, shortName: "ARS B", emblem: "")
        ]
        mockTeamRepo.searchTeamsResult = .success(teams)
        
        viewModel.searchQuery = "Arsenal"
        
        // When
        viewModel.onSearchQueryChanged()
        
        // Wait for debounce and search task to complete
        try? await Task.sleep(for: .milliseconds(500))
        
        // Then
        XCTAssertEqual(viewModel.searchResults.count, 1)
        XCTAssertEqual(viewModel.searchResults.first?.name, "Arsenal")
    }
}
