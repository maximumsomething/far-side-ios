//
//  OWMiscellaneousData.swift
//  The Far Side
//
//  Created by Max on 11/1/14.
//  Copyright (c) 2014 The Company. All rights reserved.
//

import UIKit

@objc class OWMiscellaneousData: NSObject, NSCoding {
    
    var landLat:NSNumber!
    var landLng:NSNumber!
    
    var address: String!
    var locality:String!
    
    
    
    @objc class var sharedData:OWMiscellaneousData {
        get {
            let delegate = UIApplication.sharedApplication().delegate! as! OWAppDelegate
            return delegate.miscellaneousData
            
        }
		set (toSet) {
			let delegate = UIApplication.sharedApplication().delegate! as! OWAppDelegate
			delegate.miscellaneousData = toSet
		}
    }
	
	private let landLatKey = "landLat"
	private let landLngKey = "landLng"
	private let addressKey = "address"
	private let localityKey = "locality"
	
	func encodeWithCoder(aCoder: NSCoder) {
		aCoder.encodeObject(landLat, forKey: landLatKey)
		aCoder.encodeObject(landLng, forKey: landLngKey)
		aCoder.encodeObject(address, forKey: addressKey)
		aCoder.encodeObject(locality, forKey: localityKey)
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init()
		landLat = aDecoder.decodeObjectForKey(landLatKey)   as! NSNumber!
		landLng = aDecoder.decodeObjectForKey(landLngKey)   as! NSNumber!
		address = aDecoder.decodeObjectForKey(addressKey)   as! String!
		locality = aDecoder.decodeObjectForKey(localityKey) as! String!
	}
	override init() {
		super.init()
	}
}
