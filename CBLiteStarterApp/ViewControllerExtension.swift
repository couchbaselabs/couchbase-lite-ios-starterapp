//
//  ViewControllerExtension.swift
//  CBLiteStarterApp
//
//  Created by Priya Rajagopal on 4/6/17.
//  Copyright © 2017 Couchbase Inc. All rights reserved.
//

import Foundation

extension UIViewController {
    func showAlertWithTitle(_ title:String?, message:String) {
        
        let alertController = UIAlertController(title: title ?? "", message: message, preferredStyle: UIAlertController.Style.alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { (result : UIAlertAction) -> Void in
            self.dismiss(animated: true, completion: {
                
            })
        }
        
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
}
