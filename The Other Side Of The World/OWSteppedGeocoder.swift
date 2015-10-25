//
//  OWSteppedGeocoder.swift
//  The Far Side
//
//  Created by Max on 9/7/14.
//  Copyright (c) 2014 The Company. All rights reserved.
//

import Foundation
import CoreLocation

@objc class OWSteppedGeocoder: NSObject {
    
    @objc func geocode(address: String, failure: (reason:AnyObject) -> Void, success:(Double, Double) -> Void) -> Void {
        //let encodedAddress = address.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
		let encodedAddress = address.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.alphanumericCharacterSet())!
        
        let googleGeocodeRequest = NSURLRequest(URL: NSURL(string: "https://maps.googleapis.com/maps/api/geocode/json?address=\(encodedAddress)")!)
		
        if NSURLConnection.canHandleRequest(googleGeocodeRequest) {
            NSURLConnection.sendAsynchronousRequest(googleGeocodeRequest, queue: NSOperationQueue()) { (response, responseData, error) -> Void in
                if responseData != nil {
					let json = (try? NSJSONSerialization.JSONObjectWithData(responseData!, options: [])) as! [String: AnyObject]!
                    if (json != nil) {
                        
                        /*let results = json!["results"] as [[String: Any]]
                        let geometry = results[0]["geometry"] as [String: [String: Double]]
                        var location = geometry["location"]?
                        
                        let lat = location!["lat"]
                        let lng = location!["lng"]*/
						let results = json["results"] as! [[String : AnyObject]]
						if results.count == 0 { self.geocodeWithApple(address, success: success, failure: failure); return }
						
                        let location = (results[0]["geometry"]! as!
							[String : AnyObject])["location"] as! [String : Double]
                        
                        success((location["lat"])!, (location["lng"])!)
                    }
                    else { self.geocodeWithApple(address, success: success, failure: failure) }
                }
                else { self.geocodeWithApple(address, success: success, failure: failure) }
            }
        }
        else { self.geocodeWithApple(address, success: success, failure: failure) }
    }
    
    private func geocodeWithApple(address: String, success:(Double, Double) -> Void, failure: (AnyObject) -> Void) -> Void {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { (placemarks, error) -> Void in
            if placemarks != nil {
                let placemark = placemarks![0]
                let location = placemark.location!
                success(location.coordinate.latitude, location.coordinate.longitude)
            }
            else { failure(error!) }
        }
        
    }
    
    @objc func reverseGeocodeAndPackage(lat lat:Double, lng:Double, success:(NSDictionary) -> (), failure:(NSError?) -> ()) -> () {
		self.reverseGeocodeWithApple(lat: lat, lng: lng, success: success, failure: failure)
	}
	
	
	func reverseGeocodeWithGoogle(lat lat:Double, lng:Double, success:(NSDictionary) -> (), failure:(NSError?) -> ()) -> () {
	
        // the failure function will eithier accept a string explaining why it failed or an NSError
		
//		func realSuccess(arg:NSDictionary) {
//			func doIt() { success(arg) }
//			runClosureInMainThread(doIt)
//		}
//		func realFailure(arg:NSError?) {
//			func doIt() { failure(arg) }
//			runClosureInMainThread(doIt)
//		}
		

		
        let url = NSURL(string: "https://maps.googleapis.com/maps/api/geocode/json?latlng=\(lat),\(lng)")!
        let request = NSURLRequest(URL: url);
        if NSURLConnection.canHandleRequest(request) {
            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue()) { (response, responseData, error) in
				
                //NSLog(response.MIMEType!)
                if responseData != nil && (response!.MIMEType! == "text/json" || response!.MIMEType == "application/json") {
					#if DEBUG
					let responseString = NSString(data: responseData!, encoding: NSUTF8StringEncoding)
					#endif
					var json : [String: AnyObject]
					do {
						json = try NSJSONSerialization.JSONObjectWithData(responseData!, options:NSJSONReadingOptions()) as! [String: AnyObject]
					}
					catch {
						OWUtilities.ignorableProblemAlert()
						self.reverseGeocodeWithOSM(lat: lat, lng: lng, success: success, failure: failure)
						return
					}
					
                    /*let status = json["status"] as String
                    if  status == "OK" {
                    let results = json["results"] as [[String: Any]]
                    let address = results[0]["formatted_address"] as String*/
                    let status = json["status"] as! String
                    
                    if status == "OK" {
						let results = json["results"] as! [[ String: AnyObject ]]
                        let address = results[0]["formatted_address"] as! String
                        
                        // get the city
                        var city:String! = nil
                        var level = 0;
                        while (city == nil && level <= 2) {
                            level++;
							if level == 5 { break }
                            var typeShouldBe:String
							
                            switch level {
                            case 1:typeShouldBe = "locality"
							case 2:typeShouldBe = "administrative_area_level_5"
							case 3:typeShouldBe = "administrative_area_level_4"
                            case 4:typeShouldBe = "administrative_area_level_3"
                            default:
                                typeShouldBe = ""
								OWUtilities.ignorableProblemAlert()
								return
                            }
                            
                            for result in results {
                                if (result["types"] as! [String] == [typeShouldBe, "political"]) {
                                    city = result["formatted_address"] as! String!
                                }
                            }
                        }
                        var type = (results[0]["types"] as! [String])[0]
                        if type == "address"{ type = "a" }
						
						func finish() {
							let place = ["address": address, "type": type, "city": city] as [String : String]
							let dictToSend:[String: AnyObject] = ["lat":"\(lat)", "lng": "\(lng)", "place":place]
							
							success(dictToSend)
						}
						
						if city == nil {
							self.reverseGeocodeWithOSM(lat: lat, lng: lng, success: success, failure: { error in
								finish()
							})
							return
						}
						finish()
                    }
					else {
						self.reverseGeocodeWithOSM(lat: lat, lng: lng, success: success, failure: failure)
					}
                }
                else {
                    self.reverseGeocodeWithOSM(lat: lat, lng: lng, success: success, failure: failure)
                }
            }
        }
        else {
			self.reverseGeocodeWithOSM(lat: lat, lng: lng, success: success, failure: failure)
		}
    }
    
    private func reverseGeocodeWithOSM(lat lat:Double, lng:Double, success: (NSDictionary) -> (), failure:(NSError?) -> ()) {
        let url = NSURL(string: "https://open.mapquestapi.com/nominatim/v1/reverse.php?key=cNm6VT88E3WIPryw5qvImcWwCJOl3rQC&format=json&lat=\(lat)&lon=\(lng)")!
        let request = NSURLRequest(URL: url)
        
        
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue()) { (response, responseData, error) -> Void in
            
            if error == nil {
				#if DEBUG
				let responseText = NSString(data: responseData!, encoding: NSUTF8StringEncoding)!
				#endif
				var json : [String : AnyObject]
				do {
					json = try NSJSONSerialization.JSONObjectWithData(responseData!, options: NSJSONReadingOptions()) as! [String : AnyObject]
				}
				catch {
					OWUtilities.ignorableProblemAlert()
					failure(nil)//self.reverseGeocodeWithApple(lat: lat, lng: lng, success: success, failure: failure)
					return
				}
				
                if json["error"] == nil {
                    let address = json["display_name"] as! String
                    
                    //let addressComponents = json["address"] as [String : String]
					
                    /*var firstAddressComponent = responseText.firstMatch(NSRegularExpression(pattern: "\"address\":\\{\"\\w+\":\"[^\"]+\""))
                    firstAddressComponent = firstAddressComponent.replace(NSRegularExpression(pattern: "\"address\":\\{\"\\w+\":"), with:"")
                    // this converts special json character entities into actual characters
                    firstAddressComponent = NSJSONSerialization.JSONObjectWithData(
                        firstAddressComponent.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!,
                        options: NSJSONReadingOptions.AllowFragments, error: nil) as String
                    
                    let city = address.stringByReplacingOccurrencesOfString(firstAddressComponent + ", ", withString: "")*/
                    
                    let dictToSend = ["lat":"\(lat)", "lng": "\(lng)", "place":["address": address/*, "city":city*/]]
                    success(dictToSend)
                }
                else {
					failure(nil)
                }
            }
			else { failure(error) }
        }
    }
    
    private func reverseGeocodeWithApple(lat lat:Double, lng:Double, success: (NSDictionary) -> (), failure:(NSError?) -> ()) {
        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: lat, longitude: lng), completionHandler: { (responseArray, error) -> Void in
            
            if responseArray != nil && responseArray!.count != 0 {
                let placemark = responseArray![0] as CLPlacemark
				if placemark.ocean != nil {
					self.reverseGeocodeWithGoogle(lat: lat, lng: lng, success: success, failure: failure)
					return
				}
               // let lines = placemark.addressDictionary!["FormattedAddressLines"] as! NSArray!
				
				if placemark.name == nil { self.reverseGeocodeWithGoogle(lat: lat, lng: lng, success: success, failure: failure) }
				
				let address = placemark.name!//lines.componentsJoinedByString(", ")
				
				if placemark.country != nil && placemark.country! == address {
					self.reverseGeocodeWithGoogle(lat: lat, lng: lng, success: success, failure: failure)
				}
				var city = placemark.locality ?| placemark.subLocality ?| placemark.subAdministrativeArea;
				if city == nil { city = "" }
                
				let dictToSend = ["lat":"\(lat)", "lng": "\(lng)", "place":["address": address, "city" : city!]]
                success(dictToSend)
            }
            else { self.reverseGeocodeWithGoogle(lat: lat, lng: lng, success: success, failure: failure) }
        })
    }
    
}

extension NSObject {
	@objc class func runClosureInMainThread(closure:() -> ()) {
		dispatch_async(dispatch_queue_create("serial_worker", DISPATCH_QUEUE_SERIAL)) {
			dispatch_async(dispatch_get_main_queue(), closure);
		}
	}
}




