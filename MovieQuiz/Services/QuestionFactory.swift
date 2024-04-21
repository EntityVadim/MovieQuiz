import Foundation

// MARK: - Question Factory

final class QuestionFactory: QuestionFactoryProtocol {
    
    // MARK: - Public Properties
    
    weak var delegate: QuestionFactoryDelegate?
    
    // MARK: - Private Properties
    
    private var movies: [MostPopularMovie] = []
    private var moviesLoader = MoviesLoader()
    private var lastRandomRating: Float?
    
    // MARK: - Quiz Questions
    
    /*private let questions: [QuizQuestion] = [
     QuizQuestion(
     image: "The Godfather",
     text: "Рейтинг этого фильма больше чем 6?",
     correctAnswer: true),
     QuizQuestion(
     image: "The Dark Knight",
     text: "Рейтинг этого фильма больше чем 6?",
     correctAnswer: true),
     QuizQuestion(
     image: "Kill Bill",
     text: "Рейтинг этого фильма больше чем 6?",
     correctAnswer: true),
     QuizQuestion(
     image: "The Avengers",
     text: "Рейтинг этого фильма больше чем 6?",
     correctAnswer: true),
     QuizQuestion(
     image: "Deadpool",
     text: "Рейтинг этого фильма больше чем 6?",
     correctAnswer: true),
     QuizQuestion(
     image: "The Green Knight",
     text: "Рейтинг этого фильма больше чем 6?",
     correctAnswer: true),
     QuizQuestion(
     image: "Old",
     text: "Рейтинг этого фильма больше чем 6?",
     correctAnswer: false),
     QuizQuestion(
     image: "The Ice Age Adventures of Buck Wild",
     text: "Рейтинг этого фильма больше чем 6?",
     correctAnswer: false),
     QuizQuestion(
     image: "Tesla",
     text: "Рейтинг этого фильма больше чем 6?",
     correctAnswer: false),
     QuizQuestion(
     image: "Vivarium",
     text: "Рейтинг этого фильма больше чем 6?",
     correctAnswer: false)
     ]*/
    
    // MARK: - Public Methods
    
    init(delegate: QuestionFactoryDelegate?) {
        self.delegate = delegate
        moviesLoader = MoviesLoader()
    }
    
    func setup(delegate: QuestionFactoryDelegate) {
        self.delegate = delegate
    }
    
    func requestNextQuestion() {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            let index = (0..<self.movies.count).randomElement() ?? 0
            guard let movie = self.movies[safe: index] else { return }
            var imageData = Data()
            do {
                imageData = try Data(contentsOf: movie.resizedImageURL)
            } catch {
                let detailedError = NSError(
                    domain: "MovieQuizErrorDomain",
                    code: 1001,
                    userInfo: [NSLocalizedDescriptionKey: "Не удалось загрузить изображение для фильма: \(movie.title). Проверьте соединение с интернетом и попробуйте снова."])
                DispatchQueue.main.async {
                    self.delegate?.didReceiveError(error: detailedError)
                }
                return
            }
            let rating = Float(movie.rating) ?? 0
            var randomRating: Float
            repeat {
                randomRating = Float.random(in: 8.1...8.8).rounded(toPlaces: 1)
            } while randomRating == self.lastRandomRating
            self.lastRandomRating = randomRating
            let text = "Рейтинг этого фильма больше чем \(randomRating)?"
            let correctAnswer = rating > randomRating
            let question = QuizQuestion(image: imageData, text: text, correctAnswer: correctAnswer)
            DispatchQueue.main.async {
                self.delegate?.didReceiveNextQuestion(question: question)
            }
        }
    }
    
    func loadData() {
        moviesLoader.loadMovies { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let mostPopularMovies):
                    if mostPopularMovies.errorMessage.isEmpty {
                        self.movies = mostPopularMovies.items
                        self.delegate?.didLoadDataFromServer()
                    } else {
                        self.showNetworkError(message: mostPopularMovies.errorMessage)
                    }
                case .failure(let error):
                    self.delegate?.didFailToLoadData(with: error)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func showNetworkError(message: String) {
        delegate?.didReceiveError(error: NSError(domain: "com.yp.MovieQuiz", code: 1, userInfo: [NSLocalizedDescriptionKey: message]))
    }
}
