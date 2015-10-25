//
//  OW.m
//  The Other Side Of The World
//
//  Created by Max on 6/22/14.
//  Copyright (c) 2014 The Company. All rights reserved.
//

#import "OWUtilities.h"

@implementation OWUtilities
+ (NSString*) displayCoords:(float)lat lng:(float)lng {
    
    NSString* lngEnd;       NSString* latEnd;
    
    if (lng < 0) {lngEnd = @"West" ;}
    else            {lngEnd = @"East" ;}
    if (lat > 0) {latEnd = @"North";}
    else            {latEnd = @"South";}
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return [NSString stringWithFormat:@"%fº %@, %fº %@", lat, latEnd, lng, lngEnd];
    }
    else {
        return [NSString stringWithFormat:@"%ldº %@, %ldº %@", (lroundf(lat * 100)/100), latEnd, (lroundf(lng*100)/100), lngEnd];
    }
}

- (OWUtilities *)initWithDelagate:(id)newdelagate {
    delagate = newdelagate;
    return self;
}

+ (void)fadeElement:(UILabel *)element from:(float)fadeFrom to:(float)fadeTo withDuration:(float)duration withCompletion:(void(^)(BOOL))completion{
    
    element.alpha = fadeFrom;
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseIn
                     animations:^{element.alpha = fadeTo;}
                     completion:completion];
}

+ (void)fadeElement:(UILabel *)element to:(float)fadeTo withDuration:(float)duration {
    [self fadeElement:element from:element.alpha to:fadeTo withDuration:duration];
}
+ (void)fadeElement:(UILabel *)element from:(float)fadeFrom to:(float)fadeTo withDuration:(float)duration {
    [self fadeElement:element from:fadeFrom to:fadeTo withDuration:duration withCompletion:^(BOOL finished){}];
}
+ (void)fadeElement:(UILabel *)element to:(float)fadeTo withDuration:(float)duration withCompletion:(void (^)(BOOL))completion {
    [self fadeElement:element from:element.alpha to:fadeTo withDuration:duration withCompletion:completion];
}
+ (void)ignorableProblemAlert {
#ifdef DEBUG 
	abort();
#endif
}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished    context:(void *)context {
    
    //[delagate fadeFinished:animationID];
    }


/*- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    landServerResponseData = [[NSMutableData alloc] init];
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [landServerResponseData appendData:data];
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    //self.whereItIs.text = [error localizedDescription];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // Once this method is invoked, "landServerResponseData" contains the complete result
    NSString *textReturned = [[NSString alloc] initWithData:landServerResponseData encoding:NSUTF8StringEncoding];
 
    
}*/


+ (CGRect)makeTheRectForCroppingPartOfBigMapAndlat:(double)lat lng:(double)lng size:(CGFloat)size pixelsPerDegree:(int)pixelsPerDegree {
	//pixelsPerDegree = 10;
	int x = (CGFloat)(((180 + lng)*pixelsPerDegree)     - size/2);
	int y = (CGFloat)(((90  - lat)*pixelsPerDegree - 6) - size/2);
	
	if (x > pixelsPerDegree*360) x -= pixelsPerDegree*360;
	if (x < 0				   ) x += pixelsPerDegree*360;
	
	
	
	CGRect rect = CGRectMake(x, y, size, size);
	
	//return CGRectMake(1, 2, 3, 4);
	return rect;
}

+ (CGContextRef) makeAGrayscaleContextWithSize:(int)size {
	return CGBitmapContextCreate(nil, size, size, 8, 0, CGColorSpaceCreateDeviceGray(), (CGBitmapInfo)kCGImageAlphaNone);
}

+ (void)runSelector:(SEL)selector onObject:(id)object withObject:(id)argument afterDelay:(float)delay {
	[object performSelector:selector withObject:argument afterDelay:delay];
}



// FROM SAMPLE CODE:
+ (CGImageRef)convertImageToRGBA:(CGImageRef)image {
	
	CGContextRef    context = NULL;
	CGColorSpaceRef colorSpace;
	
	// Get image width, height. We'll use the entire image.
	size_t pixelsWide = CGImageGetWidth(image);
	size_t pixelsHigh = CGImageGetHeight(image);
	
	// Declare the number of bytes per row. Each pixel in the bitmap in this
	// example is represented by 4 bytes; 8 bits each of red, green, blue, and
	// alpha.
	
	// Use the generic RGB color space.
	colorSpace = CGColorSpaceCreateDeviceRGB();
	if (colorSpace == NULL)
	{
		fprintf(stderr, "Error allocating color space\n");
		return NULL;
	}
	
	// Allocate memory for image data. This is the destination in memory
	// where any drawing to the bitmap context will be rendered.
	
	// Create the bitmap context. We want pre-multiplied ARGB, 8-bits
	// per component. Regardless of what the source image format is
	// (CMYK, Grayscale, and so on) it will be converted over to the format
	// specified here by CGBitmapContextCreate.
	context = CGBitmapContextCreate (nil,
									 pixelsWide,
									 pixelsHigh,
									 8,      // bits per component
									 0,
									 colorSpace,
									 (CGBitmapInfo) kCGImageAlphaPremultipliedLast);
	
	// Make sure and release colorspace before returning
	CGColorSpaceRelease( colorSpace );
	
	if (context == NULL)
	{
		// error creating context
		return nil;
	}
	
		size_t w = CGImageGetWidth(image);
	size_t h = CGImageGetHeight(image);
	CGRect rect = {{0,0},{w,h}};
	
	CGContextDrawImage(context, rect, image);
	
    image = CGBitmapContextCreateImage(context);
	CGContextRelease(context);
    return image;
}


@end
