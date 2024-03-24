import Foundation

// MARK: - StatisticServiceProtocol
protocol StatisticService {
    func store(correct count: Int, total amount: Int)
    func updateGameStats(isCorrect: Bool)
    func resetGameStats()
    
    var totalAccuracy: Double { get }
    var gamesCount: Int { get }
    var bestGame: GameRecord { get }
}
