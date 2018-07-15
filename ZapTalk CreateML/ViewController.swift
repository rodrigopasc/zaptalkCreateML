//
//  ViewController.swift
//  ZapTalk CreateML
//
//  Created by Rodrigo Paschoaletto on 15/06/18.
//  Copyright © 2018 Rodrigo Paschoaletto. All rights reserved.
//

import UIKit
import CoreML
import Vision

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let imageController = UIImagePickerController()
    
    // Outlets.
    @IBOutlet weak var imageToBeClassified: UIImageView!
    @IBOutlet weak var classificationResult: UILabel!
    
    // Verifica se a imagem é válida.
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            fatalError("Não foi possível carregar a foto da sua galeria.")
        }
        
        imageToBeClassified.image = image
        
        guard let ciImage = CIImage(image: image) else {
            fatalError("Não foi possível converter de UIImage para CIImage")
        }
        
        classifyImage(image: ciImage)
    }
    
    // Função para iniciar o processo de classificação da imagem selecionada.
    func classifyImage(image: CIImage) {
        // Altera o label na Storyboard.
        classificationResult.text = "Classificando a imagem..."
        
        // Configura o Vision com o model indicado.
        guard let model = try? VNCoreMLModel(for: ImageClassifier().model) else {
            fatalError("O model para o CoreML não pôde ser carregado.")
        }
        
        // Solicita ao Vision uma classificação utilizando o model personalizado.
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            guard let results = request.results as? [VNClassificationObservation],
                let topResult = results.first else {
                    fatalError("Resultado inesperado do VNCoreMLRequest.")
            }
            
            // Altera o resultado na label da Storyboard.
            DispatchQueue.main.async { [weak self] in
                self?.classificationResult.text = "\(Int(topResult.confidence * 100))% - \(topResult.identifier)"
            }
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        // Executa a operação.
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try handler.perform([request])
            } catch {
                print(error)
            }
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    // Solicita de onde virá a imagem para ser classificada.
    @IBAction func pickImageToClassify(_ sender: Any) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            presentPhotoPicker(sourceType: .photoLibrary)
            return
        }
        
        let photoSourcePicker = UIAlertController()
        let takePhoto = UIAlertAction(title: "Tirar foto", style: .default) { [unowned self] _ in
            self.presentPhotoPicker(sourceType: .camera)
        }
        let choosePhoto = UIAlertAction(title: "Escolher foto", style: .default) { [unowned self] _ in
            self.presentPhotoPicker(sourceType: .photoLibrary)
        }
        
        photoSourcePicker.addAction(takePhoto)
        photoSourcePicker.addAction(choosePhoto)
        photoSourcePicker.addAction(UIAlertAction(title: "Cancelar", style: .cancel, handler: nil))
        
        present(photoSourcePicker, animated: true)
    }

    func presentPhotoPicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        present(picker, animated: true)
    }
}
