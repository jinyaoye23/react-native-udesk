
#if __has_include("RCTBridgeModule.h")
#import "React/RCTBridgeModule.h"
#import <Foundation/Foundation.h>
#else
#import <React/RCTBridgeModule.h>
#import <Foundation/Foundation.h>
#endif

@interface RNReactNativeUdesk : NSObject <RCTBridgeModule>

@end
  
