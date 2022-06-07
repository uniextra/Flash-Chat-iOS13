//
//  ChatViewController.swift
//  Flash Chat iOS13
//
//  Created by Angela Yu on 21/10/2019.
//  Copyright © 2019 Angela Yu. All rights reserved.
//

import UIKit
import Firebase

class ChatViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextfield: UITextField!
    
    let db = Firestore.firestore()
    
    var messages: [Message] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
//      tableView.delegate = self
        tableView.dataSource = self
        messageTextfield.delegate = self
        
        title = K.appName
        navigationItem.hidesBackButton = true
        tableView.register(UINib(nibName: K.cellNibName, bundle: nil), forCellReuseIdentifier: K.cellIdentifier)
        
        loadMessages()
        
    }
    
    func loadMessages(){
        
        db.collection(K.FStore.collectionName)
            .order(by: K.FStore.dateField)
            .limit(toLast: 15)
            .addSnapshotListener { QuerySnapshot, error in
            if let e = error{
                print(" hay un erorr \(e)")
            }else{
                if let snapshotDocuments = QuerySnapshot?.documents{
                    self.messages = []
                    for doc in snapshotDocuments{
                        let data = doc.data()
                        if let messageSender = data[K.FStore.senderField] as? String, let messageBody = data[K.FStore.bodyField] as? String {
                            let newMessage = Message(sender: messageSender, body: messageBody)
                            self.messages.append(newMessage)
                            DispatchQueue.main.async {
                                
                                self.tableView.reloadData()
                                
                                let numberOfSections = self.tableView.numberOfSections
                                let numberOfRows = self.tableView.numberOfRows(inSection: numberOfSections-1)

                                let indexPath = IndexPath(row: numberOfRows-1 , section: numberOfSections-1)
                                self.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
                                
                                
                                
                            }
                            
                        }
                        
                    }
                }
            }
            
            
        }
    }
    
    @IBAction func sendPressed(_ sender: UIButton) {
        messageTextfield.endEditing(true)
        
    }
    

    
    @IBAction func logOutPressed(_ sender: UIBarButtonItem) {
        
    let firebaseAuth = Auth.auth()
    do {
        try firebaseAuth.signOut()
        // nos lleva al root del navigation stack sin pasar por los pasos medios
        navigationController?.popToRootViewController(animated: true)
        
    } catch let signOutError as NSError {
      print("Error signing out: %@", signOutError)
    }
      
    }
    
}
//MARK: - UITableView
extension ChatViewController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let message = messages[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier, for: indexPath) as! MessageCell
        cell.lable.text = message.body
        
        if message.sender == Auth.auth().currentUser?.email{
            cell.leftImageView.isHidden = true
            cell.rightImageView.isHidden = false
            cell.messageBuble.backgroundColor = UIColor(named: K.BrandColors.lightPurple)
            cell.lable.textColor = UIColor(named: K.BrandColors.purple)
        }else{
            cell.leftImageView.isHidden = false
            cell.rightImageView.isHidden = true
            cell.messageBuble.backgroundColor = UIColor(named: K.BrandColors.purple)
            cell.lable.textColor = UIColor(named: K.BrandColors.lightPurple)
            
        }
        
        return cell
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
}

//MARK: - UITextDelegate
extension ChatViewController: UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        messageTextfield.endEditing(true)
        
        return true
    }

    private func textFieldDidEndEditing(_ textField: UITextField) -> Bool {
        if textField.text == ""{
            return true
        }else{
            textField.placeholder = "type a city"
            return false
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        let messageDate = Date().timeIntervalSince1970
        if let messageBody = messageTextfield.text , let messageSender = Auth.auth().currentUser?.email {
            db.collection(K.FStore.collectionName).addDocument(data: [K.FStore.senderField: messageSender, K.FStore.bodyField: messageBody, K.FStore.dateField: messageDate]) { (error) in
                DispatchQueue.main.async {
                    if let e = error {
                        self.messageTextfield.text = "error \(e)"
                    }else{
                        self.messageTextfield.text = ""
                    }
                }

            }
        }
        
        
        
    }
    
}
