//
//  Libro+CoreDataProperties.swift
//  Mis libros
//
//  Created by Arturo Rivas on 24/4/16.
//  Copyright © 2016 Arturo Rivas. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Libro {

    @NSManaged var titulo: String?
    @NSManaged var autor: String?
    @NSManaged var portada: NSData?
    @NSManaged var isbn: String?

}
