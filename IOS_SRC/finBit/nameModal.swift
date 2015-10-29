//
//  File.swift
//  finBit
//
//  Created by Raymond Martin on 10/25/15.
//  Copyright © 2015 Raymond Martin. All rights reserved.
//

import UIKit

class nameModal: UIViewController{
    
    override func viewDidLoad() {
        
    }
    
    @IBAction func exit(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func sendCoins(sender: AnyObject) {
        
        var refreshAlert = UIAlertController(title: "Send Bitcoins", message: "are you sure?", preferredStyle: UIAlertControllerStyle.Alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Yes", style: .Default, handler: { (action: UIAlertAction!) in
            self.dismissViewControllerAnimated(true, completion: nil)
            self.dismissViewControllerAnimated(true, completion: nil)
        }))
        
        refreshAlert.addAction(UIAlertAction(title: "No", style: .Default, handler: { (action: UIAlertAction!) in
            
        }))
        
        presentViewController(refreshAlert, animated: true, completion: nil)
        
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
    

}

