//
//  UIWindowScene+EyeTrackedScrolling.mm
//  EyeTrackedScrollView
//
//  Created by Jinwoo Kim on 5/26/24.
//

#import "UIWindowScene+EyeTrackedScrolling.h"
#import <ARKit/ARKit.h>
#import <objc/message.h>
#import <objc/runtime.h>

void *arSessionKey = &arSessionKey;
void *arSessionDelegateKey = &arSessionDelegateKey;
void *oldBlendShapesByAnchorIdentifiersKey = &oldBlendShapesByAnchorIdentifiersKey;

__attribute__((objc_direct_members))
@interface _ETSARSessionDelegate : NSObject <ARSessionDelegate>
@property (copy, nonatomic) void (^didUpdateAnchorsHandler)(ARSession *session, NSArray<__kindof ARAnchor *> *anchors);
@end

@implementation _ETSARSessionDelegate

- (void)dealloc {
    [_didUpdateAnchorsHandler release];
    [super dealloc];
}

- (void)session:(ARSession *)session didUpdateAnchors:(NSArray<__kindof ARAnchor *> *)anchors {
    if (auto didUpdateAnchorsHandler = _didUpdateAnchorsHandler) {
        didUpdateAnchorsHandler(session, anchors);
    }
}

@end

@implementation UIWindowScene (EyeTrackedScrolling)

- (BOOL)ets_isEyeTrackedScrollingEnabled {
    return objc_getAssociatedObject(self, arSessionKey) != nil;
}

- (void)ets_setEyeTrackedScrollingEnabled:(BOOL)eyeTrackedScrollingEnabled {
    if (eyeTrackedScrollingEnabled) {
        [self _ets_enableEyeTrackedScrolling];
    } else {
        [self _ets_disableEyeTrackedScrolling];
    }
}

- (void)_ets_enableEyeTrackedScrolling __attribute__((objc_direct)) {
    if (!ARFaceTrackingConfiguration.isSupported) return;
    if (objc_getAssociatedObject(self, arSessionKey) != nil) return;
    
    ARSession *arSession = [ARSession new];
    
    _ETSARSessionDelegate *delegate = [_ETSARSessionDelegate new];
    __weak auto weakSelf = self;
    delegate.didUpdateAnchorsHandler = ^(ARSession *session, NSArray<__kindof ARAnchor *> *anchors) {
        [weakSelf _ets_didUpdateAnchors:anchors session:session];
    };
    
    objc_setAssociatedObject(arSession, arSessionDelegateKey, delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    arSession.delegate = delegate;
    [delegate release];
    
    ARFaceTrackingConfiguration *configuration = [ARFaceTrackingConfiguration new];
    configuration.lightEstimationEnabled = YES;
    
    [arSession runWithConfiguration:configuration];
    [configuration release];
}

- (void)_ets_disableEyeTrackedScrolling __attribute__((objc_direct)) {
    ARSession *arSession = objc_getAssociatedObject(self, arSessionKey);
    if (arSession == nil) return;
    
    [arSession pause];
    objc_setAssociatedObject(self, arSession, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)_ets_didUpdateAnchors:(NSArray<__kindof ARAnchor *> *)anchors session:(ARSession *)session __attribute__((objc_direct)) {
    if (anchors.count == 0) return;
    
    NSDictionary<NSUUID *, NSDictionary<ARBlendShapeLocation, NSNumber *> *> *old_oldBlendShapesByAnchorIdentifiers = objc_getAssociatedObject(session, oldBlendShapesByAnchorIdentifiersKey);
    NSMutableDictionary<NSUUID *, NSDictionary<ARBlendShapeLocation, NSNumber *> *> *new_oldBlendShapesByAnchorIdentifiers = [[NSMutableDictionary alloc] initWithCapacity:anchors.count];
    
    CGPoint adjustedContentOffset = CGPointZero;
    
    for (ARAnchor *anchor in anchors) {
        if (![anchor isKindOfClass:ARFaceAnchor.class]) continue;
        
        ARFaceAnchor *faceAnchor = (ARFaceAnchor *)anchor;
        
        NSDictionary<ARBlendShapeLocation, NSNumber *> * _Nullable oldBlendShapes = old_oldBlendShapesByAnchorIdentifiers[faceAnchor.identifier];
        NSDictionary<ARBlendShapeLocation, NSNumber *> *blendShapes = faceAnchor.blendShapes;
        
        new_oldBlendShapesByAnchorIdentifiers[faceAnchor.identifier] = blendShapes;
        
        if (oldBlendShapes == nil) continue;
        
        float eyeLookDownLeft = blendShapes[ARBlendShapeLocationEyeLookDownLeft].floatValue;
        float eyeLookDownRight = blendShapes[ARBlendShapeLocationEyeLookDownRight].floatValue;
        
        CGFloat offsetY;
        
        if (eyeLookDownLeft > 0.f || eyeLookDownRight > 0.f) {
            float max = MAX(eyeLookDownLeft, eyeLookDownRight);
            
            if (max > 0.25f) {
                offsetY = max;
            } else if (max < 0.15f) {
                offsetY = -max;
            } else {
                offsetY = 0.f;
            }
        } else {
            float eyeLookUpLeft = blendShapes[ARBlendShapeLocationEyeLookUpLeft].floatValue;
            float eyeLookUpRight = blendShapes[ARBlendShapeLocationEyeLookUpRight].floatValue;
            
            if (eyeLookUpLeft > 0.f || eyeLookUpRight > 0.f) {
                offsetY = -MAX(eyeLookUpLeft, eyeLookUpRight) - 0.15f;
            } else {
                offsetY = 0.;
            }
        }
        
        if (abs(adjustedContentOffset.y) < abs(offsetY)) {
            adjustedContentOffset.y = offsetY;
        }
        
        // TODO: offsetX
    }
    
    if (!CGPointEqualToPoint(adjustedContentOffset, CGPointZero)) {
        UIWindow *keyWindow = self.keyWindow;
        NSArray<UIScrollView *> *_registeredScrollToTopViews = ((id (*)(id, SEL))objc_msgSend)(keyWindow, sel_registerName("_registeredScrollToTopViews"));
        
        if (auto scrollView = _registeredScrollToTopViews.firstObject) {
            CGPoint contentOffset = scrollView.contentOffset;
            
            [scrollView setContentOffset:CGPointMake(contentOffset.x + adjustedContentOffset.x * 20.,
                                                     contentOffset.y + adjustedContentOffset.y * 20.)
                                animated:NO];
        }
    }
    
    objc_setAssociatedObject(session, oldBlendShapesByAnchorIdentifiersKey, new_oldBlendShapesByAnchorIdentifiers, OBJC_ASSOCIATION_COPY_NONATOMIC);
    [new_oldBlendShapesByAnchorIdentifiers release];
}

@end
