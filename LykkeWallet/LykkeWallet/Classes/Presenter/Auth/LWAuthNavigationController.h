//
//  LWAuthNavigationController.h
//  LykkeWallet
//
//  Created by Георгий Малюков on 09.12.15.
//  Copyright © 2015 Lykkex. All rights reserved.
//

#import "TKNavigationController.h"
#import "LWAuthStepPresenter.h"

typedef void (^LWAuthStepPushPreparationBlock)(LWAuthStepPresenter *presenter);


@interface LWAuthNavigationController : TKNavigationController {
    
}

@property (readonly, nonatomic) LWAuthStep currentStep;


#pragma mark - Common

- (void)navigateToStep:(LWAuthStep)step preparationBlock:(LWAuthStepPushPreparationBlock)block;
- (void)navigateKYCStatus:(NSString *)status isPinEntered:(BOOL)isPinEntered isAuthentication:(BOOL)isAuthentication;


#pragma mark - Auth

- (void)logout;

@end
