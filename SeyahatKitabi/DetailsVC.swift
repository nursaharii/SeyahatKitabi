//
//  DetailsVC.swift
//  SeyahatKitabi
//
//  Created by Nurşah on 26.11.2021.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class DetailsVC: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var saveBtn: UIButton!
    var locationManager = CLLocationManager()
    @IBOutlet weak var comment: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    
    var selectedName = ""
    var selectedId : UUID?
    var selectedLatitude = Double()
    var selectedLongitude = Double()
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLoc(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 2
        mapView.addGestureRecognizer(gestureRecognizer)
        if selectedName != "" {
            saveBtn.isEnabled = true
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchReq = NSFetchRequest<NSFetchRequestResult>(entityName: "Locations")
            let idString = selectedId?.uuidString
            fetchReq.predicate = NSPredicate(format: "id = %@", idString!)
            fetchReq.returnsObjectsAsFaults = false
            
            do {
               let results = try context.fetch(fetchReq)
                if results.count > 0 {
                    for i in results as! [NSManagedObject] {
                        if let isim = i.value(forKey: "name") as? String{
                            name.text = isim
                        }
                        if let yorum = i.value(forKey: "comment") as? String {
                            comment.text = yorum
                        }
                        if let enlem = i.value(forKey: "latitude") as? Double {
                            annotationLatitude = enlem
                            if let boylam = i.value(forKey: "longitude") as? Double {
                                annotationLongitude = boylam
                                let annotation = MKPointAnnotation()
                                annotation.title = name.text
                                annotation.subtitle = comment.text
                                let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                annotation.coordinate = coordinate
                                self.mapView.addAnnotation(annotation)
                                locationManager.stopUpdatingLocation()
                                let span = MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
                                let region = MKCoordinateRegion(center: coordinate, span: span)
                                mapView.setRegion(region, animated: true)
                            }
                        }
                    }
                }
            } catch  {
               print("Error")
            }
        }
        else {
            saveBtn.isEnabled = false
        }
        
        
    }
    
    
    @objc func hideKeyboard(){
        view.endEditing(true)
    }
    @objc func chooseLoc(gestureRecognizer : UILongPressGestureRecognizer){
        
        if gestureRecognizer.state == .began {
            let touchedPoint = gestureRecognizer.location(in: self.mapView)
            let touchedCoordinates = self.mapView.convert(touchedPoint, toCoordinateFrom: self.mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedCoordinates
            annotation.title = name?.text
            annotation.subtitle = comment?.text
            self.mapView.addAnnotation(annotation)
            selectedLatitude = touchedCoordinates.latitude
            selectedLongitude = touchedCoordinates.longitude
            saveBtn.isEnabled = true
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if selectedName == "" {
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: true)
        }
    }
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.black
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        }
        else {
            pinView?.annotation = annotation
        }
        return pinView
    }
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if name.text != "" {
            let newLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            CLGeocoder().reverseGeocodeLocation(newLocation) { (placemarks, error) in
                
                if let placemark = placemarks {
                    if placemark.count > 0 {
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.selectedName
                        let launcOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launcOptions)
                        
                    }
                }
            }
        }
    }
    

    @IBAction func save(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let newLocation = NSEntityDescription.insertNewObject(forEntityName: "Locations", into: context)
        
        newLocation.setValue(name.text, forKey: "name")
        newLocation.setValue(comment.text, forKey: "comment")
        newLocation.setValue(UUID(), forKey: "id")
        newLocation.setValue(selectedLongitude, forKey: "longitude")
        newLocation.setValue(selectedLatitude, forKey: "latitude")
        
        do {
            try context.save()
        } catch  {
            print("Error")
        }
        NotificationCenter.default.post(name: NSNotification.Name.init(rawValue: "newData"), object: nil)
        self.navigationController?.popViewController(animated: true)
    }
    

}
