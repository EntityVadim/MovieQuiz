import UIKit

// MARK: - MovieQuizViewController

final class MovieQuizViewController: UIViewController, MovieQuizViewControllerProtocol {
    
    // MARK: - IBOutlet
    
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var textLabel: UILabel!
    @IBOutlet var blockingButtons: UIButton!
    @IBOutlet private var counterLabel: UILabel!
    
    // MARK: - Public Properties
    
    var alertPresenter: AlertPresenter?
    
    // MARK: - Private Properties
    
    private var presenter: MovieQuizPresenter!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.backgroundColor = .clear
        textLabel.text = ""
        imageView.layer.cornerRadius = 20
        activityIndicator.hidesWhenStopped = true
        presenter = MovieQuizPresenter(viewController: self)
        alertPresenter = AlertPresenter(viewController: self)
        showLoadingIndicator()
    }
    
    // MARK: - Public methods
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return.lightContent
    }
    
    func show(quiz result: QuizResultsViewModel) {
        let resultMessage = presenter.makeResultMessage()
        let alertModel = AlertModel(
            title: "Этот раунд окончен!",
            message: resultMessage,
            buttonText: "Сыграть ещё раз",
            completion: { [weak self] in
                self?.presenter.resetGame()
            },
            accessibilityIndicator: "QuizResultsAlert")
        alertPresenter?.showAlert(model: alertModel)
    }
    
    func highlightImageBorder(isCorrectAnswer: Bool) {
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrectAnswer ? UIColor.ypGreenIOS.cgColor : UIColor.ypRedIOS.cgColor
    }
    
    func showLoadingIndicator() {
        activityIndicator?.startAnimating()
    }
    
    func hideLoadingIndicator() {
        activityIndicator?.stopAnimating()
    }
    
    func show(quiz step: QuizStepViewModel) {
        imageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
    }
    
    func showNetworkError(message: String) {
        let model = AlertModel(
            title: "Ошибка",
            message: message,
            buttonText: "Попробовать еще раз",
            completion: { [weak self] in
                self?.presenter.resetGame()
                self?.presenter.questionFactory?.loadData()
            },
            accessibilityIndicator: "NetworkErrorAlert")
        alertPresenter?.showAlert(model: model)
    }
    
    // MARK: - IBAction
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        presenter?.yesButtonClicked()
    }
    
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        presenter?.noButtonClicked()
    }
}
