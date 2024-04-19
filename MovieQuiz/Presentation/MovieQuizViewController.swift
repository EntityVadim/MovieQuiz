import UIKit

// MARK: - MovieQuizViewController

final class MovieQuizViewController: UIViewController {
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet private var counterLabel: UILabel!
    @IBOutlet private weak var blockingButtons: UIButton!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Private Properties
    
    private var presenter: MovieQuizPresenter!
    private var moviesLoader = MoviesLoader()
    private var statisticService: StatisticService?
    private var gameStatsText: String = ""
    lazy var alertPresenter = AlertPresenter(viewController: self)
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.backgroundColor = .clear
        textLabel.text = ""
        imageView.layer.cornerRadius = 20
        activityIndicator.hidesWhenStopped = true
        presenter = MovieQuizPresenter() // Изменения под сомнением
        statisticService = StatisticServiceImplementation()
        showLoadingIndicator()
        presenter.questionFactory?.loadData() // Изменения под сомнением
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
        guard presenter.currentQuestion != nil else {
            return
        }
        blockingButtons.isEnabled = false
        statisticService?.updateGameStats(isCorrect: isCorrect)
        if isCorrect {
            presenter.correctAnswers += 1
        }
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrect ? UIColor.ypGreenIOS.cgColor : UIColor.ypRedIOS.cgColor
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.showNextQuestionOrResults()
        }
    }
    
    func showNextQuestionOrResults() {
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
            self.presenter.questionFactory?.requestNextQuestion()
            imageView.layer.borderColor = UIColor.clear.cgColor
        }
    }
    
    func show(quiz result: QuizResultsViewModel) {
        guard let statisticService = statisticService else {
            return
        }
        let correctAnswers = presenter.correctAnswers
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
                self?.presenter.resetGame()
            },
            accessibilityIndicator: "QuizResultsAlert")
        alertPresenter.showAlert(model: alertModel)
    }
    

    
    func showNetworkError(message: String) {
        hideLoadingIndicator()
        let model = AlertModel(
            title: "Ошибка",
            message: message,
            buttonText: "Попробовать еще раз",
            completion: { [weak self] in
                self?.presenter.resetGame()
                self?.presenter.questionFactory?.loadData()
            },
            accessibilityIndicator: "NetworkErrorAlert")
        alertPresenter.showAlert(model: model)
    }
}
