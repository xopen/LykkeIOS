//
//  LWAuthManager.m
//  LykkeWallet
//
//  Created by Георгий Малюков on 09.12.15.
//  Copyright © 2015 Lykkex. All rights reserved.
//

#import "LWAuthManager.h"
#import "LWPacketAccountExist.h"
#import "LWPacketAuthentication.h"
#import "LWPacketRegistration.h"
#import "LWPacketRegistrationGet.h"
#import "LWPacketCheckDocumentsToUpload.h"
#import "LWPacketKYCSendDocument.h"
#import "LWPacketKYCStatusGet.h"
#import "LWPacketKYCStatusSet.h"
#import "LWPacketPinSecurityGet.h"
#import "LWPacketPinSecuritySet.h"
#import "LWPacketRestrictedCountries.h"
#import "LWKeychainManager.h"


@interface LWAuthManager () {
    
}

#pragma mark - Observing

- (void)observeGDXNetAdapterDidReceiveResponseNotification:(NSNotification *)notification;
- (void)observeGDXNetAdapterDidFailRequestNotification:(NSNotification *)notification;

@end


@implementation LWAuthManager


#pragma mark - Root

SINGLETON_INIT {
    self = [super init];
    if (self) {
        [self subscribe:kNotificationGDXNetAdapterDidReceiveResponse
               selector:@selector(observeGDXNetAdapterDidReceiveResponseNotification:)];
        [self subscribe:kNotificationGDXNetAdapterDidFailRequest
               selector:@selector(observeGDXNetAdapterDidFailRequestNotification:)];
    }
    return self;
}


#pragma mark - Common

- (void)requestEmailValidation:(NSString *)email {
    LWPacketAccountExist *pack = [LWPacketAccountExist new];
    pack.email = email;
    
    [self sendPacket:pack];
}

- (void)requestAuthentication:(LWAuthenticationData *)data {
    LWPacketAuthentication *pack = [LWPacketAuthentication new];
    pack.authenticationData = data;
    
    [self sendPacket:pack];
}

- (void)requestRegistration:(LWRegistrationData *)data {
    LWPacketRegistration *pack = [LWPacketRegistration new];
    pack.registrationData = data;
    
    [self sendPacket:pack];
}

- (void)requestRegistrationGet {
    LWPacketRegistrationGet *pack = [LWPacketRegistrationGet new];
    
    [self sendPacket:pack];
}

- (void)requestDocumentsToUpload {
    LWPacketCheckDocumentsToUpload *pack = [LWPacketCheckDocumentsToUpload new];

    [self sendPacket:pack];
}

- (void)requestSendDocument:(KYCDocumentType)docType image:(UIImage *)image {
    LWPacketKYCSendDocument *pack = [LWPacketKYCSendDocument new];
    pack.docType = docType;
    pack.imageJPEGRepresentation = UIImageJPEGRepresentation(image, 0.8f); // 20% compression
    
    [self sendPacket:pack];
}

- (void)requestKYCStatusGet {
    LWPacketKYCStatusGet *pack = [LWPacketKYCStatusGet new];
    
    [self sendPacket:pack];
}

- (void)requestKYCStatusSet {
    LWPacketKYCStatusSet *pack = [LWPacketKYCStatusSet new];
    
    [self sendPacket:pack];
}

- (void)requestPinSecurityGet:(NSString *)pin {
    LWPacketPinSecurityGet *pack = [LWPacketPinSecurityGet new];
    pack.pin = pin;
    
    [self sendPacket:pack];
}

- (void)requestPinSecuritySet:(NSString *)pin {
    LWPacketPinSecuritySet *pack = [LWPacketPinSecuritySet new];
    pack.pin = pin;
    
    [self sendPacket:pack];
}

- (void)requestRestrictedCountries {
    LWPacketRestrictedCountries *pack = [LWPacketRestrictedCountries new];
    
    [self sendPacket:pack];
}


#pragma mark - Observing

- (void)observeGDXNetAdapterDidReceiveResponseNotification:(NSNotification *)notification {
    GDXRESTContext *ctx = notification.userInfo[kNotificationKeyGDXNetContext];
    LWPacket *pack = (LWPacket *)ctx.packet;
    // decline rejected packet
    if (pack.isRejected) {
        [self observeGDXNetAdapterDidFailRequestNotification:notification];
        // return immediately
        return;
    }

    // parse packet by class
    if (pack.class == LWPacketAccountExist.class) {
        if ([self.delegate respondsToSelector:@selector(authManager:didCheckRegistration:email:)])  {
            LWPacketAccountExist *account = (LWPacketAccountExist *)pack;
            [self.delegate authManager:self
                  didCheckRegistration:account.isRegistered
                                 email:account.email];
        }
    }
    else if (pack.class == LWPacketAuthentication.class) {
        if ([self.delegate respondsToSelector:@selector(authManagerDidAuthenticate:KYCStatus:isPinEntered:)]) {
            LWPacketAuthentication *auth = (LWPacketAuthentication *)pack;
            [self.delegate authManagerDidAuthenticate:self
                                            KYCStatus:auth.status
                                         isPinEntered:auth.isPinEntered];
        }
    }
    else if (pack.class == LWPacketRegistration.class) {
        // set self registration data
        _registrationData = ((LWPacketRegistration *)pack).registrationData;
        // call delegate
        if ([self.delegate respondsToSelector:@selector(authManagerDidRegister:)]) {
            [self.delegate authManagerDidRegister:self];
        }
    }
    else if (pack.class == LWPacketRegistrationGet.class) {
        // call delegate
        if ([self.delegate respondsToSelector:@selector(authManagerDidRegisterGet:KYCStatus:isPinEntered:)]) {
            LWPacketRegistrationGet *registration = (LWPacketRegistrationGet *)pack;
            [self.delegate authManagerDidRegisterGet:self
                                           KYCStatus:registration.status
                                        isPinEntered:registration.isPinEntered];
        }
    }
    else if (pack.class == LWPacketCheckDocumentsToUpload.class) {
        // set self documents status
        _documentsStatus = ((LWPacketCheckDocumentsToUpload *)pack).documentsStatus;
        // call delegate
        if ([self.delegate respondsToSelector:@selector(authManager:didCheckDocumentsStatus:)]) {
            [self.delegate authManager:self didCheckDocumentsStatus:self.documentsStatus];
        }
    }
    else if (pack.class == LWPacketKYCSendDocument.class) {
        KYCDocumentType docType = ((LWPacketKYCSendDocument *)pack).docType;
        // modify self documents status
        [self.documentsStatus setTypeUploaded:docType];
        // call delegate
        if ([self.delegate respondsToSelector:@selector(authManagerDidSendDocument:ofType:)]) {
            [self.delegate authManagerDidSendDocument:self ofType:docType];
        }
    }
    else if (pack.class == LWPacketKYCStatusGet.class) {
        if ([self.delegate respondsToSelector:@selector(authManager:didGetKYCStatus:)]) {
            [self.delegate authManager:self didGetKYCStatus:((LWPacketKYCStatusGet *)pack).status];
        }
    }
    else if (pack.class == LWPacketKYCStatusSet.class) {
        if ([self.delegate respondsToSelector:@selector(authManagerDidSetKYCStatus:)]) {
            [self.delegate authManagerDidSetKYCStatus:self];
        }
    }
    else if (pack.class == LWPacketPinSecurityGet.class) {
        if ([self.delegate respondsToSelector:@selector(authManager:didValidatePin:)]) {
            [self.delegate authManager:self didValidatePin:((LWPacketPinSecurityGet *)pack).isPassed];
        }
    }
    else if (pack.class == LWPacketPinSecuritySet.class) {
        if ([self.delegate respondsToSelector:@selector(authManagerDidSetPin:)]) {
            [self.delegate authManagerDidSetPin:self];
        }
    }
    else if (pack.class == LWPacketRestrictedCountries.class) {
        if ([self.delegate respondsToSelector:@selector(authManager:didReceiveRestrictedCountries:)]) {
            [self.delegate authManager:self
         didReceiveRestrictedCountries:((LWPacketRestrictedCountries *)pack).countries];
        }
    }
}

- (void)observeGDXNetAdapterDidFailRequestNotification:(NSNotification *)notification {
    GDXRESTContext *ctx = notification.userInfo[kNotificationKeyGDXNetContext];
    LWPacket *pack = (LWPacket *)ctx.packet;
    
    if ([self.delegate respondsToSelector:@selector(authManager:didFailWithReject:context:)])  {
        [self.delegate authManager:self didFailWithReject:pack.reject context:ctx];
    }
}


#pragma mark - Properties

- (BOOL)isAuthorized {
    return ([LWKeychainManager instance].token != nil);
}

@end
