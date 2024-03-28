import Foundation

// MARK: - Question Factory Delegate Protocol
protocol QuestionFactoryDelegate: AnyObject {
    func didReceiveNextQuestion(question: QuizQuestion?)
}
