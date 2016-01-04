//
//  LWPacketAppSettings.m
//  LykkeWallet
//
//  Created by Alexander Pukhov on 05.01.16.
//  Copyright © 2016 Lykkex. All rights reserved.
//

#import "LWPacketAppSettings.h"
#import "LWAppSettingsModel.h"


@implementation LWPacketAppSettings


#pragma mark - LWPacket

- (void)parseResponse:(id)response error:(NSError *)error {
    [super parseResponse:response error:error];
    
    if (self.isRejected) {
        return;
    }
    
    _appSettings = [[LWAppSettingsModel alloc] initWithJSON:result];
}

- (NSString *)urlRelative {
    return @"AppSettings";
}

- (GDXRESTPacketType)type {
    return GDXRESTPacketTypeGET;
}

@end
