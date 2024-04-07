import Foundation

protocol QuestionFactoryDelegate {
    func didReceiveNextQuestion(question: QuizQuestion?)
    func didLoadDataFromServer()
    func didFailToLoadData(with error: Error)
    func didReceiveError(error: Error)
    func didReceiveQuestion(question: QuizQuestion?)
}
