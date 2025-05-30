#import <Foundation/Foundation.h>

#import <dlfcn.h>
#import <roothide.h>
#import <HBLog.h>

#define TAG "[XcodeAnyDebug] "

@interface DTDSLaunchTargetID : NSObject
- (instancetype)initWithUser:(uid_t)user group:(gid_t)group;
@end

@interface DTDSSpawnOptions : NSObject
@property (nonatomic, strong) DTDSLaunchTargetID *targetUserAndGroup;
@end

%group SMJob

static void* _SMJobSubmit;

%hookf(Boolean, _SMJobSubmit, CFStringRef domain, CFDictionaryRef job, CFTypeID auth, CFErrorRef *outError)
{
    NSMutableDictionary* mjob = [(__bridge NSDictionary*)job mutableCopy];
    if (job != nil && mjob[@"ProgramArguments"] != nil)
    {
        NSArray* argv = mjob[@"ProgramArguments"];

        HBLogDebug(@TAG "_SMJobSubmit argv=%@", argv);

        if ([argv[0] hasSuffix:@"/debugserver"])
        {
            NSMutableArray* new_argv = [argv mutableCopy];

            new_argv[0] = jbroot(@"/usr/bin/xcodeanydebug/debugserver");

            mjob[@"UserName"] = @"root";
            mjob[@"ProgramArguments"] = new_argv;
        }

        job = (__bridge_retained CFDictionaryRef)mjob;     
    }
    return %orig;
}

%end

%group Dtds

static void* _dtdsSpawnExecutableWithOptions;

%hookf(Boolean, _dtdsSpawnExecutableWithOptions, const char *path, DTDSSpawnOptions *options, pid_t *pid, NSError **error)
{
    HBLogDebug(@TAG "_dtdsSpawnExecutableWithOptions path=%s", path);

    if ([[NSString stringWithUTF8String:path] hasSuffix:@"/debugserver"])
    {
        DTDSLaunchTargetID *target = [[%c(DTDSLaunchTargetID) alloc] initWithUser:0 group:0];
        [options setTargetUserAndGroup:target];

        NSString *newPath = jbroot(@"/usr/bin/xcodeanydebug/debugserver");
        return %orig([newPath UTF8String], options, pid, error);
    }

    return %orig;
}

%end

%ctor {
    BOOL isDtds = NO;
    for (NSString* arg in [[NSProcessInfo processInfo] arguments]) {
        if ([arg hasSuffix:@"dtdebugproxyd"]) {
            isDtds = YES;
            break;
        }
    }
    HBLogDebug(@TAG "isDtds=%@", isDtds ? @"YES" : @"NO");
    if (isDtds) {
        _dtdsSpawnExecutableWithOptions = dlsym(RTLD_DEFAULT, "dtdsSpawnExecutableWithOptions");
        %init(Dtds);
    } else {
        _SMJobSubmit = dlsym(RTLD_DEFAULT, "SMJobSubmit");
        %init(SMJob);
    }
}
