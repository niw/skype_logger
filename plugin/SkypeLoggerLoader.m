#import "SkypeLoggerLoader.h"
#import <RubyCocoa/RBRuntime.h>

@implementation SkypeLoggerLoader
+(void) load
{
	static Boolean loaded = NO;
	if(! loaded) {
		RBBundleInit("skype_logger.rb", [SkypeLoggerLoader class], nil);
		NSLog(@"SkypeLogger loaded");
		loaded = YES;
	}
}
@end