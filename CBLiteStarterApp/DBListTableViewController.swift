//
//  DBListTableViewController.swift
//  CBLiteStarterApp
//
//  Created by Priya Rajagopal on 4/6/17.
//  Copyright © 2017 Couchbase Inc. All rights reserved.
//

import Foundation
class DBListTableViewController: UITableViewController {
    
    fileprivate let cbManager:CBLManager = CBLManager.sharedInstance()
    fileprivate var dbNames:[String]?
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("Databases", comment: "")
    }
     
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.getAllDatabases()
        self.tableView.reloadData()
        
    }
    
    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
    }
}

// MARK: CBL Related
extension DBListTableViewController {
    
    // Creates a DB in local store
    fileprivate func getAllDatabases() {
       self.dbNames = cbManager.allDatabaseNames
    }
    
    fileprivate func deleteDatabaseAtIndex(_ indexPath:IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath)   {
            if  let dbToDelete = cell.textLabel?.text {
                do {
                    // 1.  Get handle to database if exists
                    let db = try cbManager.existingDatabaseNamed(dbToDelete)
                    
                    // 2. Delete the database
                    try db.delete()
                    
                    // 3. update local bookkeeping
                    self.dbNames?.remove(at: indexPath.row)

                    // 4. Update UI
                    tableView.deleteRows(at: [indexPath], with: .automatic)
                }
                catch {
                    self.showAlertWithTitle(NSLocalizedString("Database Delete Error!", comment: ""), message: error.localizedDescription)
                    
                }
                
            }
        }
    }
}

//MARK:UITableViewDataSource
extension DBListTableViewController {
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dbNames?.count ?? 0
    }
    
    
    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DBCell") else { return UITableViewCell.init()}
        if let db = dbNames?[indexPath.row] {
            cell.textLabel?.text = db
        
            cell.selectionStyle = .default
            cell.accessoryType = .disclosureIndicator
        }
        return cell
        
    }
    
    
}

// MARK: UITableViewDelegate
extension DBListTableViewController {
    override public func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .destructive, title: NSLocalizedString("Delete", comment: ""), handler: { [unowned self] (action, indexPath) in
            
            // remove document at index
            
             self.deleteDatabaseAtIndex(indexPath)
            
            
        })
        return [deleteAction]
        
    }

}

//MARK:Navigation
extension DBListTableViewController {
    override public func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            switch segue.identifier ?? "" {
            case UIStoryboard.StoryboardSegue.listDocs.identifier:
                if let destVC = segue.destination as? DocListTableViewController {
                    if let selectedIndex = tableView.indexPathForSelectedRow {
                        if  let name  = dbNames?[selectedIndex.row] {
                            destVC.dbName = name
                        }
                    }
                }
            default:
                print("Unhandled segue \(String(describing: segue.identifier))")
            }
    }
}
