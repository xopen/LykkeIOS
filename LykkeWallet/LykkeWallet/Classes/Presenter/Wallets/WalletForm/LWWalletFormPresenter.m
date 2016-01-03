//
//  LWWalletFormPresenter.m
//  LykkeWallet
//
//  Created by Alexander Pukhov on 31.12.15.
//  Copyright © 2015 Lykkex. All rights reserved.
//

#import "LWWalletFormPresenter.h"
#import "LWWalletConfirmPresenter.h"
#import "LWAuthManager.h"
#import "LWTextField.h"
#import "LWValidator.h"
#import "LWConstants.h"
#import "LWBankCardsAdd.h"
#import "LWBankCardsData.h"
#import "UIColor+Generic.h"
#import "UIViewController+Loading.h"


@interface LWWalletFormPresenter ()<LWAuthManagerDelegate, LWTextFieldDelegate> {
    UIColor *navigationTintColor;
    LWTextField *cardNumberTextField;
    LWTextField *cardExpireTextField;
    LWTextField *cardOwnerTextField;
    LWTextField *cardCodeTextField;
}


#pragma mark - Outlets

@property (weak, nonatomic) IBOutlet UIView *bankCardsView;
@property (weak, nonatomic) IBOutlet TKContainer *cardNumberContainer;
@property (weak, nonatomic) IBOutlet TKContainer *cardExpireContainer;
@property (weak, nonatomic) IBOutlet TKContainer *cardOwnerContainer;
@property (weak, nonatomic) IBOutlet TKContainer *cardCodeContainer;

@property (weak, nonatomic) IBOutlet UIButton *resetButton;
@property (weak, nonatomic) IBOutlet UIButton *submitButton;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *warningLabel;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bankCardHeightConstraint;


#pragma mark - Utils

- (void)createTextFields;
- (BOOL)isCardsExists;
- (BOOL)canProceed;

@end


@implementation LWWalletFormPresenter


#pragma mark - Constants

static CGFloat const kBanksHeight = 20.0;


#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self createTextFields];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"BackIcon"] style:UIBarButtonItemStylePlain target:self.navigationController action:@selector(popViewControllerAnimated:)];
    self.navigationItem.leftBarButtonItem = button;
    
    self.bankCardHeightConstraint.constant = [self isCardsExists] ? kBanksHeight : 0.0;

    // check button state
    [LWValidator setButton:self.submitButton enabled:self.canProceed];

    [LWAuthManager instance].delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated {
    self.navigationController.navigationBar.barTintColor = navigationTintColor;

    [super viewWillDisappear:animated];
}


#pragma mark - Setup

- (void)localize {
    self.title = Localize(@"wallets.cardform.title");
    
    self.submitButton.titleLabel.text = Localize(@"wallets.cardform.card.submitButton");
    self.resetButton.titleLabel.text = Localize(@"wallets.cardform.card.resetButton");
    self.descriptionLabel.text = Localize(@"wallets.cardform.card.description");
}

- (void)colorize {
    // detect color depends on bank cards list
    UIColor *color = ([self isCardsExists]
                      ? [UIColor colorWithHexString:kMainGrayElementsColor]
                      : [UIColor colorWithHexString:kMainWhiteElementsColor]);
    
    navigationTintColor = self.navigationController.navigationBar.barTintColor;
    [self.navigationController.navigationBar setBarTintColor:color];
    self.bankCardsView.backgroundColor = color;
    
    UIColor *resetColor = [UIColor colorWithHexString:kMainDarkElementsColor];
    [self.resetButton setTitleColor:resetColor forState:UIControlStateNormal];
    
    self.warningLabel.textColor = [UIColor redColor];
}


#pragma mark - LWAuthManagerDelegate

- (void)authManagerDidCardAdd:(LWAuthManager *)manager {
    [self setLoading:NO];
    
    LWWalletConfirmPresenter *form = [LWWalletConfirmPresenter new];
    [self.navigationController pushViewController:form animated:YES];
}

- (void)authManager:(LWAuthManager *)manager didFailWithReject:(NSDictionary *)reject context:(GDXRESTContext *)context {
    [self showReject:reject];
}


#pragma mark - LWTextFieldDelegate

- (void)textFieldDidChangeValue:(LWTextField *)textFieldInput {
    if (!self.isVisible) { // prevent from being processed if controller is not presented
        return;
    }

    if (textFieldInput == cardNumberTextField) {
        textFieldInput.valid = [LWValidator validateCardNumber:textFieldInput.text];
    }
    else if (textFieldInput == cardExpireTextField) {
        textFieldInput.valid = [LWValidator validateCardExpiration:textFieldInput.text];
    }
    else if (textFieldInput == cardOwnerTextField) {
        textFieldInput.valid = [LWValidator validateCardOwner:textFieldInput.text];
    }
    else if (textFieldInput == cardCodeTextField) {
        textFieldInput.valid = [LWValidator validateCardCode:textFieldInput.text];
    }

    // check button state
    [LWValidator setButton:self.submitButton enabled:self.canProceed];
}

#pragma mark - Actions

- (IBAction)resetClicked:(id)sender {
    cardNumberTextField.text = @"";
    cardExpireTextField.text = @"";
    cardOwnerTextField.text = @"";
    cardCodeTextField.text = @"";
}

- (IBAction)submitClicked:(id)sender {
    [self.view endEditing:YES];

    [self setLoading:YES];
    
    LWBankCardsAdd *data = [LWBankCardsAdd new];
    data.bankNumber = cardNumberTextField.text;
    data.name = cardOwnerTextField.text;
#warning TODO:
    data.type = @"Visa";
    data.monthTo = [NSNumber numberWithInt:10];
    data.yearTo = [NSNumber numberWithInt:2017];
    data.cvc = cardCodeTextField.text;
    
    [[LWAuthManager instance] requestAddBankCard:data];
}


#pragma mark - Utils

- (void)createTextFields {
    // card number
    cardNumberTextField = [LWTextField
                           createTextFieldForContainer:self.cardNumberContainer withPlaceholder:Localize(@"wallets.cardform.card.number.placeholder")];
    cardNumberTextField.keyboardType = UIKeyboardTypeNumberPad;
    cardNumberTextField.delegate = self;
    
    // card expiration date
    cardExpireTextField = [LWTextField
                           createTextFieldForContainer:self.cardExpireContainer withPlaceholder:Localize(@"wallets.cardform.card.expire.placeholder")];
    cardExpireTextField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    cardExpireTextField.viewMode = UITextFieldViewModeNever;
    cardExpireTextField.delegate = self;
    
    // card owner name
    cardOwnerTextField = [LWTextField
                          createTextFieldForContainer:self.cardOwnerContainer withPlaceholder:Localize(@"wallets.cardform.card.owner.placeholder")];
    cardOwnerTextField.keyboardType = UIKeyboardTypeASCIICapable;
    cardOwnerTextField.delegate = self;
    
    // cvc card code
    cardCodeTextField = [LWTextField
                         createTextFieldForContainer:self.cardCodeContainer withPlaceholder:Localize(@"wallets.cardform.card.code.placeholder")];
    cardCodeTextField.keyboardType = UIKeyboardTypeNumberPad;
    cardCodeTextField.viewMode = UITextFieldViewModeNever;
    cardCodeTextField.delegate = self;
}

- (BOOL)isCardsExists {
    BOOL const isCardsExists = (self.bankCards && self.bankCards.count > 0);
    return isCardsExists;
}

- (BOOL)canProceed {
    return cardNumberTextField.valid && cardExpireTextField.valid && cardOwnerTextField.valid && cardCodeTextField.valid;
}

@end
