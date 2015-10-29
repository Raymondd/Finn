//
//  modalView.swift
//  finBit
//
//  Created by Raymond Martin on 10/25/15.
//  Copyright © 2015 Raymond Martin. All rights reserved.
//

import UIKit

class modalView: UIViewController{
    @IBOutlet weak var urlText: UIButton!
    let defaults = NSUserDefaults.standardUserDefaults()
    
    override func viewDidLoad() {
        urlText.setTitle( "Click for: " + (defaults.stringForKey("item")?.lowercaseString)! + "s you can buy in bitcoin", forState: .Normal);
        
    }
    
    @IBAction func exit(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
   
    @IBAction func linkOut(sender: AnyObject) {
        var url : NSURL
        url = NSURL(string: defaults.stringForKey("URL")!)!
        UIApplication.sharedApplication().openURL(url)
        
        
        
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
    
}

