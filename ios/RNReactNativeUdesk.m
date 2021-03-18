
#import "RNReactNativeUdesk.h"
#import <UdeskSDK/SDK/UdeskCustomer.h>
#import <UdeskSDK/SDK/UdeskOrganization.h>
#import <UdeskSDK/SDK/UdeskManager.h>
#import <UdeskSDK/UDChatMessage/Udesk.h>
#import <UdeskSDK/UDChatMessage/UDTools/Config/UdeskSDKStyle.h>
#import <UdeskSDK/UDChatMessage/UDTools/Config/UdeskSDKManager.h>

#import <React/RCTEventDispatcher.h>
#import <React/RCTBridge.h>

static RCTResponseSenderBlock _callback;
static NSDictionary * _userInfo;


@implementation RNReactNativeUdesk

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}
RCT_EXPORT_MODULE()

@synthesize bridge = _bridge;

RCT_EXPORT_METHOD(initSDK:(NSString *)udeskDomain appKey:(NSString *)udeskAppkey appId:(NSString *)udeskAppId userInfo:(NSDictionary *)userInfo) {
    _userInfo = userInfo;
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
       
       [defaultCenter removeObserver:self];
       
       [defaultCenter addObserver:self
                         selector:@selector(noti_receiveRemoteNotification:)
                             name:UD_RECEIVED_NEW_MESSAGES_NOTIFICATION
                           object:nil];
    [defaultCenter addObserver:self
                      selector:@selector(noti_receiveUdeskInfoRemoteNotification:)
                          name:@"UD_GET_CUSTOMERID"
                        object:nil];
    [defaultCenter addObserver:self
                      selector:@selector(noti_receiveUdeskInfoRemoteNotification:)
                          name:@"UD_GET_IMSUBSESSIONID"
                        object:nil];
    
    
    //初始化公司（appKey、appID、domain都是必传字段）
    UdeskOrganization *organization = [[UdeskOrganization alloc] initWithDomain:udeskDomain appKey:udeskAppkey appId:udeskAppId];

    //注意sdktoken 是客户的唯一标识，用来识别身份,是你们生成传入给我们的。
    //sdk_token: 传入的字符请使用 字母 / 数字 等常见字符集 。就如同身份证一样，不允许出现一个身份证号对应多个人，或者一个人有多个身份证号;其次如果给顾客设置了邮箱和手机号码，也要保证不同顾客对应的手机号和邮箱不一样，如出现相同的，则不会创建新顾客。
    UdeskCustomer *customer = [UdeskCustomer new];
    //必填（请不要使用特殊字符）
    customer.sdkToken = userInfo[@"sdk_token"];
    //非必填可选主键，唯一客户外部标识，用于处理 唯一标识冲突 （请不要随意传值）
    customer.customerToken = userInfo[@"customerToken"];
    //非必填
    customer.nickName = userInfo[@"nick_name"];
    //需要严格按照邮箱规则（没有则不填，不可以为空）

    //需要严格按照号码规则（没有则不填，不可以为空）
    customer.cellphone = userInfo[@"cellphone"];
    
    UdeskCustomerCustomField *customerNameField = [UdeskCustomerCustomField new];
    customerNameField.fieldKey = userInfo[@"companyName_id"];
    customerNameField.fieldValue = userInfo[@"companyName"];
    
    UdeskCustomerCustomField *enterpriseIdField = [UdeskCustomerCustomField new];
    enterpriseIdField.fieldKey = userInfo[@"enterpriseID_id"];
    enterpriseIdField.fieldValue = userInfo[@"enterpriseID"];
    
    UdeskCustomerCustomField *roleField = [UdeskCustomerCustomField new];
    roleField.fieldKey = userInfo[@"role_id"];
    roleField.fieldValue = userInfo[@"role"];
    
    
    customer.customField = @[customerNameField,enterpriseIdField,roleField];
    

    //初始化sdk
    [UdeskManager initWithOrganization:organization customer:customer];
}

RCT_EXPORT_METHOD(setUserInfo:(NSDictionary *)options) {
    
}

RCT_EXPORT_METHOD(entryChat:(NSString * )imageUrl) {

    UdeskSDKStyle *sdkStyle = [UdeskSDKStyle customStyle];
    if (_userInfo != nil && _userInfo[@"headerImage"] != nil) {
        sdkStyle.customerImageURL = _userInfo[@"headerImage"];
    }
    
    
   NSBundle *libBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[RNReactNativeUdesk class]] pathForResource:@"UdeskBundle" ofType:@"bundle"]];
    NSString *resourceBundle = [[libBundle resourcePath] stringByAppendingPathComponent:@"arrow_back.png"];
    sdkStyle.navBackButtonImage = [UIImage imageWithContentsOfFile:resourceBundle];
    
    UIButton *right_Button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 44)];
    [right_Button setTitle:@"提交工单" forState:UIControlStateNormal];
    [right_Button setTitleColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:1] forState:UIControlStateNormal];
    right_Button.titleLabel.font = [UIFont systemFontOfSize:14];
    [right_Button addTarget:self action:@selector(right_BarButtonItemAction) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *right_BarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:right_Button];
    
    
    
    
    UdeskSDKConfig *sdkConfig = [UdeskSDKConfig customConfig];

    sdkConfig.backText = @"";
    sdkConfig.showTopCustomButtonSurvey = YES;
    sdkConfig.customRightBarButtonItems = @[right_BarButtonItem];
    
    if(imageUrl != nil) {
        NSURL * imgUrl = [NSURL URLWithString:imageUrl];
        NSData *imgData = [NSData dataWithContentsOfURL:imgUrl];
        UIImage *image =[UIImage imageWithData:imgData];
        if (imgData != nil) {
            sdkConfig.preSendMessages = @[image];
        }
        
    }
    
    
    UdeskSDKActionConfig *actionConfig = [UdeskSDKActionConfig new];
    //离开人工IM页面回调
    actionConfig.leaveChatViewControllerBlock = ^{
        NSLog(@"离开人工IM页面回调");
        [UdeskManager startUdeskPush];
    };
    
    
    UdeskSDKManager *sdkManager = [[UdeskSDKManager alloc] initWithSDKStyle:sdkStyle sdkConfig:sdkConfig sdkActionConfig:actionConfig];
    [sdkManager pushUdeskInViewController:[RNReactNativeUdesk getCurrentVC] completion:nil];
}

-(void)right_BarButtonItemAction{
    UIViewController *currentVC = [RNReactNativeUdesk getCurrentVC];
    [self.bridge.eventDispatcher sendAppEventWithName:@"openWorkOrder"
                                                 body:nil];
    [(UdeskChatViewController *)currentVC dismissChatViewController];
    NSLog(@"提交工单");
}

RCT_EXPORT_METHOD(getUnReadCount:(RCTResponseSenderBlock)callback){
    NSInteger count = (long)[UdeskManager getLocalUnreadeMessagesCount];
    callback(@[@{@"count": [NSNumber numberWithInteger:count]}]);
}

RCT_EXPORT_METHOD(openSDkPush) {
    [UdeskManager startUdeskPush];
}

RCT_EXPORT_METHOD(closeSDkPush) {
    [UdeskManager endUdeskPush];
}

RCT_EXPORT_METHOD(logoutUdesk) {
    [UdeskManager logoutUdesk];
}

RCT_EXPORT_METHOD(initSDkPushListen) {
    
}

- (void)noti_receiveRemoteNotification:(NSNotification *)notification {
//  id obj = [notification object];
    if ([notification.object isKindOfClass:[UdeskMessage class]]) {
        UdeskMessage *message = (UdeskMessage *)notification.object;
        NSLog(@"未读消息内容：%@",message.content);
        id obj = [notification object];
        [self.bridge.eventDispatcher sendAppEventWithName:@"arrivalNotification"
                                                     body:obj];

    } else {
        NSLog(@"%@", notification);
    
        [self.bridge.eventDispatcher sendAppEventWithName:@"arrivalNotification"
                                                     body:@{@"type": @"在线客服"}];
    }
//    if([userInfo[@"type"] isEqualToString:@"在线客服"]
}
-(void)noti_receiveUdeskInfoRemoteNotification:(NSNotification *)notification {
     id obj = [notification object];
    if (obj[@"customerID"] != nil) {
        [self.bridge.eventDispatcher sendAppEventWithName:@"UdeskInfoNotification"
                                                     body:@{@"customerID": obj[@"customerID"]}];
    }
    if (obj[@"imSubSessionID"] != nil) {
        [self.bridge.eventDispatcher sendAppEventWithName:@"UdeskInfoNotification"
                                                     body:@{@"imSubSessionID": obj[@"imSubSessionID"]}];
    }

}

//获取当前屏幕显示的viewcontroller
+ (UIViewController *)getCurrentVC {
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    UIViewController *currentVC = [self getCurrentVCFrom:rootViewController];
    
    return currentVC;
}

+ (UIViewController *)getCurrentVCFrom:(UIViewController *)rootVC {
    UIViewController *currentVC;
    
    if ([rootVC presentedViewController]) {
        
        rootVC = [rootVC presentedViewController];
    }
    
    if ([rootVC isKindOfClass:[UITabBarController class]]) {
        
        currentVC = [self getCurrentVCFrom:[(UITabBarController *)rootVC selectedViewController]];
        
    } else if ([rootVC isKindOfClass:[UINavigationController class]]){
        
        currentVC = [self getCurrentVCFrom:[(UINavigationController *)rootVC visibleViewController]];
        
    } else {
        
        currentVC = rootVC;
    }
    
    return currentVC;
}

@end
  
