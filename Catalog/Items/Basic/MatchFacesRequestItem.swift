//
//  MatchFacesRequestItem.swift
//  Catalog
//
//  Created by Pavel Kondrashkov on 5/20/21.
//  Copyright © 2021 Regula. All rights reserved.
//

import FaceSDK
import Photos

final class MatchFacesRequestItem: CatalogItem {
    override init() {
        super.init()

        title = "MatchFacesRequest"
        itemDescription = "Checks the likelihood that two faces belong to the same person."
        category = .basic
    }

    override func onItemSelected(from viewController: UIViewController) {
        let example = MatchFacesRequestViewController()
        viewController.show(example, sender: nil)
    }
}

final class MatchFacesRequestViewController: UIViewController {
    private enum Position {
        case first
        case second
    }

    lazy var firstImageView: UIImageView = {
        let view = UIImageView()
        let tapGestureFirst = UITapGestureRecognizer(target: self, action: #selector(self.handleFirstImageTap))
        view.addGestureRecognizer(tapGestureFirst)
        view.contentMode = .scaleAspectFit
        view.isUserInteractionEnabled = true
        view.backgroundColor = .lightGray
        return view
    }()

    lazy var secondImageView: UIImageView = {
        let view = UIImageView()
        let tapGestureFirst = UITapGestureRecognizer(target: self, action: #selector(self.handleSecondImageTap))
        view.addGestureRecognizer(tapGestureFirst)
        view.contentMode = .scaleAspectFit
        view.isUserInteractionEnabled = true
        view.backgroundColor = .lightGray
        return view
    }()

    private var firstImage: Image?
    private var secondImage: Image?

    private lazy var matchFacesButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(self.handleMatchButtonPress), for: .touchUpInside)
        button.setTitle("Match Faces", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15)
        button.backgroundColor = .windsor
        button.contentEdgeInsets = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
        button.layer.cornerRadius = 5
        button.clipsToBounds = false
        return button
    }()

    private lazy var clearButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(self.handleClearButtonPress), for: .touchUpInside)
        button.setTitle("Clear", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15)
        button.backgroundColor = .windsor
        button.contentEdgeInsets = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
        button.layer.cornerRadius = 5
        button.clipsToBounds = false
        return button
    }()

    private lazy var similarityLabel: UILabel = {
        let label = UILabel()
        label.text = similarityLabelDefaultText
        label.font = .preferredFont(forTextStyle: .title3)
        return label
    }()

    private let similarityLabelDefaultText = "Similarity: Select Photos."

    override func loadView() {
        view = UIView()
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }

        let root = UIStackView()
        root.spacing = 25
        root.axis = .vertical

        view.addSubview(root)
        root.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            root.topAnchor.constraint(equalTo: view.safeTopAnchor, constant: 20),
            root.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            root.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            root.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40),
        ])

        let imagesContainer = UIStackView()
        imagesContainer.axis = .vertical
        imagesContainer.distribution = .fillEqually
        imagesContainer.spacing = 45

        imagesContainer.addArrangedSubview(firstImageView)
        imagesContainer.addArrangedSubview(secondImageView)

        root.addArrangedSubview(similarityLabel)
        root.addArrangedSubview(imagesContainer)
        root.addArrangedSubview(matchFacesButton)
        root.addArrangedSubview(clearButton)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
    }

    @objc private func handleFirstImageTap() {
        similarityLabel.text = similarityLabelDefaultText

        createImageForPosition(.first) { [weak self] (image) in
            self?.firstImageView.image = image?.image
            self?.firstImage = image
        }
    }

    @objc private func handleSecondImageTap() {
        similarityLabel.text = similarityLabelDefaultText

        createImageForPosition(.second) { [weak self] (image) in
            self?.secondImageView.image = image?.image
            self?.secondImage = image
        }
    }

    private func createImageForPosition(_ position: Position, completion: @escaping (Image?) -> Void) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Regula FaceCaptureUI", style: .default, handler: { _ in
            Face.service.presentCaptureViewController(
                from: self,
                animated: true,
                onCapture: { response in
                    completion(response.image)
                },
                completion: nil
            )
        }))
        alert.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
            self.pickImage(sourceType: .photoLibrary) { image in
                let result = image.map { Image(image: $0, type: .printed) }
                completion(result)
            }
        }))
        alert.addAction(UIAlertAction(title: "Camera Shoot", style: .default, handler: { _ in
            self.pickImage(sourceType: .camera) { image in
                let result = image.map { Image(image: $0, type: .live) }
                completion(result)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            completion(nil)
        }))


        let imageView: UIImageView
        switch position {
        case .first:
            imageView = firstImageView
        case .second:
            imageView = secondImageView
        }

        if let popoverPresentationController = alert.popoverPresentationController {
            popoverPresentationController.sourceView = view
            popoverPresentationController.sourceRect = CGRect(
                x: imageView.frame.midX,
                y: imageView.frame.midY,
                width: 0,
                height: 0
            )
        }
        self.present(alert, animated: true, completion: nil)
    }

    @objc private func handleMatchButtonPress() {
        guard let firstImage = firstImage, let secondImage = secondImage else {
            let alert = UIAlertController(title: "Having both images is required", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }

        let request = MatchFacesRequest(images: [firstImage, secondImage])

        self.similarityLabel.text = "Processing..."
        self.matchFacesButton.isEnabled = false
        self.clearButton.isEnabled = false

        Face.service.matchFaces(request, completion: { (response: MatchFacesResponse) in
            self.matchFacesButton.isEnabled = true
            self.clearButton.isEnabled = true

            if let error = response.error {
                self.similarityLabel.text = "Similarity: \(error.localizedDescription)"
                return
            }

            if let firstPair = response.matchedFaces.first {
                let similarity = String(format: "%.5f", firstPair.similarity.doubleValue)
                self.similarityLabel.text = "Similarity: \(similarity)"
            } else {
                self.similarityLabel.text = "Similarity: no matched pair found"
            }
        })
    }

    @objc private func handleClearButtonPress(sender: UIButton) {
        self.firstImageView.image = nil
        self.firstImage = nil

        self.secondImageView.image = nil
        self.secondImage = nil

        self.similarityLabel.text = similarityLabelDefaultText
    }

    private var imagePickerCompletion: ((UIImage?) -> Void)?

    private func pickImage(sourceType: UIImagePickerController.SourceType, completion: @escaping ((UIImage?) -> Void)) {
        PHPhotoLibrary.requestAuthorization { (status) in
            switch status {
            case .authorized:
                if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
                    DispatchQueue.main.async {
                        self.imagePickerCompletion = completion

                        let imagePicker = UIImagePickerController()
                        imagePicker.delegate = self
                        imagePicker.sourceType = sourceType
                        imagePicker.allowsEditing = false
                        imagePicker.navigationBar.tintColor = .black
                        self.present(imagePicker, animated: true, completion: nil)
                    }
                } else {
                    completion(nil)
                }
            case .denied:
                let message = NSLocalizedString("Application doesn't have permission to use the camera, please change privacy settings", comment: "Alert message when the user has denied access to the gallery")
                let alertController = UIAlertController(title: NSLocalizedString("Gallery Unavailable", comment: "Alert eror title"), message: message, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert manager, OK button tittle"), style: .cancel, handler: nil))
                alertController.addAction(UIAlertAction(title: NSLocalizedString("Settings", comment: "Alert button to open Settings"), style: .default, handler: { action in
                    guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
                    } else {
                        UIApplication.shared.openURL(settingsURL)
                    }
                }))
                self.present(alertController, animated: true, completion: nil)
                print("PHPhotoLibrary status: denied")
                completion(nil)
            case .notDetermined:
                print("PHPhotoLibrary status: notDetermined")
                completion(nil)
            case .restricted:
                print("PHPhotoLibrary status: restricted")
                completion(nil)
            case .limited:
                print("PHPhotoLibrary status: Limited")
                completion(nil)
            @unknown default:
                fatalError()
            }
        }
    }
}

extension MatchFacesRequestViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let image = info[.originalImage] as? UIImage {
            picker.dismiss(animated: true, completion: {
                self.imagePickerCompletion?(image)
            })
        } else {
            picker.dismiss(animated: true, completion: {
                self.imagePickerCompletion?(nil)
            })
            print("Something went wrong")
        }
    }
}
