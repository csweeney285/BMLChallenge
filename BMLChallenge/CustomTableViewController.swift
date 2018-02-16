//
//  CustomTableViewController.swift
//  BMLChallenge
//
//  Created by Conor Sweeney on 2/15/18.
//  Copyright © 2018 csweeney. All rights reserved.
//

import UIKit
import ReactiveJSON
import ReactiveSwift
import Result

struct JSONClient: Singleton, ServiceHost {
    
    typealias Instance = JSONClient
    private(set) static var shared = Instance()
    
    static var scheme: String { return "https" }
    static var host: String { return "jsonplaceholder.typicode.com" }
    static var path: String? { return nil }
}

//this will be reused for users and comments
class UserObject: NSObject {
    var name: String = ""
    var id: Int = -1
}

class CustomTableViewController: UITableViewController {
    var userArray :Array = [UserObject]()
    var otherData :Array = [String]()
    var userBool : Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //download user data
        //this will be displayed first
        DispatchQueue.global(qos: .background).async {
            self.requestWithEndPoint(value: "users")
        }
        
        //add background image
        let backgroundImage = UIImage(named: "spoke.jpg")
        let imageView = UIImageView(image: backgroundImage)
        imageView.contentMode = UIViewContentMode.scaleAspectFill
        imageView.alpha = 0.4
        tableView.backgroundView = imageView
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func requestWithEndPoint(value: String) {
        
        JSONClient
            .request(endpoint: value)
            .startWithResult { (result: Result<[Any], NetworkError>) in
                switch result {
                case .success:
                    //put it into the user array
                    if value == "users"{
                        //parse and put into tableview
                        let users = result.value as! Array<Dictionary<String,Any>>;
                        for user in users {
                            let newUser = UserObject()
                            newUser.id = user["id"] as! Int
                            newUser.name = user["name"] as! String
                            self.userArray.append(newUser)
                        }
                    }
                    else{
                        //parse and put into tableview
                        let data = result.value as! Array<Dictionary<String,Any>>;
                        var key = "name"
                        if value.range(of:"posts") != nil{
                            key = "title"
                        }
                        for obj in data {
                            let name = obj[key] as! String
                            self.otherData.append(name)
                        }

                    }
                    //reload tableview on mainthread
                    DispatchQueue.main.async {
                        self.tableView.allowsSelection = true
                        self.tableView.reloadData()
                    }
               
                case .failure:
                    print("error")
                }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if userBool {
            return userArray.count
        }
        return otherData.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        if userBool {
            cell.textLabel?.text = userArray[indexPath.row].name
        }
        else{
            cell.textLabel?.text = otherData[indexPath.row]
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if userBool {
            let selectedUser = userArray[indexPath.row]
            let alertController = UIAlertController(title: "\(selectedUser.name)", message: "What would you like to see?", preferredStyle: .alert)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { action in
                
            }
            alertController.addAction(cancelAction)
            
            let commentAction = UIAlertAction(title: "Comments", style: .default) { action in
                self.userBool = false
                self.tableView.allowsSelection = false
                DispatchQueue.global(qos: .background).async {
                    self.requestWithEndPoint(value: "comments?userId=\(selectedUser.id)")
                }
            }
            alertController.addAction(commentAction)
            
            let postsAction = UIAlertAction(title: "Posts", style: .default) { action in
                self.userBool = false
                self.tableView.allowsSelection = false
                DispatchQueue.global(qos: .background).async {
                    self.requestWithEndPoint(value: "posts?userId=\(selectedUser.id)")
                }
            }
            alertController.addAction(postsAction)
            
            tableView.deselectRow(at: indexPath, animated: true)
            
            self.present(alertController, animated: true) {
            }
        }
        else{
        let alertController = UIAlertController(title: "Return", message: "Would you like to return to the users page?", preferredStyle: .alert)
            
            let yesAction = UIAlertAction(title: "Yes", style: .default) { action in
                self.userBool = true
                //empty array for memory space
                self.otherData.removeAll()
                //reload tableview on mainthread
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
            
            alertController.addAction(yesAction)
            let cancelAction = UIAlertAction(title: "No", style: .cancel) { action in
                
            }
            alertController.addAction(cancelAction)
            

            tableView.deselectRow(at: indexPath, animated: true)
            
            self.present(alertController, animated: true) {
            }
        }

    }
}
