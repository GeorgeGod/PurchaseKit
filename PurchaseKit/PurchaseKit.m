//
//  PurchaseKit.m
//  PurchaseKit
//
//  Created by admin on 2018/1/16.
//  Copyright © 2018年 george. All rights reserved.
//

#import "PurchaseKit.h"

typedef enum : NSUInteger {
    PurchaseStateRequestNonProduct = 0, //没有商品
    PurchaseStateRequestFailure,
    PurchaseStateRequestSuccess,
    
    PurchaseStatePurchasing,
    PurchaseStatePurchased,
    PurchaseStateFailed,
    PurchaseStateRestored,
    PurchaseStateDeferred
} PurchaseState;

@interface PurchaseKit()<SKPaymentTransactionObserver,SKProductsRequestDelegate >
@property (nonatomic, copy  ) NSString *productID;
@property (nonatomic, assign) PurchaseState purchaseState;
@end

@implementation PurchaseKit

/*
 * 1. 请求收不到内购的产品信息
 * 解决办法：
 *  (1) 先看看bundle id，和测试证书之类的东西配置的都对不对，然后看看产品的唯一ID和iTunesConnect里的能不能对应上。如果都没有问题，那么看下面的。
 *  (2) 去看看iTunesConnect里的协议里面的公司的地址信息和银行卡信息是否填写正确，只要没有报错，报红就可以。基本上上面这几点弄好了也就能请求到商品了。
 */
/*
 * 2. 手机提示无法连接到iTunesStore
 * 解决办法：把手机的Apple ID先注销掉，然后购买的时候重新填写Apple ID。
 */

- (instancetype)initWithProductId:(NSString *)productId {
    if(self = [super init]) {
        self.productID = productId;
        
        //开启内测检测
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];

        if ([SKPaymentQueue canMakePayments]) {
            [self requestProductData:self.productID];
        }
    }
    return self;
}

+ (instancetype)startPurchase:(NSString *)productId {
    return [[PurchaseKit alloc] initWithProductId:productId];
}

-(void)setPurchaseError:(PurchaseState)purchaseState {
    _purchaseState = purchaseState;
    NSLog(@"======%lu", (unsigned long)purchaseState);
}

///private 请求商品详细信息
- (void)requestProductData:(NSString *)productId {
    NSSet *set = [NSSet setWithObjects:productId, nil];
    SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:set];
    request.delegate = self;
    [request start];
}

///SKProductsRequestDelegate 收到产品返回的信息
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    NSArray *productArr = response.products;
    if (productArr.count == 0) {
        self.purchaseState = PurchaseStateRequestNonProduct;
        return;
    }
    SKProduct *product = nil;
    for (SKProduct *pro in productArr) {
        NSLog(@"PurchaseKit----[%@]", pro.description);
        NSLog(@"PurchaseKit----[%@]", pro.localizedTitle);
        NSLog(@"PurchaseKit----[%@]", pro.localizedDescription);
        NSLog(@"PurchaseKit----[%@]", pro.price);
        NSLog(@"PurchaseKit----[%@]", pro.productIdentifier);
        if ([pro.productIdentifier isEqualToString:self.productID]) {
            product = pro;
        }
    }
    if (product != nil) {
        SKPayment *payment = [SKPayment paymentWithProduct:product];
        //发起购买请求
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
    NSLog(@"PurchaseKit----[发起购买请求了]");
}

///SKRequestDelegate 请求产品失败
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    self.purchaseState = PurchaseStateFailed;
    NSLog(@"PurchaseKit----[请求产品错误:%@]", error);
}
///SKRequestDelegate 请求产品结束
- (void)requestDidFinish:(SKRequest *)request {
    NSLog(@"PurchaseKit----[请求产品完成]");
}

///SKPaymentTransactionObserver 监听购买结果
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    
    for (SKPaymentTransaction *tran in transactions) {
        switch (tran.transactionState) {
            case SKPaymentTransactionStatePurchased:
                //交易完成
                [[SKPaymentQueue defaultQueue] finishTransaction:tran];
                [self comleteTranscation:tran];
                self.purchaseState = PurchaseStatePurchased;
                break;
            case SKPaymentTransactionStatePurchasing:
                //商品添加进列表
                self.purchaseState = PurchaseStatePurchasing;
                break;
            case SKPaymentTransactionStateRestored:
                //已经购买过商品
                [self restoreTranscation:tran];
                self.purchaseState = PurchaseStateRestored;
                break;
            case SKPaymentTransactionStateFailed:
                //购买失败
                [self failedTransaction:tran];
                self.purchaseState = PurchaseStateFailed;
                break;
            case SKPaymentTransactionStateDeferred:
                self.purchaseState = PurchaseStateDeferred;
                break;
            default:
                break;
        }
    }
}

///private 交易结束
- (void)comleteTranscation:(SKPaymentTransaction *)transaction {
    NSString *productIdentifier = transaction.payment.productIdentifier;
    if (productIdentifier.length > 0) {
        //一般是要向服务器验证购买凭证
        //验证凭据，获取到苹果返回的交易凭据
        // appStoreReceiptURL iOS7.0增加的，购买交易完成后，会将凭据存放在该地址
        NSURL *receiptURL = [NSBundle.mainBundle appStoreReceiptURL];
        
        //从沙盒中获取到购买凭据
        NSData *receipt = [NSData dataWithContentsOfURL:receiptURL];
        
        NSString *version = [UIDevice.currentDevice systemVersion];
        NSString *mainVersion = version.pathComponents.firstObject;
        NSData *data = nil;
        if (mainVersion.floatValue < 7.0) {
            data = transaction.transactionReceipt;
        } else {
            data = receipt;
        }
        NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSString *base64 = [[result dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
        NSLog(@"PurchaseKit----[交易结果:%@]", base64);
    }
}
- (void)restoreTranscation:(SKPaymentTransaction *)transaction {
    
}
- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    
}

-(void)dealloc {
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

@end
