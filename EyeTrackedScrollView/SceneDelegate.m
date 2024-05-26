//
//  SceneDelegate.m
//  EyeTrackedScrollView
//
//  Created by Jinwoo Kim on 5/26/24.
//

#import "SceneDelegate.h"
#import "CollectionViewController.h"
#import "UIWindowScene+EyeTrackedScrolling.h"

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    windowScene.ets_eyeTrackedScrollingEnabled = YES;
    UIWindow *window = [[UIWindow alloc] initWithWindowScene:windowScene];
    CollectionViewController *rootViewController = [CollectionViewController new];
    window.rootViewController = rootViewController;
    [rootViewController release];
    self.window = window;
    [window makeKeyAndVisible];
    [window release];
}

@end
