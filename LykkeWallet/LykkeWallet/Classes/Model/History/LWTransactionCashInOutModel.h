//
//  LWTransactionCashInOutModel.h
//  LykkeWallet
//
//  Created by Alexander Pukhov on 10.01.16.
//  Copyright © 2016 Lykkex. All rights reserved.
//

#import "LWJSONObject.h"


@interface LWTransactionCashInOutModel : LWJSONObject {
    
}

@property (readonly, nonatomic) NSString *identity;
@property (readonly, nonatomic) NSNumber *amount;
@property (readonly, nonatomic) NSString *dateTime;

@end