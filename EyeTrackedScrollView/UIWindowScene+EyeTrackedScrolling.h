//
//  UIWindowScene+EyeTrackedScrolling.h
//  EyeTrackedScrollView
//
//  Created by Jinwoo Kim on 5/26/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface UIWindowScene (EyeTrackedScrolling)
@property (nonatomic, getter=ets_isEyeTrackedScrollingEnabled, setter=ets_setEyeTrackedScrollingEnabled:) BOOL ets_eyeTrackedScrollingEnabled;
@end

NS_ASSUME_NONNULL_END
