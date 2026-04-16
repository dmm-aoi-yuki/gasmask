//
//  NotificationHelper.m
//  Gas Mask
//
//  Created by Siim Raud on 16.11.12.
//  Copyright (c) 2012 Clockwise. All rights reserved.
//

#import "NotificationHelper.h"

@implementation NotificationHelper

+ (void)notify:(NSString*)title message:(NSString*)message
{
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = title;
    notification.informativeText = message;
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    #pragma clang diagnostic pop
}

@end
