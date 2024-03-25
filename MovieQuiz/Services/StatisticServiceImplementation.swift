import Foundation

// MARK: - StatisticServiceImplementation
class StatisticServiceImplementation: StatisticService {
    private let userDefaults = UserDefaults.standard
    
    private enum Keys: String {
        case correct, total, bestGame, gamesCount, totalAccuracy
    }
    
    // MARK: - Public Methods
    func store(correct count: Int, total amount: Int) {
        self.correct += count
        self.total += amount
        let newGameRecord = GameRecord(correct: count, total: amount, date: Date())
        var currentBestGame = bestGame
        if newGameRecord.isBetterThan(currentBestGame) {
            currentBestGame = newGameRecord
            bestGame = currentBestGame
            userDefaults.set(try? JSONEncoder().encode(currentBestGame), forKey: Keys.bestGame.rawValue)
        }
    }
    
    func updateGameStats(isCorrect: Bool) {
        if isCorrect {
            correct += 1
        }
        total += 1
        if total % 10 == 0 {
            gamesCount += 1
        }
    }
    
    func resetGameStats() {
        gamesCount = 0
        userDefaults.set(0, forKey: Keys.correct.rawValue)
        userDefaults.set(0, forKey: Keys.total.rawValue)
    }
    
    // MARK: - Public Properties
    var totalAccuracy: Double {
        if total == 0 {
            return 0
        } else {
            return Double(correct) / Double(total)
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
    
    // MARK: - Private Properties
    private var correct: Int {
        get {
            return userDefaults.integer(forKey: Keys.correct.rawValue)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.correct.rawValue)
        }
    }

    private var total: Int {
        get {
            return userDefaults.integer(forKey: Keys.total.rawValue)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.total.rawValue)
        }
    }
}
