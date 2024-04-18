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
    private var correctAnswers: Int = 0
    private lazy var alertPresenter = AlertPresenter(viewController: self)
    private lazy var presenter = MovieQuizPresenter()
    
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
        presenter.viewController = self
    }
    
    // MARK: - QuestionFactoryDelegate
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        presenter.didReceiveNextQuestion(question: question)
    }
    
    // MARK: - Public methods
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return.lightContent
    }
    
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
        hideLoadingIndicator()
        let model = AlertModel(
            title: "Ошибка",
            message: error.localizedDescription,
            buttonText: "Попробовать еще раз",
            completion: { [weak self] in
                self?.resetGame()
                self?.questionFactory?.loadData()
            },
            accessibilityIndicator: "ErrorAlert")
        alertPresenter.showAlert(model: model)
    }
    
    func didReceiveQuestion(question: QuizQuestion?) {
        guard let question = question else {
            return
        }
        currentQuestion = question
        let viewModel = presenter.convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.show(quiz: viewModel)
        }
    }
    
    // MARK: - IBAction
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        presenter.yesButtonClicked()
    }
    
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        presenter.noButtonClicked()
    }
    
    // MARK: - Private Methods
    

    
    func show(quiz step: QuizStepViewModel) {
        imageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
    }
    
    func showAnswerResult(isCorrect: Bool) {
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
        if presenter.isLastQuestion() {
            let viewModel = QuizResultsViewModel(
                title: "Этот раунд окончен!",
                text: gameStatsText,
                buttonText: "Сыграть ещё раз")
            show(quiz: viewModel)
            print(gameStatsText)
            imageView.layer.borderColor = UIColor.clear.cgColor
        } else {
            presenter.switchToNextQuestion()
            self.questionFactory?.requestNextQuestion()
            imageView.layer.borderColor = UIColor.clear.cgColor
        }
    }
    
    private func show(quiz result: QuizResultsViewModel) {
        guard let statisticService = statisticService else {
            return
        }
        let correctAnswers = self.correctAnswers
        let totalQuestions = presenter.questionsAmount
        statisticService.store(correct: correctAnswers, total: totalQuestions)
        let text = "Ваш результат: \(correctAnswers)/10"
        let completedGamesCount = "Количество сыгранных квизов: \(statisticService.gamesCount)"
        let bestGame = statisticService.bestGame
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm"
        let dateString = dateFormatter.string(from: bestGame.date)
        let bestGameInfo = "Рекорд: \(bestGame.correct)/\(bestGame.total) (\(dateString))"
        let averageAccuracy = String(format: "Средняя точность: %.2f%%", statisticService.totalAccuracy * 100)
        gameStatsText = "\(text)\n\(completedGamesCount)\n\(bestGameInfo)\n\(averageAccuracy)"
        let alertModel = AlertModel(
            title: result.title,
            message: gameStatsText,
            buttonText: result.buttonText,
            completion: { [weak self] in
                self?.resetGame()
            },
            accessibilityIndicator: "QuizResultsAlert")
        alertPresenter.showAlert(model: alertModel)
    }
    
    private func resetGame() {
        presenter.resetQuestionIndex()
        correctAnswers = 0
        questionFactory?.requestNextQuestion()
    }
    
    private func showNetworkError(message: String) {
        hideLoadingIndicator()
        let model = AlertModel(
            title: "Ошибка",
            message: message,
            buttonText: "Попробовать еще раз",
            completion: { [weak self] in
                self?.resetGame()
                self?.questionFactory?.loadData()
            },
            accessibilityIndicator: "NetworkErrorAlert")
        alertPresenter.showAlert(model: model)
    }
}
