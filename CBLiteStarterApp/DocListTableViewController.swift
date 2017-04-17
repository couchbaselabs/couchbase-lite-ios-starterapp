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
        case owner = "owner"
        case tag = "tag"
    }
    
    let kDbName:String = "demo" // CHANGE THIS TO THE NAME OF DATABASE THAT YOU HAVE CREATED ON YOUR SYNC GATEWAY VIA ADMIN PORT
    
    let kPublicDoc:String = "public"
    
    // This is the remote URL of the Sync Gateway (public Port)
    let kRemoteSyncUrl = "http://localhost:4984"
 
    fileprivate let cbManager:CBLManager = CBLManager.sharedInstance()

    fileprivate var db:CBLDatabase?
    
    fileprivate var loggedInUser:String?
    
    fileprivate var docsEnumerator:CBLQueryEnumerator? {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    fileprivate var liveQuery:CBLLiveQuery?
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.updateUIWithAddButton()
        self.updateUIWithLogoutButton()
        self.title = NSLocalizedString("Documents", comment: "")
    }
    
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.loginUser()
        
    }
    
    deinit {
        self.deinitialize()
        
    }
    
    func updateUIWithAddButton() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(handleAddDocumentRequest))
    }
    
    func updateUIWithLogoutButton() {
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Logout", comment: ""), style: .plain, target: self, action: #selector(handleLogout))
    }
    
    
    func updateUIWithLoginButton() {
        self.navigationItem.leftBarButtonItem = nil
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Login", comment: ""), style: .plain, target: self, action: #selector(loginUser))
    }
    
    fileprivate func deinitialize() {
        // Stop observing changes to the database that affect the query
        self.removeLiveQueryObserverAndStopObserving()
        
        // Stop observing remote db changes
        self.removeRemoteDatabaseObserverAndStopObserving()
        
        
        // Close Database handle . stops all replications
        do {
            try self.db?.close()
            docsEnumerator = nil
            self.loginUser()
        }
        catch {
        }

    }
}


// MARK: Login
extension DocListTableViewController {
     func loginUser() {
        let alertController = UIAlertController(title: nil,
                                                message: NSLocalizedString("Login", comment: ""),
                                                preferredStyle: .alert)
        var nameTitleTextField: UITextField!
        var passwordTextField: UITextField!
        alertController.addTextField(configurationHandler: { (textField) in
            textField.placeholder = NSLocalizedString("User Name", comment: "")
            nameTitleTextField = textField
        })
        
        alertController.addTextField(configurationHandler: { (textField) in
            textField.placeholder = NSLocalizedString("Password", comment: "")
            textField.isSecureTextEntry = true
            passwordTextField = textField
            
        })
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Login", comment: ""), style: .default) { _ in
            guard let name = nameTitleTextField.text, let password = passwordTextField.text else {
                print("Cannot open database without signing in ")
                return
            }
            self.updateUIWithLogoutButton()
            self.loggedInUser = name
            if self.openDatabaseForUser( name, password: password) == true {
                self.getAllDocumentForUserDatabase()
            }
            
        })
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default) { _ in
            self.updateUIWithLoginButton()
        })
        self.present(alertController, animated: true, completion: nil)
        
    }
    func handleAddDocumentRequest() {
        var docNameTextField:UITextField!
        var docOverviewTextField:UITextField!
        var tagTextField:UITextField!
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
        alertController.addTextField(configurationHandler: { (textField) in
            textField.placeholder = NSLocalizedString("Specify \"public\" for documents that can be shared. Blank otherwise", comment: "")
            tagTextField = textField
        })
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Create", comment: ""), style: .default) { _ in
            let docName = docNameTextField.text ?? "\(String(describing: self.kDbName))_\(String(describing: self.docsEnumerator?.count))"
            let docOverview = docOverviewTextField.text ?? ""
            let tag = (tagTextField.text == self.kPublicDoc) ? self.kPublicDoc: "_\(String(describing: self.loggedInUser))"
            self.createDocWithName(docName, overview:docOverview,tag:tag)
            
        })
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default) { _ in
            
        })
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    func handleLogout() {
        self.deinitialize()
    }
}

// MARK: CBL Related
extension DocListTableViewController {
    
    // Creates a DB in local store if it does not exist
    fileprivate func openDatabaseForUser(_ user:String, password:String)-> Bool {
        
        do {
            // 1: Set Database Options
            let options = CBLDatabaseOptions()
            options.storageType  = kCBLSQLiteStorage
            options.create = true
            
            // 2: Create a DB for logged in user if it does not exist else return handle to existing one
            self.db  = try cbManager.openDatabaseNamed(user.lowercased(), with: options)
            self.showAlertWithTitle(NSLocalizedString("Success!", comment: ""), message: NSLocalizedString("Database \(user) was opened succesfully at path \(CBLManager.defaultDirectory())", comment: ""))
            
            // 3. Start replication with remote Sync Gateway
            startDatabaseReplicationForUser(user, password: password)
            return true
        }
        catch  {
            print("Failed to create database named \(user)")
            self.showAlertWithTitle(NSLocalizedString("Error!", comment: ""), message: NSLocalizedString("Database \(user) open failed:\(error.localizedDescription)", comment: ""))
            return false
    
        }
    }
    
    // Start Replication/ Synching with remote Sync Gateway
    fileprivate func startDatabaseReplicationForUser(_ user:String, password:String) {
    
         // 1. Create Authenticator to be sent with every request.
        let auth = CBLAuthenticator.basicAuthenticator(withName: user, password: password)
    
        // 2. Create a Pull replication to start pulling from remote source
        self.startPullReplicationWithAuthenticator(auth)
    
        // 3. Create a Push replication to start pushing to  remote source
        self.startPushReplicationWithAuthenticator(auth)
        
        // 4: Start Observing push/pull changes to/from remote database
        self.addRemoteDatabaseChangesObserverAndStartObserving()

    }
    
    fileprivate func startPullReplicationWithAuthenticator(_ auth:CBLAuthenticatorProtocol?) {
        
        // 1: Create a Pull replication to start pulling from remote source
        let pullRepl = db?.createPullReplication(URL(string: kDbName, relativeTo: URL.init(string: kRemoteSyncUrl))!)
        
        // 2. Set Authenticator for pull replication
        pullRepl?.authenticator = auth
        
        // Continuously look for changes
        pullRepl?.continuous = true
        
        // Optionally, Set channels from which to pull
        // pullRepl?.channels = [...]
        
        // 4. Start the pull replicator
        pullRepl?.start()
       
    }
    
    fileprivate func startPushReplicationWithAuthenticator(_ auth:CBLAuthenticatorProtocol?) {
        
        // 1: Create a push replication to start pushing to remote source
        let pushRepl = db?.createPushReplication(URL(string: kDbName, relativeTo: URL.init(string:kRemoteSyncUrl))!)
        
        // 2. Set Authenticator for push replication
        pushRepl?.authenticator = auth
        
        // Continuously push  changes
        pushRepl?.continuous = true
        
        
        // 3. Start the push replicator
        pushRepl?.start()
        
    }
    
    
    fileprivate func addRemoteDatabaseChangesObserverAndStartObserving() {
        
        
        // 1. iOS Specific. Add observer to the NOtification Center to observe replicator changes
        NotificationCenter.default.addObserver(forName: NSNotification.Name.cblReplicationChange, object: nil, queue: nil) {
            [unowned self] (notification) in
          
            // Handle changes to the replicator status - Such as displaying progress
            // indicator when status is .running
            print ("\(String(describing: self.db)) was updated")
            
        }
        
    }
    
    fileprivate func removeRemoteDatabaseObserverAndStopObserving() {
        // 1. iOS Specific. Remove observer from Replication state changes
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.cblReplicationChange, object: nil)
        
    }
    
    
   

    // Fetch all Documents in Database
    fileprivate func getAllDocumentForUserDatabase() {
        do {
            
            
            // 1. Create Query to fetch all documents. You can set a number of properties on the query object
            liveQuery = self.db?.createAllDocumentsQuery().asLive()
            
            guard let liveQuery = liveQuery else {
                return
            }
            
            // 2: You can optionally set a number of properties on the query object.
            // Explore other properties on the query object
            liveQuery.limit = UInt(UINT32_MAX) // All documents
            
            //   query.postFilter =
            
            //3. Start observing for changes to the database
            self.addLiveQueryObserverAndStartObserving()
            
            
            // 4: Run the query to fetch documents asynchronously
            liveQuery.runAsync({ (enumerator, error) in
                switch error {
                case nil:
                    // 5: The "enumerator" is of type CBLQueryEnumerator and is an enumerator for the results
                    self.docsEnumerator = enumerator
                    
                    
                default:
                    self.showAlertWithTitle(NSLocalizedString("Data Fetch Error!", comment: ""), message: error.localizedDescription)
                }
            })

            
        }
        catch  {
            print("Failed to open database named \(String(describing: kDbName))")
            self.showAlertWithTitle(NSLocalizedString("Error!", comment: ""), message: NSLocalizedString("Database \(String(describing: kDbName)) open failed:\(error.localizedDescription)", comment: ""))
            
        }

    }
    
    
    // Creates a Document in database
    fileprivate func createDocWithName(_ name:String, overview:String, tag:String) {
        do {
            // 1: Create Document with unique Id else open existing one
            let doc = self.db?.createDocument()
            
            
            // 2: Construct user properties Object
            let userProps = [DocumentUserProperties.name.rawValue:name,
                             DocumentUserProperties.overview.rawValue:overview,
                             DocumentUserProperties.tag.rawValue:tag,
                             DocumentUserProperties.owner.rawValue:loggedInUser ?? ""] as [String : Any]
            
           
            // 3: Add a new revision with specified user properties
            let _ = try doc?.putProperties(userProps)
            
            
        }
        catch  {
            print("Failed to create database named \(name)")
            self.showAlertWithTitle(NSLocalizedString("Error!", comment: ""), message: NSLocalizedString("Document \(name) open failed:\(error.localizedDescription)", comment: ""))
            
        }
    }
    
    // Updates the Document in database
    fileprivate func updateDocWithName(_ name:String, overview:String, tag:String, atIndex index:Int) {
        do {
            // 1: Get the document associated with the row
            let doc = self.docAtIndex(index)
            
            print("doc to update  \(String(describing: doc?.userProperties))")
            
      
            // 2: Construct user properties Object with updated values
            var userProps = [DocumentUserProperties.name.rawValue:name,
                             DocumentUserProperties.overview.rawValue:overview,
                             DocumentUserProperties.tag.rawValue:tag,
                             DocumentUserProperties.owner.rawValue:loggedInUser ?? ""] as [String : Any]
            
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
            
            
            print("doc to remove  \(String(describing: doc?.userProperties))")
            
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
                print ("No document at index!")
                return
            }
            
            guard  let userProp = doc.userProperties else {
                print ("Document to edit has no current user properties!")
                return
            }
            
            let alertController = UIAlertController(title: nil,
                                                    message: NSLocalizedString("Update Document", comment: ""),
                                                    preferredStyle: .alert)
            var docTitleTextField: UITextField!
            var docOverviewTextField: UITextField!
            
            alertController.addTextField(configurationHandler: { (textField) in
                textField.text = userProp[DocumentUserProperties.name.rawValue] as? String
                docTitleTextField = textField
            })
            
            alertController.addTextField(configurationHandler: { (textField) in
                textField.text = userProp[DocumentUserProperties.overview.rawValue] as? String
                docOverviewTextField = textField
            })
            
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Update", comment: ""), style: .default) { _ in
                // update document at index
                let row = indexPath.row
                // Document tag is not updated
                guard let currTag = userProp[DocumentUserProperties.tag.rawValue] as? String else {
                    print("Tag does not exist for document to be updated!")
                    return
                }
                self.updateDocWithName(docTitleTextField.text ?? "", overview: docOverviewTextField.text ?? "", tag:currTag ,atIndex: row )
                
              })
            
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default) { _ in
                
            })
            self.present(alertController, animated: true, completion: nil)
            
            
        })
        return [deleteAction,editAction]

    }
}



// MARK: KVO
extension DocListTableViewController {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        print(#function)
        if keyPath == "rows" {
            self.docsEnumerator = self.liveQuery?.rows
            tableView.reloadData()
        }
    }
}
