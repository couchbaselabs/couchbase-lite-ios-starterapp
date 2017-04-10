//
//  DocListTableViewController.swift
//  CBLiteStarterApp
//
//  Created by Priya Rajagopal on 4/6/17.
//  Copyright © 2017 Couchbase Inc. All rights reserved.
//

import Foundation

class DocListTableViewController:UITableViewController {
    
    enum DocumentUserProperties:String {
        case name = "name"
        case overview = "overview"
    }
    
    var dbName:String? {
        didSet {
            getAllDocumentForDatabase()
        }
    }
    fileprivate let cbManager:CBLManager = CBLManager.sharedInstance()

    fileprivate var db:CBLDatabase?
    
    fileprivate var docsEnumerator:CBLQueryEnumerator? {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    fileprivate var liveQuery:CBLLiveQuery?
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.updateUIWithAddButton()
        self.title = NSLocalizedString("Documents", comment: "")
    }
    
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.updateUIWithAddButton()
        
    }
    
    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Stop observing changes to the database that affect the query
        self.removeLiveQueryObserverAndStopObserving()
        
    }
    
    private func updateUIWithAddButton() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(handleAddDocumentRequest))
    }
}

// MARK: CBL Related
extension DocListTableViewController {
    
    
    // Creates a DB in local store
    fileprivate func getAllDocumentForDatabase() {
        do {
            guard let dbName = dbName else {
                print("Invalid db name")
                return
            }
            // 1. Get handle to DB with specified name
            self.db = try cbManager.existingDatabaseNamed(dbName)
            
            
            // 2. Create Query to fetch all documents. You can set a number of properties on the query object
            liveQuery = self.db?.createAllDocumentsQuery().asLive()
            
            guard let liveQuery = liveQuery else {
                return
            }
            
            // 3: You can optionally set a number of properties on the query object.
            // Explore other properties on the query object
            liveQuery.limit = UInt(UINT32_MAX) // All documents
            
            //   query.postFilter =
            
            //4. Start observing for changes to the database
            self.addLiveQueryObserverAndStartObserving()
            
            
            // 5: Run the query to fetch documents asynchronously
            liveQuery.runAsync({ (enumerator, error) in
                switch error {
                case nil:
                    // 6: The "enumerator" is of type CBLQueryEnumerator and is an enumerator for the results
                    self.docsEnumerator = enumerator
                    
                    
                default:
                    self.showAlertWithTitle(NSLocalizedString("Data Fetch Error!", comment: ""), message: error.localizedDescription)
                }
            })
            
        }
        catch  {
            print("Failed to open database named \(String(describing: dbName))")
            self.showAlertWithTitle(NSLocalizedString("Error!", comment: ""), message: NSLocalizedString("Database \(String(describing: dbName)) open failed:\(error.localizedDescription)", comment: ""))
            
        }

    }
    
    
    // Creates a Document in database
    fileprivate func createDocWithName(_ name:String, overview:String) {
        do {
            // 1: Create Document with unique Id
            let doc = self.db?.createDocument()
            
            print("doc to add  \(String(describing: doc?.userProperties))")
            
            // 2: Construct user properties Object
            let userProps = [DocumentUserProperties.name.rawValue:name,DocumentUserProperties.overview.rawValue:overview]
            
           
            // 3: Add a new revision with specified user properties
            let _ = try doc?.putProperties(userProps)
            
        }
        catch  {
            print("Failed to create database named \(name)")
            self.showAlertWithTitle(NSLocalizedString("Error!", comment: ""), message: NSLocalizedString("Document \(name) creation failed:\(error.localizedDescription)", comment: ""))
            
        }
    }
    
    // Updates the Document in database
    fileprivate func updateDocWithName(_ name:String, overview:String, atIndex index:Int) {
        do {
            // 1: Get the document associated with the row
            let doc = self.docAtIndex(index)
            
            print("doc to add  \(String(describing: doc?.userProperties))")
            
            // 2: Construct user properties Object with updated values
            var userProps = [DocumentUserProperties.name.rawValue:name,DocumentUserProperties.overview.rawValue:overview]
            
            // 3: If a previous revision of document exists, make sure to specify that. SInce its an update, it should exist!
            if let revId = doc?.currentRevisionID  {
                
                userProps["_rev"] = revId
            }
            
            // 4: Add a new revision with specified user properties
            let _ = try doc?.putProperties(userProps)
            
        }
        catch  {
            print("Failed to create database named \(name)")
            self.showAlertWithTitle(NSLocalizedString("Error!", comment: ""), message: NSLocalizedString("Document \(name) update failed:\(error.localizedDescription)", comment: ""))
            
        }
    }
    
    // Deletes a Document in database
    fileprivate func deleteDocAtIndex(_ index:Int) {
        do {
            
            // 1: Get the document associated with the row
            let doc = self.docAtIndex(index)
            
            
            print("doc ro remove  \(String(describing: doc?.userProperties))")
            
            // 2: Delete the document
            try doc?.delete()
            

        }
        catch  {
            self.showAlertWithTitle(NSLocalizedString("Error!", comment: ""), message: NSLocalizedString("Document Deletion failed:\(error.localizedDescription)", comment: ""))
            
        }
    }

    
    // Helper function to get document at specified index
    fileprivate func docAtIndex(_ index:Int) -> CBLDocument? {
        // 1. Get the CBLQueryRow object at specified index
        let queryRow = self.docsEnumerator?.row(at: UInt(index))
        
        
        // 2: Get the document associated with the row
        let doc = queryRow?.document
        
        return doc
    }
    
    fileprivate func addLiveQueryObserverAndStartObserving() {
        guard let liveQuery = liveQuery else {
            return
        }
        
        // 1. iOS Specific. Add observer to the live Query object
        liveQuery.addObserver(self, forKeyPath: "rows", options: NSKeyValueObservingOptions.new, context: nil)
        
        // 2. Start observing changes
        liveQuery.start()
    
    }
    
    fileprivate func removeLiveQueryObserverAndStopObserving() {
        guard let liveQuery = liveQuery else {
            return
        }
         // 1. iOS Specific. Remove observer from the live Query object
        liveQuery.removeObserver(self, forKeyPath: "rows")
        
        // 2. Stop observing changes
        liveQuery.stop()
        
    }

    
}

//MARK:UITableViewDataSource
extension DocListTableViewController {
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Int (self.docsEnumerator?.count ?? 0)
    }
    
    
    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DocumentCell") else { return UITableViewCell.init()}
        if let queryRow = docsEnumerator?.row(at: UInt(indexPath.row)) {
            print ("row is \(String(describing: queryRow.document))")
            if let userProps = queryRow.document?.userProperties ,let title = userProps[DocumentUserProperties.name.rawValue] as? String , let overview = userProps[DocumentUserProperties.overview.rawValue] as? String{
                cell.textLabel?.text = title
                cell.detailTextLabel?.text = overview
                
                cell.selectionStyle = .default

            }
        }
        return cell
        
    }
    
    
    
}

//MARK: UITableViewDelegate
extension DocListTableViewController {
    override public func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .destructive, title: NSLocalizedString("Delete", comment: ""), handler: { [unowned self] (action, indexPath) in
            
            // remove document at index
            let row = indexPath.row
            self.deleteDocAtIndex(row)
            
            
        })
        let editAction = UITableViewRowAction(style: .normal, title: NSLocalizedString("Edit", comment: ""), handler: { [unowned self] (action, indexPath) in
            
            let row = indexPath.row
            
            guard let doc = self.docAtIndex(row) else {
                print ("No document at index")
                return
            }
            
            let userProp = doc.userProperties
            
            let alertController = UIAlertController(title: nil,
                                                    message: NSLocalizedString("Update Document", comment: ""),
                                                    preferredStyle: .alert)
            var docTitleTextField: UITextField!
            var docOverviewTextField: UITextField!
            alertController.addTextField(configurationHandler: { (textField) in
                textField.text = userProp?[DocumentUserProperties.name.rawValue] as? String
                docTitleTextField = textField
            })
            
            alertController.addTextField(configurationHandler: { (textField) in
                textField.text = userProp?[DocumentUserProperties.overview.rawValue] as? String
                docOverviewTextField = textField
            })
            
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Update", comment: ""), style: .default) { _ in
                // update document at index
                let row = indexPath.row
                self.updateDocWithName(docTitleTextField.text ?? "", overview: docOverviewTextField.text ?? "", atIndex: row)
                
              })
            
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default) { _ in
                
            })
            self.present(alertController, animated: true, completion: nil)
            
            
        })
        return [deleteAction,editAction]

    }
}

//MARK: UI Stuff
extension DocListTableViewController {
    func handleAddDocumentRequest() {
        var docNameTextField:UITextField!
        var docOverviewTextField:UITextField!
        
        let alertController = UIAlertController(title: nil,
                                                message: NSLocalizedString("Add Document", comment: ""),
                                                preferredStyle: .alert)
        alertController.addTextField(configurationHandler: { (textField) in
            textField.placeholder = NSLocalizedString("Enter Document Name", comment: "")
            docNameTextField = textField
        })
        alertController.addTextField(configurationHandler: { (textField) in
            textField.placeholder = NSLocalizedString("A one-line description", comment: "")
            docOverviewTextField = textField
        })
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Create", comment: ""), style: .default) { _ in
            let docName = docNameTextField.text ?? "\(String(describing: self.dbName))_\(String(describing: self.docsEnumerator?.count))"
            let docOverview = docOverviewTextField.text ?? ""
            self.createDocWithName(docName, overview:docOverview)
            
  
        })
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default) { _ in
            
        })
        self.present(alertController, animated: true, completion: nil)

    
    
    }
}


// MARK: KVO
extension DocListTableViewController {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "rows" {
            self.docsEnumerator = self.liveQuery?.rows
            tableView.reloadData()
        }
    }
}
