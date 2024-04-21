import UIKit

// // MARK: - MovieQuizPresenter

final class MovieQuizPresenter {
    
    // MARK: - Public Properties
    
    var questionFactory: QuestionFactoryProtocol?
    var statisticService: StatisticService?
    weak var viewController: MovieQuizViewController?
    
    // MARK: - Private Properties
    
    private var currentQuestion: QuizQuestion?
    private var gameStatsText: String = ""
    private var correctAnswers: Int = 0
    private var currentQuestionIndex: Int = 0
    private let questionsAmount: Int = 10
    
    // MARK: - Public methods
    
    init(viewController: MovieQuizViewController) {
        self.viewController = viewController
        statisticService = StatisticServiceImplementation()
        questionFactory = QuestionFactory(delegate: self)
        viewController.showLoadingIndicator()
        statisticService = StatisticServiceImplementation()
        viewController.alertPresenter = AlertPresenter(viewController: viewController)
    }
    
    func resetGame() {
        currentQuestionIndex = 0
        correctAnswers = 0
        questionFactory?.requestNextQuestion()
    }
    
    func convert(model: QuizQuestion) -> QuizStepViewModel {
        return QuizStepViewModel(
            image: UIImage(data: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
    }
    
    func yesButtonClicked() {
        didAnswer(isYes: true)
    }
    
    func noButtonClicked() {
        didAnswer(isYes: false)
    }
    
    func makeResultMessage() -> String {
        guard let statisticService = statisticService else {
            return "Ошибка"
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
        return gameStatsText
    }
    
    // MARK: - Private Methods
    
    private func isLastQuestion() -> Bool {
        currentQuestionIndex == questionsAmount - 1
    }
    
    private func resetQuestionIndex() {
        currentQuestionIndex = 0
    }
    
    private func switchToNextQuestion() {
        currentQuestionIndex += 1
    }
    
    private func didAnswer(isYes: Bool) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        let givenAnswer = isYes
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
    
    private func showNextQuestionOrResults() {
        viewController?.blockingButtons.isEnabled = true
        if isLastQuestion() {
            let viewModel = QuizResultsViewModel(
                title: "Этот раунд окончен!",
                text: gameStatsText,
                buttonText: "Сыграть ещё раз")
            viewController?.show(quiz: viewModel)
            print(gameStatsText)
            viewController?.imageView.layer.borderColor = UIColor.clear.cgColor
        } else {
            switchToNextQuestion()
            self.questionFactory?.requestNextQuestion()
            viewController?.imageView.layer.borderColor = UIColor.clear.cgColor
        }
    }
    
    private func showAnswerResult(isCorrect: Bool) {
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

}

// MARK: - QuestionFactoryDelegate

extension MovieQuizPresenter: QuestionFactoryDelegate {
    func didLoadDataFromServer() {
        viewController?.hideLoadingIndicator()
        questionFactory?.requestNextQuestion()
    }
    
    func didFailToLoadData(with error: Error) {
        viewController?.hideLoadingIndicator()
        viewController?.showNetworkError(message: error.localizedDescription)
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
        viewController?.alertPresenter?.showAlert(model: model)
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
