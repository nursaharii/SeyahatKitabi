//
//  ViewController.swift
//  SeyahatKitabi
//
//  Created by Nurşah on 26.11.2021.
//

import UIKit
import CoreData

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = nameArry[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nameArry.count
    }
    var selectedName = ""
    var selectedId : UUID?
    var nameArry = [String]()
    var idArry = [UUID]()
   // var pins = [String]()
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addFunc))
        getData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name.init(rawValue: "newData"), object: nil)
    }

    @objc func addFunc (){
        selectedName = ""
        performSegue(withIdentifier: "toDetailsVC", sender: nil)
    }
    
    @objc func getData(){
        nameArry.removeAll(keepingCapacity: false)
        idArry.removeAll(keepingCapacity: false)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let fetchReq = NSFetchRequest<NSFetchRequestResult>(entityName: "Locations")
        fetchReq.returnsObjectsAsFaults = false
        do {
           let results = try context.fetch(fetchReq)
            for i in results as! [NSManagedObject]{
                if let name = i.value(forKey: "name") as? String{
                    self.nameArry.append(name)
                }
                if let id = i.value(forKey: "id") as? UUID{
                    self.idArry.append(id)
                }
                self.tableView.reloadData()
            }
            
        } catch  {
            print("Hata")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetailsVC" {
            let destinationVC = segue.destination as! DetailsVC
            destinationVC.selectedName = selectedName
            destinationVC.selectedId = selectedId
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedName = nameArry[indexPath.row]
        selectedId = idArry[indexPath.row]
        performSegue(withIdentifier: "toDetailsVC", sender: nil)
    }
    func tableView(_ tableView : UITableView, commit EditingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath){
        if EditingStyle == .delete {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            let idString = idArry[indexPath.row].uuidString
            let fetchReq = NSFetchRequest<NSFetchRequestResult>(entityName: "Locations")
            fetchReq.predicate = NSPredicate(format: "id = %@", idString)
            fetchReq.returnsObjectsAsFaults = false
            
            do {
               let results = try context.fetch(fetchReq)
                for i in results as! [NSManagedObject]{
                    if let id = i.value(forKey: "id") as? UUID{
                        if id == idArry[indexPath.row] {
                            context.delete(i)
                            nameArry.remove(at: indexPath.row)
                            idArry.remove(at: indexPath.row)
                            self.tableView.reloadData()
                            do {
                                try context.save()
                            } catch  {
                                print("Error")
                            }
                            break
                        }
                    }
                }
                
            } catch  {
                print("Error")
            }
        }
    }
}

