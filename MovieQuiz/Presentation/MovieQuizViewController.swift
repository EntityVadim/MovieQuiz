import UIKit

// MARK: - Movie Quiz View Controller
final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {
    
    // MARK: - IBOutlet
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private var counterLabel: UILabel!
    @IBOutlet private weak var blockingButtons: UIButton!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Private Properties
    private var questionFactory: QuestionFactoryProtocol?
    private var moviesLoader = MoviesLoader()
    private var currentQuestion: QuizQuestion?
    private var statisticService: StatisticService?
    private var gameStatsText: String = ""
    private var currentQuestionIndex: Int = 0
    private var correctAnswers: Int = 0
    private let questionsAmount: Int = 10
    private lazy var alertPresenter = AlertPresenter(viewController: self)
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.backgroundColor = .clear
        textLabel.text = ""
        imageView.layer.cornerRadius = 20
        activityIndicator.hidesWhenStopped = true
        questionFactory = QuestionFactory(delegate: self)
        statisticService = StatisticServiceImplementation()
        showLoadingIndicator()
        questionFactory?.loadData()
    }
    
    // MARK: - QuestionFactoryDelegate
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else {
            return
        }
        currentQuestion = question
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.show(quiz: viewModel)
            self?.imageView.image = viewModel.image
            self?.textLabel.text = viewModel.question
        }
    }
    
    // MARK: - Public methods
    func showLoadingIndicator() {
        activityIndicator.startAnimating()
    }
    
    func hideLoadingIndicator() {
        activityIndicator.stopAnimating()
    }
    
    func didLoadDataFromServer() {
        hideLoadingIndicator()
        questionFactory?.requestNextQuestion()
    }

    func didFailToLoadData(with error: Error) {
        showNetworkError(message: error.localizedDescription)
    }
    func didReceiveError(error: Error) {
        if error is URLError && (error as! URLError).code == .notConnectedToInternet {
            questionFactory?.loadData()
        } else {
            let model = AlertModel(
                title: "Ошибка",
                message: error.localizedDescription,
                buttonText: "Попробовать еще раз") { [weak self] in
                    self?.resetGame()
                    self?.questionFactory?.loadData()
                }
            alertPresenter.showAlert(model: model)
        }
    }

    func didReceiveQuestion(question: QuizQuestion?) {
        guard let question = question else {
            return
        }
        currentQuestion = question
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.show(quiz: viewModel)
        }
    }
    
    // MARK: - IBAction
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        let givenAnswer = true
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        let givenAnswer = false
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
    
    // MARK: - Private Methods
    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        return QuizStepViewModel(
            image: UIImage(data: model.image)!,
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
    }
    
    private func show(quiz step: QuizStepViewModel) {
        imageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
    }
    
    private func showAnswerResult(isCorrect: Bool) {
        guard currentQuestion != nil else {
            return
        }
        blockingButtons.isEnabled = false
        statisticService?.updateGameStats(isCorrect: isCorrect)
        if isCorrect {
            correctAnswers += 1
        }
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrect ? UIColor.ypGreenIOS.cgColor : UIColor.ypRedIOS.cgColor
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.showNextQuestionOrResults()
        }
    }
    
    private func showNextQuestionOrResults() {
        blockingButtons.isEnabled = true
        if currentQuestionIndex == questionsAmount - 1 {
            guard let statisticService = statisticService else {
                return
            }
            let correctAnswers = self.correctAnswers
            let totalQuestions = questionsAmount
            statisticService.store(correct: correctAnswers, total: totalQuestions)
            let text = "Ваш результат: \(correctAnswers)/10"
            let completedGamesCount = "Количество сыгранных квизов: \(statisticService.gamesCount)"
            let bestGame = statisticService.bestGame
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.yyyy"
            let dateString = dateFormatter.string(from: bestGame.date)
            let bestGameInfo = "Рекорд: \(bestGame.correct)/\(bestGame.total) (\(dateString))"
            let averageAccuracy = String(format: "Средняя точность: %.2f%%", statisticService.totalAccuracy * 100)
            gameStatsText = "\(text)\n\(completedGamesCount)\n\(bestGameInfo)\n\(averageAccuracy)"
            let viewModel = QuizResultsViewModel(
                title: "Этот раунд окончен!",
                text: gameStatsText,
                buttonText: "Сыграть ещё раз")
            show(quiz: viewModel)
            print(gameStatsText)
            imageView.layer.borderColor = UIColor.clear.cgColor
        } else {
            currentQuestionIndex += 1
            self.questionFactory?.requestNextQuestion()
            imageView.layer.borderColor = UIColor.clear.cgColor
        }
    }

    
    private func show(quiz result: QuizResultsViewModel) {
        let alertModel = AlertModel(
            title: result.title,
            message: gameStatsText,
            buttonText: result.buttonText) { [weak self] in
                self?.resetGame()
            }
        alertPresenter.showAlert(model: alertModel)
    }
    
    private func resetGame() {
        currentQuestionIndex = 0
        correctAnswers = 0
        questionFactory?.requestNextQuestion()
    }
    
    private func showNetworkError(message: String) {
        hideLoadingIndicator()
        let model = AlertModel(
            title: "Ошибка",
            message: message,
            buttonText: "Попробовать еще раз") { [weak self] in
                self?.resetGame()
                self?.questionFactory?.loadData()
            }
        alertPresenter.showAlert(model: model)
    }
}
