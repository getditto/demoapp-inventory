import UIKit

final class NewAssetViewController: UIViewController {

    // MARK: - State

    private var capturedImage: UIImage?

    // MARK: - Subviews

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let photoButton: UIButton = {
        let config = UIImage.SymbolConfiguration(pointSize: 36, weight: .light)
        let img = UIImage(systemName: "camera.fill", withConfiguration: config)
        var btn = UIButton(type: .system)
        btn.setImage(img, for: .normal)
        btn.backgroundColor = UIColor.secondarySystemBackground
        btn.tintColor = .systemGray2
        btn.layer.cornerRadius = 12
        btn.layer.masksToBounds = true
        return btn
    }()

    private let photoImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 12
        iv.layer.masksToBounds = true
        iv.isHidden = true
        return iv
    }()

    private let nsnField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "e.g. 1005-01-234-5678"
        tf.borderStyle = .roundedRect
        tf.autocapitalizationType = .allCharacters
        tf.autocorrectionType = .no
        tf.font = UIFont.monospacedSystemFont(ofSize: 16, weight: .regular)
        tf.returnKeyType = .done
        return tf
    }()

    private let conditionControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: Constants.Condition.allCases.map { $0.rawValue })
        sc.selectedSegmentIndex = 0
        return sc
    }()

    private let notesField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Optional"
        tf.borderStyle = .roundedRect
        tf.returnKeyType = .done
        return tf
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "New Asset"

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel, target: self, action: #selector(cancel)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Save", style: .done, target: self, action: #selector(save)
        )

        setupLayout()
        photoButton.addTarget(self, action: #selector(takePhoto), for: .touchUpInside)
        nsnField.delegate = self
        notesField.delegate = self
    }

    // MARK: - Layout

    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])

        let photoLabel    = sectionLabel("PHOTO")
        let nsnLabel      = sectionLabel("NSN / LSN")
        let condLabel     = sectionLabel("CONDITION")
        let notesLabel    = sectionLabel("NOTES")

        [photoLabel, photoButton, photoImageView,
         nsnLabel, nsnField,
         condLabel, conditionControl,
         notesLabel, notesField].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            photoLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            photoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            photoButton.topAnchor.constraint(equalTo: photoLabel.bottomAnchor, constant: 8),
            photoButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            photoButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            photoButton.heightAnchor.constraint(equalToConstant: 200),

            photoImageView.topAnchor.constraint(equalTo: photoButton.topAnchor),
            photoImageView.leadingAnchor.constraint(equalTo: photoButton.leadingAnchor),
            photoImageView.trailingAnchor.constraint(equalTo: photoButton.trailingAnchor),
            photoImageView.bottomAnchor.constraint(equalTo: photoButton.bottomAnchor),

            nsnLabel.topAnchor.constraint(equalTo: photoButton.bottomAnchor, constant: 28),
            nsnLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            nsnField.topAnchor.constraint(equalTo: nsnLabel.bottomAnchor, constant: 8),
            nsnField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            nsnField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            condLabel.topAnchor.constraint(equalTo: nsnField.bottomAnchor, constant: 28),
            condLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            conditionControl.topAnchor.constraint(equalTo: condLabel.bottomAnchor, constant: 8),
            conditionControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            conditionControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            notesLabel.topAnchor.constraint(equalTo: conditionControl.bottomAnchor, constant: 28),
            notesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            notesField.topAnchor.constraint(equalTo: notesLabel.bottomAnchor, constant: 8),
            notesField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            notesField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            notesField.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),
        ])
    }

    private func sectionLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        l.textColor = .secondaryLabel
        return l
    }

    // MARK: - Actions

    @objc private func takePhoto() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera)
            ? .camera
            : .photoLibrary
        present(picker, animated: true)
    }

    @objc private func save() {
        let nsn = (nsnField.text ?? "").trimmingCharacters(in: .whitespaces)
        guard !nsn.isEmpty else {
            let alert = UIAlertController(
                title: "NSN Required",
                message: "Please enter a National Stock Number.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        let condition = Constants.Condition.allCases[conditionControl.selectedSegmentIndex].rawValue
        let notes = (notesField.text ?? "").trimmingCharacters(in: .whitespaces)
        AssetDittoManager.shared.insertAsset(nsn: nsn, condition: condition, notes: notes, image: capturedImage)
        dismiss(animated: true)
    }

    @objc private func cancel() {
        dismiss(animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate

extension NewAssetViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        picker.dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage else { return }
        capturedImage = image
        photoImageView.image = image
        photoImageView.isHidden = false
        photoButton.setImage(nil, for: .normal)
        photoButton.backgroundColor = .clear
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - UITextFieldDelegate

extension NewAssetViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
