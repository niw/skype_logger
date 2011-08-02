#import <Cocoa/Cocoa.h>

@interface SkypeLoggerLoader : NSObject {
    pid_t pid_;
}
+(void)load;
+(SkypeLoggerLoader *)sharedInstance;

-(void)load;
@end