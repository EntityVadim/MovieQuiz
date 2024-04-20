import UIKit

// MARK: - MovieQuizViewController

final class MovieQuizViewController: UIViewController, MovieQuizViewControllerProtocol {
    
    // MARK: - IBOutlet
    
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var blockingButtons: UIButton!
    @IBOutlet private var counterLabel: UILabel!
    
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
        showLoadingIndicator()
        presenter?.questionFactory?.loadData()
    }
    
    // MARK: - Public methods
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return.lightContent
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
 
    // MARK: - IBAction
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        presenter?.yesButtonClicked()
    }
    
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        presenter?.noButtonClicked()
    }
}
