//
//  OWGoogleMapsDelegateToCallback.swift
//  The Far Side
//
//  Created by Max on 11/4/14.
//  Copyright (c) 2014 The Company. All rights reserved.
//

import UIKit

@objc class OWGoogleMapsDelegateToCallback : NSObject, GMSMapViewDelegate {
    
    //var mapView:GMSMapView!
    var animationType:String!
    var callback:(() -> ())!
    
    func mapView(mapView:GMSMapView, idleAtCameraPosition:GMSCameraPosition) {
        
        mapView.delegate = nil
        switch animationType {
        case "zoom", "pan":
            self.callback()
        default:
            doNothing()
        }
    }
    
    func animateZoom(zoom:Float, mapView:GMSMapView, completion:() -> ()) {
        mapView.delegate = self;
        mapView.animateToZoom(zoom)
        animationType = "zoom"
        callback = completion
    }
    
    func panTo(location:CLLocationCoordinate2D, mapView:GMSMapView, completion: () -> ()) {
        mapView.delegate = self;
        mapView.animateToLocation(location)
        animationType = "pan"
        callback = completion
    }
    
    func doNothing() {
        
    }
}
