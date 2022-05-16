//
//  UISheetPresentationController+Private.h
//  mist-ios
//
//  Created by Adam Novak on 2022/05/15.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UISheetPresentationControllerDetent ()
+ (UISheetPresentationControllerDetent *)_detentWithIdentifier:(NSString *)identifier constant:(CGFloat)constant;
@end

NS_ASSUME_NONNULL_END
