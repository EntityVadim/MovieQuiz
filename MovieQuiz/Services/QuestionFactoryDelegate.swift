import Foundation

// MARK: - QuestionFactoryDelegateProtocol
protocol QuestionFactoryDelegate: AnyObject {
    func didReceiveNextQuestion(question: QuizQuestion?)
}
