//
//  ViewController.swift
//  WhatFlower2
//
//  Created by Tracy Adams on 12/21/22.
//

import UIKit
import CoreML
import Vision
//from Podfile:
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let flowerURL = "https://en.wikipedia.org/w/api.php"

    let imagePicker = UIImagePickerController()
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var label: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userPickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            
            //imageView.image = userPickedImage
            
            guard let ci_image = CIImage(image: userPickedImage) else {
                fatalError("Could not convert to CI Image")
            }
            
            detect(image: ci_image) //call the image function
            
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func detect(image: CIImage){
        //reference the model
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else{
            fatalError("loading CoreML Model Failed")
        }
        
        //need request to run the model on image
        let request = VNCoreMLRequest(model: model){
            (request, error) in
            
            guard let classification = request.results?.first as? VNClassificationObservation else {
                fatalError("Could not classify image")
            }
            
            //show the result in the navigation bar title
            self.navigationItem.title = classification.identifier.capitalized
            self.performRequest(flowerName: classification.identifier)
        }
        let handler = VNImageRequestHandler(ciImage: image)
        
        do {
            //perform the request
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    func performRequest(flowerName: String) {
        
        let parameters : [String:String] = [
          "format" : "json",
          "action" : "query",
          "prop" : "extracts|pageimages",
          "exintro" : "",
          "explaintext" : "",
          "titles" : flowerName,
          "indexpageids" : "",
          "redirects" : "1",
          "pithumbsize" : "500"
          ]
        
        //simple method to use for APIs
        Alamofire.request(flowerURL, method: .get, parameters: parameters).responseJSON {(response) in
            if response.result.isSuccess {
                print("Got the wiki stuff")
                print(response)
                
                //Parse JSON:
                
                let flowerJSON : JSON = JSON(response.result.value!)
                //print("This is the JSON")
                //print(flowerJSON)
                
            
                let pageid = flowerJSON["query"]["pageids"][0].stringValue
                //print("This is the pageid")
                //print(pageid)
                
                
                let flowerDescription = flowerJSON["query"]["pages"][pageid]["extract"].stringValue
                //print("This is the flower description")
                //print(flowerDescription)
                
                self.label.text = flowerDescription
                
                let flowerImageURL = flowerJSON["query"]["pages"][pageid]["thumbnail"]["souce"].stringValue
               
                //print(flowerJSON["query"]["pages"][pageid]["thumbnail"])
                //This prints null, other parameters are not showing in JSON...
                
                self.imageView.sd_setImage(with: URL(string: flowerImageURL))
                
                
                
                
                
            
            }
        }
       
    }



    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        //send image to learning model
        present(imagePicker, animated: true, completion: nil)
        
    }
}

