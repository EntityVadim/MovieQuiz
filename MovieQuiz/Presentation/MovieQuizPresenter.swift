import UIKit

// // MARK: - MovieQuizPresenter

final class MovieQuizPresenter {
    
    // MARK: - Public Properties
    
    var correctAnswers: Int = 0
    let questionsAmount: Int = 10
    var currentQuestion: QuizQuestion?
    var questionFactory: QuestionFactoryProtocol?
    var statisticService: StatisticService?
    weak var viewController: MovieQuizViewController?
    var alertPresenter: AlertPresenter?
    
    // MARK: - Private Properties
    
    private var gameStatsText: String = ""
    private var currentQuestionIndex: Int = 0
    
    // MARK: - Public methods
    
    init(viewController: MovieQuizViewController) {
        self.viewController = viewController
        statisticService = StatisticServiceImplementation()
        questionFactory = QuestionFactory(delegate: self)
        viewController.showLoadingIndicator()
        statisticService = StatisticServiceImplementation()
        alertPresenter = AlertPresenter(viewController: viewController)
    }
    
    func isLastQuestion() -> Bool {
        currentQuestionIndex == questionsAmount - 1
    }
    
    func resetQuestionIndex() {
        currentQuestionIndex = 0
    }
    
    func switchToNextQuestion() {
        currentQuestionIndex += 1
    }
    
    func convert(model: QuizQuestion) -> QuizStepViewModel {
        return QuizStepViewModel(
            image: UIImage(data: model.image)!,
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
    }
    
    func resetGame() {
        currentQuestionIndex = 0
        correctAnswers = 0
        questionFactory?.requestNextQuestion()
    }
    
    func yesButtonClicked() {
        didAnswer(isYes: true)
    }
    
    func noButtonClicked() {
        didAnswer(isYes: false)
    }
    
    func didAnswer(isYes: Bool) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        let givenAnswer = isYes
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
    
    func showNextQuestionOrResults() {
        viewController?.blockingButtons.isEnabled = true
        if isLastQuestion() {
            let viewModel = QuizResultsViewModel(
                title: "Этот раунд окончен!",
                text: gameStatsText,
                buttonText: "Сыграть ещё раз")
            show(quiz: viewModel)
            print(gameStatsText)
            viewController?.imageView.layer.borderColor = UIColor.clear.cgColor
        } else {
            switchToNextQuestion()
            self.questionFactory?.requestNextQuestion()
            viewController?.imageView.layer.borderColor = UIColor.clear.cgColor
        }
    }
    
    func showAnswerResult(isCorrect: Bool) {
        guard currentQuestion != nil else {
            return
        }
        viewController?.blockingButtons.isEnabled = false
        statisticService?.updateGameStats(isCorrect: isCorrect)
        if isCorrect {
            correctAnswers += 1
        }
        viewController?.highlightImageBorder(isCorrectAnswer: isCorrect)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.showNextQuestionOrResults()
        }
    }
    
    func show(quiz result: QuizResultsViewModel) {
        guard let statisticService = statisticService else {
            return
        }
        let correctAnswers = correctAnswers
        let totalQuestions = questionsAmount
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
        alertPresenter?.showAlert(model: alertModel)
    }
    
    func showNetworkError(message: String) {
        viewController?.hideLoadingIndicator()
        let model = AlertModel(
            title: "Ошибка",
            message: message,
            buttonText: "Попробовать еще раз",
            completion: { [weak self] in
                self?.resetGame()
                self?.questionFactory?.loadData()
            },
            accessibilityIndicator: "NetworkErrorAlert")
        alertPresenter?.showAlert(model: model)
    }
}

// MARK: - QuestionFactoryDelegate

extension MovieQuizPresenter: QuestionFactoryDelegate {
    func didLoadDataFromServer() {
        viewController?.hideLoadingIndicator()
        questionFactory?.requestNextQuestion()
    }
    
    func didFailToLoadData(with error: Error) {
        showNetworkError(message: error.localizedDescription)
    }
    
    func didReceiveError(error: Error) {
        viewController?.hideLoadingIndicator()
        let model = AlertModel(
            title: "Ошибка",
            message: error.localizedDescription,
            buttonText: "Попробовать еще раз",
            completion: { [weak self] in
                self?.resetGame()
                self?.questionFactory?.loadData()
            },
            accessibilityIndicator: "ErrorAlert")
        alertPresenter?.showAlert(model: model)
    }
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else {
            return
        }
        currentQuestion = question
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.viewController?.show(quiz: viewModel)
            self?.viewController?.imageView?.image = viewModel.image
            self?.viewController?.textLabel?.text = viewModel.question
        }
    }
}
