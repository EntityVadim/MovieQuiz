import Foundation

class StatisticServiceImplementation: StatisticService {
    private let userDefaults = UserDefaults.standard
    
    private enum Keys: String {
        case correct, total, bestGame, gamesCount, totalAccuracy
    }
    
    func store(correct count: Int, total amount: Int) {
        userDefaults.set(count, forKey: Keys.correct.rawValue)
        userDefaults.set(amount, forKey: Keys.total.rawValue)
        let newGameRecord = GameRecord(correct: count, total: amount, date: Date())
        var currentBestGame = bestGame
        if newGameRecord.isBetterThan(currentBestGame) {
            currentBestGame = newGameRecord
            bestGame = currentBestGame
        }
    }

    var totalAccuracy: Double {
        get {
            return userDefaults.double(forKey: Keys.totalAccuracy.rawValue)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.totalAccuracy.rawValue)
        }
    }
    
    var gamesCount: Int {
        get {
            return userDefaults.integer(forKey: Keys.gamesCount.rawValue)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.gamesCount.rawValue)
        }
    }
    
    var bestGame: GameRecord {
        get {
            guard let data = userDefaults.data(forKey: Keys.bestGame.rawValue),
                  let record = try? JSONDecoder().decode(GameRecord.self, from: data) else {
                return GameRecord(correct: 0, total: 0, date: Date())
            }
            return record
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else {
                print("Невозможно сохранить результат")
                return
            }
            userDefaults.set(data, forKey: Keys.bestGame.rawValue)
        }
    }
    
    func updateGameStats(isCorrect: Bool) {
        gamesCount += 1
        if isCorrect {
            totalAccuracy = (totalAccuracy * Double(gamesCount) + 1) / Double(gamesCount + 1)
        }
    }
    
    func resetGameStats() {
        totalAccuracy = 0
        gamesCount = 0
    }
}
