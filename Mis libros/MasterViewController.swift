//
//  MasterViewController.swift
//  Mis libros
//
//  Created by Arturo Rivas on 18/4/16.
//  Copyright © 2016 Arturo Rivas. All rights reserved.
//

import UIKit
import CoreData

class LibroA {
    var título: String
    var autor: String
    var portada: UIImage?
    var isbn: String
    
    init(título: String, autor: String, portada: UIImage?, isbn: String) {
        self.título = título
        self.autor = autor
        self.portada = portada
        self.isbn = isbn
    }
}

class MasterViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    var detailViewController: DetailViewController? = nil
    var managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    var colección = [LibroA]()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.leftBarButtonItem = self.editButtonItem()

        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
        
        let petición = NSFetchRequest(entityName: "Libro")
        do {
            let datos = try managedObjectContext.executeFetchRequest(petición) as! [Libro]
            
            for dato in datos {
                let imagen: UIImage?
                if dato.portada != nil {
                    imagen = UIImage(data: dato.portada!)
                } else {
                    imagen = nil
                }
                let libro = LibroA(título: dato.titulo!, autor: dato.autor!, portada: imagen, isbn: dato.isbn!)
                colección.append(libro)
            }
        } catch {
            let nserror = error as NSError
            NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }

    override func viewWillAppear(animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.collapsed
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func insertarNuevoLibro(sender: AnyObject) {
        var campoTexto: UITextField!
        
        let alerta = UIAlertController(title: "Libros", message: "Busque su libro para ver los detalles y añadirlo a la lista", preferredStyle: .Alert)
        alerta.addTextFieldWithConfigurationHandler({(textField: UITextField) in
            textField.placeholder = "Introduca ISBN"
            campoTexto = textField
        })
        alerta.addAction(UIAlertAction(title: "Buscar", style: UIAlertActionStyle.Default, handler: {(action) in
            self.obtenerLibro(campoTexto.text!)
            self.tableView.reloadData()
        }))
        
        presentViewController(alerta, animated: true, completion: nil)
    }
    
    func obtenerLibro(isbn: String) {
        let libro = colección.filter({ libro in libro.isbn == isbn })
        if !libro.isEmpty {
            self.performSegueWithIdentifier("showDetail", sender: libro.first)
            return
        }
        
        let url = NSURL(string: "https://openlibrary.org/api/books?jscmd=data&format=json&bibkeys=ISBN:" + isbn)
        
        do {
            let data = try NSData(contentsOfURL: url!, options: .DataReadingMappedIfSafe)
            let respuesta = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableLeaves) as? [String: AnyObject]
            
            var losAutores: String = ""
            var elTítulo: String = ""
            var laImagen: UIImage?
            
            if respuesta != nil && !respuesta!.isEmpty {
                
                let libroData = NSEntityDescription.insertNewObjectForEntityForName("Libro", inManagedObjectContext: managedObjectContext) as! Libro
                
                var autores = respuesta!["ISBN:\(isbn)"]!["authors"] as? [[String: String]]
                if autores != nil {
                    
                    losAutores = autores![0]["name"]!
                    autores?.removeAtIndex(0)
                    
                    for autor in autores! {
                        losAutores = "\(losAutores), \(autor["name"]!)"
                    }
                }
                
                let título = respuesta!["ISBN:\(isbn)"]!["title"] as? String
                if título != nil {
                    elTítulo = título!
                }
                
                let cover = respuesta!["ISBN:\(isbn)"]!["cover"] as? [String: String]
                
                if cover != nil {
                    let imagenUrl = cover!["medium"]! as String
                    
                    libroData.portada = NSData(contentsOfURL: NSURL(string: imagenUrl)!)
                    laImagen = UIImage(data: libroData.portada!)
                    
                } else {
                    laImagen = nil
                    libroData.portada = nil
                }
                
                let libro = LibroA(título: elTítulo, autor: losAutores, portada: laImagen, isbn: isbn)
                colección.append(libro)
                
                libroData.autor = libro.autor
                libroData.titulo = libro.título
                libroData.isbn = libro.isbn
                
                do {
                    try managedObjectContext.save()
                } catch {
                    let nserror = error as NSError
                    NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                }
                
                self.performSegueWithIdentifier("showDetail", sender: nil)
            } else {
                let alert = UIAlertController(title: "Error", message: "No hay ningún libro con ese ISBN", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Aceptar", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }
            
        } catch {
            let alert = UIAlertController(title: "Error", message: "Hay problemas con la conexión a Internet. Inténtelo de nuevo más tarde.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Aceptar", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
            let libro: LibroA!
            if let indexPath = self.tableView.indexPathForSelectedRow {
                //let object = self.fetchedResultsController.objectAtIndexPath(indexPath)
                self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
                libro = self.colección[indexPath.row]
            } else if let mismoLibro = sender {
                libro = mismoLibro as! LibroA
            } else {
                libro = self.colección.last
            }
        
            controller.detailItem = libro
            controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
            controller.navigationItem.leftItemsSupplementBackButton = true
        }
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        //return self.fetchedResultsController.sections?.count ?? 0
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return colección.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        cell.textLabel?.text = colección[indexPath.row].título
        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let isbn = self.colección[indexPath.row].isbn
            
            let entidad = NSEntityDescription.entityForName("Libro", inManagedObjectContext: managedObjectContext)
            let petición = entidad?.managedObjectModel.fetchRequestFromTemplateWithName("petIsbn", substitutionVariables: ["isbn": isbn])
            
            do {
                let datos = try managedObjectContext.executeFetchRequest(petición!) as! [Libro]
                
                managedObjectContext.deleteObject(datos.first!)
                
                try managedObjectContext.save()
            } catch {
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
            }
            
            self.colección.removeAtIndex(indexPath.row)
            
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }

}

