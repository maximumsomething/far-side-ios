import Foundation
//import MapKit


@objc class OWShowInMapShareOption : UIActivity {
    
    override init() {
        
    }
    
    var lat: Double!
    var lng: Double!
    
    override class func activityCategory() -> UIActivityCategory { return UIActivityCategory.Share }
    override func prepareWithActivityItems(activityItems: [AnyObject]) {
        
        /*let vcardString = NSString(contentsOfURL: activityItems[0] as NSURL, encoding: NSUTF8StringEncoding, error: nil)!
        
        let latLngString = vcardString.firstMatch(NSRegularExpression(pattern: "ll=*\n"))
        
        let latRegex = NSRegularExpression(pattern: "ll=*,")
        let lngRegex = NSRegularExpression(pattern: ",*\n")
        
        lat = latLngString.firstMatch(latRegex)
            .stringByReplacingOccurrencesOfString("ll=", withString:"")
            .stringByReplacingOccurrencesOfString(","  , withString:"")
        
        lng = latLngString.firstMatch(NSRegularExpression(pattern: ",*\n", options:nil, error:nil))
            .stringByReplacingOccurrencesOfString("\n", withString:"")
            .stringByReplacingOccurrencesOfString("," , withString:"")*/
        
        lat = OWMiscellaneousData.sharedData.landLat as Double
        lng = OWMiscellaneousData.sharedData.landLng as Double

    }
    
    
    override func canPerformWithActivityItems(activityItems: [AnyObject]) -> Bool {
        
        if activityItems.count > 1 { return false }
        
        if activityItems[0].isMemberOfClass(NSURL) {
            let url = activityItems[0] as! NSURL
            if (url.absoluteString.hasSuffix(".loc.vcf")) { return true }
        }
        
        return false
    }
    //override func activityImage() -> UIImage? { return  }
    
}


@objc class OWShowInAppleMapsShareOption : OWShowInMapShareOption {
    
    override func activityTitle() -> String? {
        return "Maps"
    }
    
    override func performActivity() {
        let url = NSURL(string: "http://maps.apple.com/?q=\(lat),\(lng)&z=9")!
        UIApplication.sharedApplication().openURL(url)
		/*let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2DMake(lat, lng), addressDictionary: nil))
		mapItem.openInMapsWithLaunchOptions(<#T##launchOptions: [String : AnyObject]?##[String : AnyObject]?#>)*/
    }
    
    override func activityImage() -> UIImage? {
        return UIImage(named: "apple maps icon.png")
    }
}


@objc class OWShowInGoogleMapsShareOption : OWShowInMapShareOption {
    
    override func activityTitle() -> String? {
        return "Google Maps"
    }
    override func activityImage() -> UIImage? {

        let image = UIImage(named: "googleMapsIcon.png")
        return image
    }
    override func performActivity() {
		let onlineUrlString = "www.google.com/maps/place/\(lat),\(lng)/@\(lat),\(lng),10z"
		/*let url = NSURL(string: "comgooglemapsurl://\(onlineUrlString)")!
		
		if UIApplication.sharedApplication().canOpenURL(url) {
			UIApplication.sharedApplication().openURL(url)
		}
		else {*/
			let url = NSURL(string: "comgooglemaps://?q=\(lat),\(lng)&center=\(lat),\(lng)&zoom=10")!
			if UIApplication.sharedApplication().canOpenURL(url) {
				UIApplication.sharedApplication().openURL(url)
			}
			else {
				let url = NSURL(string: "http://\(onlineUrlString)")!
				UIApplication.sharedApplication().openURL(url)
			}
		//}
    }
}


@objc class OWSearchWikipediaShareOption : UIActivity {
    
    //private var geocodeResponseDictionary:[String : AnyObject]!
    private var address:String!
    
    override func activityTitle() -> String? {
        return "Search Wikipedia"
    }
    override class func activityCategory() -> UIActivityCategory {
        return UIActivityCategory.Share
    }
    override func activityType() -> String? {
        return "searchWikipedia"
    }
    override func activityImage() -> UIImage? {
        return UIImage(named:"wikipediaIcon")
    }
    override func canPerformWithActivityItems(activityItems: [AnyObject]) -> Bool {
        // I don't care.
        return true
    }
    
    override func prepareWithActivityItems(activityItems: [AnyObject]) {
        if OWMiscellaneousData.sharedData.address != nil {
            address = OWMiscellaneousData.sharedData.locality
            if address == nil { address = OWMiscellaneousData.sharedData.address }
            self.performActivityAfterDoneGeocoding()
        }
        else {
            let data = OWMiscellaneousData.sharedData
            OWSteppedGeocoder().reverseGeocodeAndPackage(lat: Double(data.landLat), lng: Double(data.landLng),
                success: { (stuff:NSDictionary) -> () in
                    
                    //self.geocodeResponseDictionary = stuff as [String : AnyObject];
                    self.address = (stuff["place"] as! [String : String])["city"]!
                    if self.address == nil { self.address = (stuff["place"] as! [String : String])["address"] }
                    self.performActivityAfterDoneGeocoding()
                    
                }, failure: { (error) in
					if error != nil { NSLog(error!.localizedDescription) }
                })
        }
    }
    
    func performActivityAfterDoneGeocoding() {
		
        //let searchString = address + " site:en.wikipedia.org"
        let searchString = address
        let escapedSearchString = searchString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.alphanumericCharacterSet())!
        //let urlString = "http://www.google.com/?q=\(escapedSearchString)&gws_rd=ssl#q=\(escapedSearchString)"
        let urlString = "http://\((NSLocale.preferredLanguages()[0] as NSString).substringToIndex(2)).wikipedia.org/wiki/Special:Search?search=\(escapedSearchString)"
        let url = NSURL(string: urlString)!
        UIApplication.sharedApplication().openURL(url)
    }
}


class OWSearchGoogleShareOption : UIActivity {
    
    private var address:String!
    
    override func activityTitle() -> String? {
        return "Search Google"
    }
    override func activityType() -> String? {
        return "searchGoogle"
    }
    override class func activityCategory() -> UIActivityCategory {
        return UIActivityCategory.Share
    }
    override func activityImage() -> UIImage? {
        return UIImage(named: "google search icon.png")
    }
    override func canPerformWithActivityItems(activityItems: [AnyObject]) -> Bool {
        return true
    }
    
    override func prepareWithActivityItems(activityItems: [AnyObject]) {
        if OWMiscellaneousData.sharedData.address != nil {
            self.address = OWMiscellaneousData.sharedData.address
            self.performActivityAfterDoneGeocoding()
        }
        else {
            let data = OWMiscellaneousData.sharedData
            OWSteppedGeocoder().reverseGeocodeAndPackage(lat: Double(data.landLat), lng: Double(data.landLng),
                success: { (stuff:NSDictionary) -> () in
                    
                    //self.geocodeResponseDictionary = stuff as [String : AnyObject];
                    self.address = (stuff["place"] as! [String : String])["city"]!
                    self.performActivityAfterDoneGeocoding()
                    
                }, failure: { (error) in })
        }
    }
    
    func performActivityAfterDoneGeocoding() {
        let escapedAddress = address.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.alphanumericCharacterSet())!
        let url = NSURL(string: "http://www.google.com/search?q=\(escapedAddress)&gws_rd=ssl#q=\(escapedAddress)")!
        let something = url.absoluteString
        UIApplication.sharedApplication().openURL(url)
    }

}




