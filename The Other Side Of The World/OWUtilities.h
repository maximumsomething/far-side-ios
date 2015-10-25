//
//  OW.h
//  The Other Side Of The World
//
//  Created by Max on 6/22/14.
//  Copyright (c) 2014 The Company. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>



@interface OWUtilities : NSObject {
    //NSMutableData *landServerResponseData;
    
    id delagate;
}
+ (NSString*) displayCoords:(float)lat lng:(float)lng;

+ (void) fadeElement:(UILabel *)element from:(float)fadeFrom to:(float)fadeTo withDuration:(float)duration withCompletion:(void(^) (BOOL))completion;
+ (void) fadeElement:(UILabel *)element to:(float)fadeTo withDuration:(float)duration withCompletion:(void(^) (BOOL))completion;
+ (void) fadeElement:(UILabel *)element from:(float)fadeFrom to:(float)fadeTo withDuration:(float)duration;
+ (void) fadeElement:(UILabel *)element to:(float)fadeTo withDuration:(float)duration;
+ (void) ignorableProblemAlert;

+ (void) runSelector:(SEL)selector onObject:(id)object withObject:(id)argument afterDelay:(float)delay;

+ (CGRect) makeTheRectForCroppingPartOfBigMapAndlat:(double)lat lng:(double)lng size:(CGFloat)size pixelsPerDegree:(int)pixelsPerDegree;
+ (CGContextRef) makeAGrayscaleContextWithSize:(int)size;
+ (CGImageRef)convertImageToRGBA:(CGImageRef)image;

- (OWUtilities *) initWithDelagate:(id)delagate;

/*- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;*/

@end


