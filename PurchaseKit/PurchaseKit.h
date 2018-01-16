//
//  PurchaseKit.h
//  PurchaseKit
//
//  Created by admin on 2018/1/16.
//  Copyright © 2018年 george. All rights reserved.
//

#import <StoreKit/StoreKit.h>

typedef void(^successCallback)(NSString *result);
typedef void(^failureCallback)(NSString *result);
typedef void(^errorCallback)(NSError *error);


@interface PurchaseKit : NSObject

//- (instancetype)initWithProductId:(NSString *)productId;
+ (instancetype)startPurchase:(NSString *)productId;

@end
