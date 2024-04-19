import UIKit

// // MARK: - MovieQuizPresenter

final class MovieQuizPresenter {
    
    // MARK: - Public Properties
    
    var correctAnswers: Int = 0
    let questionsAmount: Int = 10
    var currentQuestion: QuizQuestion?
    var questionFactory: QuestionFactoryProtocol?
    weak var viewController: MovieQuizViewController?
    
    // MARK: - Private Properties
    
    private var currentQuestionIndex: Int = 0
    
    // MARK: - Public methods
    
    init(viewController: MovieQuizViewController) {
        self.viewController = viewController
        questionFactory = QuestionFactory(delegate: self)
        questionFactory?.loadData()
        viewController.showLoadingIndicator()
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
        viewController?.showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
}

// MARK: - QuestionFactoryDelegate

extension MovieQuizPresenter: QuestionFactoryDelegate {
    func didLoadDataFromServer() {
        viewController?.hideLoadingIndicator()
        questionFactory?.requestNextQuestion()
    }
    
    func didFailToLoadData(with error: Error) {
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
        viewController?.alertPresenter.showAlert(model: model)
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
