//
//  DetailViewController.swift
//  openlibraryCursado
//
//  Created by Arturo Rivas on 12/4/16.
//  Copyright © 2016 Arturo Rivas. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var títuloLabel: UILabel!
    @IBOutlet weak var autoresLabel: UILabel!
    @IBOutlet weak var portadaImage: UIImageView!
    
    var detailItem: Libro? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }
    
    func configureView() {
        // Update the user interface for the detail item.
        if let detail = self.detailItem {
            if let label = self.títuloLabel {
                label.text = detail.título
            }
            if let label = self.autoresLabel {
                label.text = detail.autor
            }
            if let label = self.portadaImage {
                label.image = detail.portada
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }

}

