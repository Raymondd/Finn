//
//  File.swift
//  finBit
//
//  Created by Raymond Martin on 10/25/15.
//  Copyright © 2015 Raymond Martin. All rights reserved.
//

import UIKit

class infoModal: UIViewController{
    @IBOutlet weak var titel: UILabel!
    @IBOutlet weak var info: UILabel!
    
    
    
    
    override func viewDidLoad() {
        let defaults = NSUserDefaults.standardUserDefaults()
        
        titel.text = defaults.stringForKey("question")
        info.text = defaults.stringForKey("answer")
    }
    
    @IBAction func exit(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
}