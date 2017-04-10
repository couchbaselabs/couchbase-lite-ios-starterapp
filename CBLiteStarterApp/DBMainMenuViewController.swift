//
//  MainMenuViewController.swift
//  CBLiteStarterApp
//
//  Created by Priya Rajagopal on 4/6/17.
//  Copyright © 2017 Couchbase Inc. All rights reserved.
//

import UIKit


class DBMainMenuViewController: UITableViewController {
   
    fileprivate let cbManager:CBLManager = CBLManager.sharedInstance()
    fileprivate let kDefaultDBName = "My Awesome DB"
}
// MARK : UITableViewDelegate
extension DBMainMenuViewController {
    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
 
            handleNewDBRequest()

        default:
            return
        }
}
}

// MARK: UI helpers
extension DBMainMenuViewController {
    fileprivate func handleNewDBRequest() {
        var dbNameTextField:UITextField!
        let alertController = UIAlertController(title: nil,
                                                message: NSLocalizedString("Create Database", comment: ""),
                                                preferredStyle: .alert)
        alertController.addTextField(configurationHandler: { (textField) in
            textField.placeholder = NSLocalizedString("Enter Database Name", comment: "")
            dbNameTextField = textField
        })
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Create", comment: ""), style: .default) { _ in
            let dbName = dbNameTextField.text ?? self.kDefaultDBName
            self.createDBWithName(dbName)
            
        })
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default) { _ in
            
        })
        self.present(alertController, animated: true, completion: nil)
        
    }

}



// MARK: CBL Related
extension DBMainMenuViewController {
    
    // Creates a DB in local store
    fileprivate func createDBWithName(_ name:String) {
        do {
            // 1: Set Database Options
            let options = CBLDatabaseOptions()
            options.storageType  = kCBLSQLiteStorage
            options.create = true
            
            // 2: Create a DB if it does not exist else return handle to existing one
            let _  = try cbManager.openDatabaseNamed(name.lowercased(), with: options)
            self.showAlertWithTitle(NSLocalizedString("Success!", comment: ""), message: NSLocalizedString("Database \(name) was created succesfully at path \(CBLManager.defaultDirectory())", comment: ""))
            
        }
        catch  {
            print("Failed to create database named \(name)")
            self.showAlertWithTitle(NSLocalizedString("Error!", comment: ""), message: NSLocalizedString("Database \(name) creation failed:\(error.localizedDescription)", comment: ""))
            
        }
    }
}
