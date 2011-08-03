#import "SkypeLoggerLoader.h"

@implementation SkypeLoggerLoader
+(void)load
{
    static Boolean loaded = NO;
    if(! loaded) {
        [[SkypeLoggerLoader sharedInstance] load];
        NSLog(@"SkypeLogger loaded");
        loaded = YES;
    }
}

+(SkypeLoggerLoader *)sharedInstance
{
    static SkypeLoggerLoader* instance = nil;
    if(! instance) {
        instance = [[SkypeLoggerLoader alloc] init];
    }
    return instance;
}

- (NSString *)skypeLoggerPath
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    return [[bundle resourcePath] stringByAppendingPathComponent:@"skype_logger.rb"];
}

- (NSString *)logFilePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    if([paths count] > 0) {
        NSString *path = [paths objectAtIndex:0];
        path = [path stringByAppendingPathComponent:@"Application Support"];
        path = [path stringByAppendingPathComponent:@"Skype"];
        path = [path stringByAppendingPathComponent:@"SkypeLogger.log"];
        return path;
    } else {
        return [@"~/Library/Application Support/Skype/SkypeLogger.log" stringByStandardizingPath];
    }
}

- (void)load
{
    pid_t pid;
    const char* skypeLoggerPath = [[self skypeLoggerPath] UTF8String];
    const char* logFilePath = [[self logFilePath] UTF8String];

    if((pid = fork()) == 0) {
        NSLog(@"Running SkypeLogger...");
        if(execl("/usr/bin/ruby",
                 "ruby",
                 skypeLoggerPath,
                 "-l",
                 logFilePath,
                 NULL) < 0) {
            NSLog(@"Fail to execl, exit.");
            exit(1);
        }
    } else if(pid < 0) {
        NSLog(@"Fail to fork SkypeLogger.");
    } else {
        pid_ = pid;
        NSLog(@"Forked SkypeLogger pid: %d", pid);
    }

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(terminate:)
                               name:NSApplicationWillTerminateNotification
                             object:NSApp];
}

- (void)terminate:(NSNotification *)notification
{
    if(pid_ > 1) {
        NSLog(@"Kill SkypeLogger pid: %d", pid_);
        kill(pid_, SIGTERM);
        waitpid(pid_, NULL, 0);
        pid_ = 0;
    }
}
@end