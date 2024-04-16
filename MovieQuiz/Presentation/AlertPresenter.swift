import UIKit

class AlertPresenter {
    
    // MARK: - Private Properties
    
    private weak var viewController: UIViewController?
    
    // MARK: - Public methods
    
    init(viewController: UIViewController) {
        self.viewController = viewController
    }
    
    func showAlert(model: AlertModel) {
        guard let viewController = viewController else {
            return
        }
        let alert = UIAlertController(
            title: model.title,
            message: model.message,
            preferredStyle: .alert)
        alert.view.accessibilityIdentifier = model.accessibilityIndicator
        let action = UIAlertAction(title: model.buttonText, style: .default) { _ in
            model.completion()
        }
        alert.addAction(action)
        viewController.present(alert, animated: true, completion: nil)
    }
}
