//
//  LWAuthenticationPresenter.m
//  LykkeWallet
//
//  Created by Alexander Pukhov on 20.12.15.
//  Copyright © 2015 Lykkex. All rights reserved.
//

#import "LWAuthenticationPresenter.h"
#import "LWKYCPendingPresenter.h"
#import "LWAuthNavigationController.h"
#import "LWAuthenticationData.h"
#import "LWTextField.h"
#import "LWValidator.h"
#import "TKPresenter+Loading.h"


@interface LWAuthenticationPresenter () <LWTextFieldDelegate, LWAuthManagerDelegate> {
    LWTextField *emailField;
    LWTextField *passwordField;
}

@property (weak, nonatomic) IBOutlet TKContainer *emailContainer;
@property (weak, nonatomic) IBOutlet TKContainer *passwordContainer;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;

@end


@implementation LWAuthenticationPresenter

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = Localize(@"title.authentication");
    
    // init fields
    emailField = [LWTextField createTextFieldForContainer:self.emailContainer
                                          withPlaceholder:Localize(@"auth.email")];
    emailField.keyboardType = UIKeyboardTypeEmailAddress;
    emailField.enabled = NO;
    
    passwordField = [LWTextField createTextFieldForContainer:self.passwordContainer
                                             withPlaceholder:Localize(@"auth.password")];
    passwordField.secure = YES;
    passwordField.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [LWValidator setButton:self.loginButton enabled:[self canProceed]];
    
    // load email
    emailField.text = self.email;
    // focus first name
    [passwordField becomeFirstResponder];
}


#pragma mark - LWTextFieldDelegate

- (void)textFieldDidChangeValue:(LWTextField *)textFieldInput {
    if (!self.isVisible) { // prevent from being processed if controller is not presented
        return;
    }
    
    // check button state
    [LWValidator setButton:self.loginButton enabled:[self canProceed]];
}


#pragma mark - Private

- (BOOL)canProceed {
    BOOL isValidEmail = [LWValidator validateEmail:emailField.text];
    BOOL isValidPassword = [LWValidator validatePassword:passwordField.text];
    return (isValidEmail && isValidPassword);
}


#pragma mark - Utils

- (IBAction)loginClicked:(id)sender {
    if ([self canProceed]) {
        [self setLoading:YES];
        
        LWAuthenticationData *data = [LWAuthenticationData new];
        data.email = emailField.text;
        data.password = passwordField.text;
        
        [[LWAuthManager instance] requestAuthentication:data];
    }
}


#pragma mark - LWAuthManagerDelegate

- (void)authManagerDidAuthenticate:(LWAuthManager *)manager withKYCStatus:(NSString *)status withPinEntered:(BOOL)isPinEntered {
    [self setLoading:NO];
    
    LWAuthNavigationController *navController = (LWAuthNavigationController *)self.navigationController;
    [navController navigateWithKYCStatus:status
                          withPinEntered:isPinEntered
                        isAuthentication:YES];
}

- (void)authManager:(LWAuthManager *)manager didFailWithReject:(NSDictionary *)reject context:(GDXRESTContext *)context {
    [self showReject:reject];
}

@end
