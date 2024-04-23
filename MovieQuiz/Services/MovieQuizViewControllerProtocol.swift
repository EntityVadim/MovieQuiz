import Foundation
import UIKit

protocol MovieQuizViewControllerProtocol: AnyObject {
    var alertPresenter: AlertPresenter? { get set }
    var imageView: UIImageView! { get set }
    var textLabel: UILabel! { get set }
    var blockingButtons: UIButton! { get set }
    
    func show(quiz step: QuizStepViewModel)
    func show(quiz result: QuizResultsViewModel)
    func highlightImageBorder(isCorrectAnswer: Bool)
    func showLoadingIndicator()
    func hideLoadingIndicator()
    func showNetworkError(message: String)
}
