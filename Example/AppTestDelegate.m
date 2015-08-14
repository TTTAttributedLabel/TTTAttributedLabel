//
//  AppTestDelegate.m
//  Espressos
//
//  Created by Jonathan Hersh on 6/15/15.
//
//

#import "AppTestDelegate.h"

@implementation AppTestDelegate

- (BOOL)application:(__unused UIApplication *)application didFinishLaunchingWithOptions:(__unused NSDictionary *)launchOptions {
    _window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = [UIViewController new];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
