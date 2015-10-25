
import Foundation
import UIKit

let pixelsPerDegree = 10.0

//var errorToLookAt:String! = nil

@objc class otherSideFinder : NSObject {
	    
	private var coordsDatabase:[String : Double]!
	//private var progressCheckerInfo:(Int, Int, Bool)
	
	override init() {
		//progressCheckerInfo = (0, 0, false)
		
		super.init()
		let path = NSBundle.mainBundle().bundlePath + "/coords-database.json"
		let coordsDatabaseData = NSData(contentsOfFile: path)!
		do {
			coordsDatabase = try NSJSONSerialization.JSONObjectWithData(coordsDatabaseData, options:NSJSONReadingOptions()) as! [String : Double]
		}
		catch {
			
		}
		//let localCoordsDatabase = coordsDatabase
		//let coordsDatabaseString = NSString(data: coordsDatabaseData, encoding: NSUTF8StringEncoding) as String
		
	}
    //let pixelsPerDegree = 10
    
	@objc func startFinding(/*lat: Double, lng:Double, callback: (Double, Double) -> ()*/callbackPlusGetStuff:([String: AnyObject]) -> [AnyObject]?) {
		
		//infiniteLoop() //{ exit() }
		
		let stuff = callbackPlusGetStuff(["get values": true])!
		let lat:Double = stuff[0] as! Double
		let lng:Double = stuff[1] as! Double
		let callback = callbackPlusGetStuff
        
		findLand(lat: lat, lng: lng, size: 400, useBigMap: true, center: CGPointMake(200, 200), callback: { landLat, landLng, progress in
			if (landLat == nil || landLng == nil) && progress == nil {
				NSLog("somehow failed in the end")
				callback(["error": true])
			}
			else if progress != nil {
				callback(["progress": progress])
			}
			else {
				//NSLog("YAY!!!!!!!!!!!!!!!!!!")
				callback(["lat": landLat, "lng": landLng])
				return;
				/*self.reverseGeocodeAndPackage(lat: landLat, lng: landLng, success: callback, failure: { reason in
					NSLog("\(landLat), \(landLng)")
					callback(["lat": landLat, "lng": landLng])
					NSLog("reverse geocoding failed")
				})*/
				
			}
		})
    }
	
	
	//the boolean returned specifies if the thread should be exited or not
	private func findLand(lat lat:Double, lng:Double, size:Int, useBigMap:Bool, isDownFartherSouth:Bool = false, center:CGPoint, callback:((Double!, Double!, Float!) -> Void)) -> Bool! {
		
		//NSLog("findLand")
		
		getImage(useBigMap: useBigMap, size: size, lat: lat, lng: lng, failure: {callback(nil, nil, nil)}) { image, origin in
			
			let visibleImage = UIImage(CGImage: image)
			let data = CGImageGetDataProvider(image)
			
			let pixels:NSData = CGDataProviderCopyData(data)!
			let length        = pixels.length;
			let ptr           = UnsafePointer<UInt8>(pixels.bytes)
			
			/*let newImage = UIImage(CGImage: CGImage.imageFromARGB32Bitmap(data, width: UInt(size), height: UInt(size), bitmapInfo: CGImageGetBitmapInfo(image)))*/
			
			//NSLog("\(length)")
			//NSLog("\((ptr.memory)), \((ptr + 1).memory), \((ptr + 2).memory), \((ptr + 3).memory), \((ptr + 4).memory)")
			
			
			/*if self.onLand((ptr + (((size/2)*size) + size/2)).memory) {
				if (useBigMap) {
					
				}
				else {
					callback(lat, lng, nil)
					return
				}
				
			}*/
			
			let bytesPerPixel = (useBigMap ? 1 : 4)
			
			var closestLand = (distance:Int.max, x:0,y:0)
			var pixelIndex = 0
			
			var upperMarker:Int!
			var lowerMarker:Int!
			
			for y in 0 ..< size {
				for x in 0 ..< size {
					
					//let pixelIndex = (size*y) + x
					
					//ptr + pixelIndex is the greyscale channel
					if self.onLand(ptr[pixelIndex]) {
						
						let (competitor, _, _) = closestLand
						let distanceFromCenter = self.distance(x1: Int(center.x), y1: Int(center.y), x2: x, y2: y)
						
						if distanceFromCenter < competitor {
							closestLand = (distanceFromCenter, x, y)
						}
						
					}
					else if self.isMarker(ptr[pixelIndex], otherChannel: ptr[pixelIndex + 1]) {
						if x < size/2 { lowerMarker = y }
						else		  { upperMarker = y }
					}
					pixelIndex += bytesPerPixel
				}
				//let searchProgress = Float(y)/Float(size)
				//if (Float(lroundf(searchProgress*Float(10))) == searchProgress*Float(10)) { callback(nil, nil, searchProgress*0.6/2) }
				if NSThread.currentThread().cancelled { return }
				
				// It makes it work. Why? I have no idea. If it stops working, try removing this.
				pixelIndex += ((length - size*size*bytesPerPixel)/size)
				
				if closestLand.distance == 0 { break }
			}
			//free(ptr)
			
			// pass it on
			var (distance, bestX, bestY) = closestLand
			if distance != Int.max {
			
				if useBigMap {
					var amountToOffsetBy:Float
					/*
					90:
					45:7
					0:
					
					switch lat {
						case -90...
					}*/
					
					var finalLat = 90 - (((Double(origin.y) + Double(bestY) + (pixelsPerDegree*0.7)))/pixelsPerDegree)
					var finalLng = ((Double(origin.x) + Double(bestX))/pixelsPerDegree) - 180
					
					(finalLat, finalLng) = self.realCoords(lat: finalLat, lng: finalLng)
					
					NSLog("\(finalLat), \(finalLng)")
					
					//callback(finalLat, finalLng, nil); return
					func nextCallback(lat:Double!, lng:Double!, var progress:Float!) -> Void {
						if progress != nil {
							progress = progress + 0.5
						}
						callback(lat, lng, progress)
					}
					if closestLand.distance != 0 {
						let sizeRatio = (22/0.03)/pixelsPerDegree
						let newPoint = self.calcNewCenter(newX: bestX, newY: bestY, newSize: 150, sizeRatio: sizeRatio, originalCenter: center)
						
						self.findLand(lat: finalLat, lng: finalLng, size: 300, useBigMap: false, center:newPoint, callback: nextCallback)
					}
					else {
						self.findLand(lat: finalLat, lng: finalLng, size: 300, useBigMap: false, center:CGPointMake(150, 150), callback: nextCallback)
					}
				}
				else {
					if closestLand.distance != 0 {
						
						if upperMarker == nil || lowerMarker == nil { callback(nil, nil, nil); return }
						
						let latPixelsToCoordsRatio = 0.06/Double(lowerMarker - upperMarker)
						var finalLat = lat - Double(bestY - size/2)*(latPixelsToCoordsRatio)//0.06 degrees of latitude
						var finalLng = lng + Double(bestX - size/2)*(0.03/22) //22 is the amount of pixels per 0.03 longitude on a google map at 10 zoom
						(finalLat, finalLng) = self.realCoords(lat: finalLat, lng: finalLng)
						
						if size == 300 {
							/*if self.onLand((ptr + (bestY + 2)*size + (bestX    ) + 1).memory) { bestY += 2 }
							if self.onLand((ptr + (bestY - 2)*size + (bestX    ) + 1).memory) { bestY -= 2 }
							if self.onLand((ptr + (bestY    )*size + (bestX + 2) + 1).memory) { bestX += 2 }
							if self.onLand((ptr + (bestY    )*size + (bestX - 2) + 1).memory) { bestX -= 2 }*/
							callback(finalLat, finalLng, nil)
						}
						else {
							let newPoint = self.calcNewCenter(newX: bestX, newY: bestY, newSize: 150, sizeRatio: 1, originalCenter: center)
							self.findLand(lat: finalLat, lng: finalLng, size: 300, useBigMap: false, center:newPoint, callback:callback)
						}
					}
					else {
						callback(lat, lng, nil)
					}
				}
				
			}
			else {
				func nextCallback(lat:Double!, lng:Double!, progress:Float!) -> Void {
					if progress == nil { callback(lat, lng, nil) }
					//else do nothing
				}
				if useBigMap {
					let newCenter = CGFloat(size + 300)/2
					
					self.findLand(lat: lat, lng: lng, size: size + 300, useBigMap: true, center: CGPointMake(newCenter, newCenter), callback: callback)
				}
				else if size == 300 {
					self.findLand(lat: lat, lng: lng, size: 600, useBigMap: false, center:CGPointMake(300, 300), callback: callback)
				}
				else {
					if !isDownFartherSouth {
						let degreesPerPixel = 0.06/self.coordsDatabase["\(lround(lat))"]!;
						
						//-300 means the original center of the original (not south) image
						self.findLand(lat: lat - (degreesPerPixel*450), lng: lng, size: 300, useBigMap: false, isDownFartherSouth: true, center:CGPointMake(center.x, center.y-450), callback: nextCallback)
					}
					else {
						callback(nil, nil, nil) // haven't found anything, so call back with both parameters null
					}
				}
				
			}
		}
		return true;
	}
	
	private func calcNewCenter(newX newX:Int, newY:Int, newSize:Int, sizeRatio:Double, originalCenter:CGPoint) -> CGPoint {
		let xDist = Double(Int(originalCenter.x) - newX)*sizeRatio
		let yDist = Double(Int(originalCenter.y) - newY)*sizeRatio
		
		let xDistRaised = powf(Float(xDist), 2)
		let yDistRaised = powf(Float(yDist), 2)
		
		let shrinkBy = pow(Float(newSize), 2)/Float(xDistRaised + yDistRaised)
		
		let shrunkenXDist = sqrt(xDistRaised*shrinkBy)
		let shrunkenYDist = sqrt(yDistRaised*shrinkBy)
		
		var newCenterXDist = shrunkenXDist;		var newCenterYDist = shrunkenYDist
		if xDist < 0 { newCenterXDist = -newCenterXDist }
		if yDist < 0 { newCenterYDist = -newCenterYDist }
		
		return CGPointMake(CGFloat(newCenterXDist + 150), CGFloat(newCenterYDist + 150))
	}
	
	private func getImage(useBigMap useBigMap:Bool, size:Int, lat:Double, lng:Double, failure:() -> Void, success:(CGImage, origin:CGPoint!) -> Void) {
		//var image:CGImageRef! = nil
        
        if useBigMap {
			let fullimagepath = "\(NSBundle.mainBundle().resourcePath!)/big map.png"
            let fullimagedata = NSData(contentsOfFile: fullimagepath)
			let fullimage = CGImageCreateWithPNGDataProvider(CGDataProviderCreateWithCFData(fullimagedata), nil, false, CGColorRenderingIntent.RenderingIntentAbsoluteColorimetric)!
            
            //6 is subtracted from the y because the map is offset that way for some reason.
            let areaToSearch = OWUtilities.makeTheRectForCroppingPartOfBigMapAndlat(lat, lng: lng, size: CGFloat(size), pixelsPerDegree: 10)
			
			var image:CGImage
			if areaToSearch.origin.x < CGFloat(360*pixelsPerDegree - Double(size))
			&& areaToSearch.origin.y < CGFloat(180*pixelsPerDegree - Double(size)) {
				
				image = CGImageCreateWithImageInRect(fullimage, areaToSearch)!
			}
			else {
				var leftTopSearchArea = areaToSearch
				var originXOffsetFromEdge = CGFloat(360*pixelsPerDegree) - areaToSearch.origin.x
				var originYOffsetFromEdge = CGFloat(180*pixelsPerDegree) - areaToSearch.origin.y
				
				if Int(originXOffsetFromEdge) > size { originXOffsetFromEdge = CGFloat(size) }
				if Int(originYOffsetFromEdge) > size { originYOffsetFromEdge = CGFloat(size) }
				
				//remember: left top in the image is on the bottom right on the map!
				leftTopSearchArea.size.width  = originXOffsetFromEdge
				leftTopSearchArea.size.height = originYOffsetFromEdge
				
				let leftBottomSearchArea  = CGRectMake(areaToSearch.origin.x, 0, leftTopSearchArea.size.width, CGFloat(size) - originYOffsetFromEdge)
				let rightTopSearchArea    = CGRectMake(0, areaToSearch.origin.y, CGFloat(size) - originXOffsetFromEdge, leftTopSearchArea.size.height)
				let rightBottomSearchArea = CGRectMake(0, 0, CGFloat(size) - originXOffsetFromEdge, CGFloat(size) - originYOffsetFromEdge)
				
				
				let leftTopImage     = CGImageCreateWithImageInRect(fullimage, leftTopSearchArea)
				let leftBottomImage  = CGImageCreateWithImageInRect(fullimage, leftBottomSearchArea)
				let rightTopImage    = CGImageCreateWithImageInRect(fullimage, rightTopSearchArea)
				let rightBottomImage = CGImageCreateWithImageInRect(fullimage, rightBottomSearchArea)
				
				
				UIGraphicsBeginImageContext(CGSizeMake(CGFloat(size), CGFloat(size)))
				
				if leftTopImage     != nil { UIImage(CGImage: leftTopImage!    ).drawAtPoint(CGPointMake(0, 0)) }
				if rightTopImage    != nil { UIImage(CGImage: rightTopImage!   ).drawAtPoint(CGPointMake(CGFloat(CGImageGetWidth(leftTopImage)), 0)) }
				if leftBottomImage  != nil { UIImage(CGImage: leftBottomImage! ).drawAtPoint(CGPointMake(0, CGFloat(CGImageGetHeight(leftTopImage)))) }
				if rightBottomImage != nil { UIImage(CGImage: rightBottomImage!).drawAtPoint(CGPointMake(CGFloat(CGImageGetWidth(leftTopImage)),
					CGFloat(CGImageGetHeight(leftTopImage)))) }
				
				image = UIGraphicsGetImageFromCurrentImageContext().CGImage!
				UIGraphicsEndImageContext()
			}
			
			
			let context = OWUtilities.makeAGrayscaleContextWithSize(Int32(size)).takeRetainedValue()
			CGContextDrawImage(context,
				CGRectMake(0, 0, CGFloat(size), CGFloat(size)),
				image)
			image = CGBitmapContextCreateImage(context)!
			
            success(image, origin: areaToSearch.origin)
        }
        else {
			
			//load a map
			let bwStyle  = /*"style=feature:administrative%7Cvisibility:off"*/"style=feature:landscape%7Clightness:100&style=feature:water%7Clightness:-100&style=feature:road%7Cvisibility:off&style=feature:administrative%7Cvisibility:off&style=feature:poi%7Cvisibility:off&style=feature:transit%7Cvisibility:off";
			let key	        = "AIzaSyA5gTRlULxXXzTDK9VaMWhGqEjKlGuGrr0";
			let noLabels    = "style=element:labels%7Cvisibility:off";
			let markerStyle = "size:tiny%7Ccolor:"
			
			
			//let halfOfTwentyFivePixels = (12.5)*(0.06/self.coordsDatabase["\(lround(lat))"]!)
			
			let urlString = "https://maps.googleapis.com/maps/api/staticmap?size=\(size)x\(size + 50)&center=\(lat),\(lng)&\(bwStyle)&\(noLabels)&key=\(key)&zoom=10&markers=\(markerStyle)red%7C\(lat - 0.03),\(lng - 0.18)&markers=\(markerStyle)red%7C\(lat + 0.03),\(lng + 0.18)"
			
			//println(urlString)
			let url = NSURL(string: urlString)!
			let request = NSURLRequest(URL: url)
			if NSURLConnection.canHandleRequest(request) {
				
			
				NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue()) { response, responseData, error in
					if (responseData == nil) {
						failure()
						return
					}
					
					#if DEBUG
					let visibleImage = UIImage(data: responseData!)
					#endif
					//NSLog(response.MIMEType!)
					//let dataString = NSString(data: responseData, encoding: NSUTF8StringEncoding)
					//NSLog(error.localizedDescription)
					//if error != nil {errorToLookAt = error.localizedDescription}
					
					var image = CGImageCreateWithPNGDataProvider(CGDataProviderCreateWithCFData(responseData!), nil, false, CGColorRenderingIntent.RenderingIntentAbsoluteColorimetric)
					
					
					if image == nil {
						NSLog("the image is null")
						failure()
						return
					}
					else {
						image = CGImageCreateWithImageInRect(image, CGRectMake(0, 25, CGFloat(size), CGFloat(size)))
						
						image = OWUtilities.convertImageToRGBA(image).takeRetainedValue()
						
						//var context = CGBitmapContextCreate(nil as UnsafePointer<Void>, UInt(size) as UInt, UInt(size) as UInt, 32 as UInt, 0 as UInt, CGColorSpaceCreateDeviceRGB()!, CGImageAlphaInfo.Last as CGBitmapInfo)
						
						success(image!, origin:nil)
						
					}
				}
			}
			else {
				failure()
				NSLog("could not download image")
			}
        }

	}

	private func distance(x1 x1:Int, y1:Int, x2:Int, y2:Int) -> Int {
		return lround((sqrt(pow(Double(x1 - x2), 2.0) + pow(Double(y1 - y2), 2.0))))
	}

	private func onLand(color: UInt8) -> Bool {
		return (color == 254 || color == 255)
    }
	private func isMarker(redChannel:UInt8, otherChannel:UInt8) -> Bool {
		return ((redChannel > 50 && redChannel < 254) && otherChannel != redChannel)
	}
	
	
	private func realCoords(var lat lat:Double, var lng:Double) -> (Double, Double) {
		
		if lng < -180 { lng += 360 }
		if lng >  180 { lng -= 360 }
		
		if lat <  -90 { lat += 180 }
		if lat >   90 { lat -= 180 }
		
		return (lat, lng)
	}
	
	func exitIfCancelled() -> Bool {
		if NSThread.currentThread().cancelled {
			//exit()
			return true;
		}
		return false;
	}
	
	@objc func exit() -> () {
		NSThread.exit()
	}
	
}

typealias IntegerCoordinate = (x:Int, y:Int)


