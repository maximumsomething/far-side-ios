import Foundation


infix operator ?| {
	precedence 95
	associativity left
}

func ?| <T>(a: T?, b: T?) -> T? {
	if a == nil { return b }
	else { return a }
}




class OWCameraPositionContainer : NSObject, NSCoding {
	var contained : GMSCameraPosition
	
	private static let zoomKey      = "zoom"
	private static let latitudeKey  = "latitude"
	private static let longitudeKey = "longitude"
	private static let bearingKey   = "bearing"
	private static let angleKey     = "viewingAngle"
	
	func encodeWithCoder(aCoder: NSCoder) {
		aCoder.encodeFloat (contained.zoom,             forKey: OWCameraPositionContainer.zoomKey)
		aCoder.encodeDouble(contained.target.latitude,  forKey: OWCameraPositionContainer.latitudeKey)
		aCoder.encodeDouble(contained.target.longitude, forKey: OWCameraPositionContainer.longitudeKey)
		aCoder.encodeDouble(contained.bearing,          forKey: OWCameraPositionContainer.bearingKey)
		aCoder.encodeDouble(contained.viewingAngle,     forKey: OWCameraPositionContainer.angleKey)
	}
	required init?(coder aDecoder: NSCoder) {
		let zoom    = aDecoder.decodeFloatForKey(OWCameraPositionContainer.zoomKey)
		let lat     = aDecoder.decodeDoubleForKey(OWCameraPositionContainer.latitudeKey)
		let lng     = aDecoder.decodeDoubleForKey(OWCameraPositionContainer.longitudeKey)
		let bearing = aDecoder.decodeDoubleForKey(OWCameraPositionContainer.bearingKey)
		let angle   = aDecoder.decodeDoubleForKey(OWCameraPositionContainer.angleKey)
		contained = GMSCameraPosition(target: CLLocationCoordinate2DMake(lat, lng), zoom: zoom, bearing: bearing, viewingAngle: angle)
		super.init()
	}
	init(contained: GMSCameraPosition) {
		self.contained = contained
		super.init()
	}
}