//
//  HTTPSWithSNIScene.m
//  httpdns_ios_demo
//
//  Created by Miracle on 2024/5/24.
//  Copyright © 2024 alibaba. All rights reserved.
//

#import "HTTPSWithSNIScene.h"
#import <AlicloudHttpDNS/AlicloudHttpDNS.h>
#import "HttpDnsNSURLProtocolImpl.h"

@interface HTTPSWithSNIScene()

@end

@implementation HTTPSWithSNIScene

+ (void)beginQuery:(NSString *)originalUrl completionHandler:(void(^)(NSString * ip, NSString * text))completionHandler {
    // 组装提示信息
    __block NSMutableString *tipsInfo = [NSMutableString string];

    // 初始化httpdns实例
    HttpDnsService *httpdns = [HttpDnsService sharedInstance];

    NSURL *url = [NSURL URLWithString:originalUrl];
    NSMutableURLRequest *request;

    HttpdnsResult *result = [httpdns resolveHostSyncNonBlocking:url.host byIpType:HttpdnsQueryIPTypeBoth];
    NSLog(@"resolve result: %@", result);
    NSString *validIp = nil;

    if (result) {
        if (result.hasIpv4Address) {
            // 使用ip
            validIp = result.firstIpv4Address;

            // 使用ip列表
            // NSArray<NSString *> *ips = result.ips;
            // 根据业务场景进行ip使用
            /*
             * validIp = result.ips.firstObject;
             */
        } else if (result.hasIpv6Address) {
            // 使用ip
            validIp = result.firstIpv6Address;

            // 使用ip列表
            // NSArray<NSString *> *ips = result.ipv6s;
            // 根据业务场景进行ip使用
            /*
             * validIp = result.ipv6s.firstObject;
             */
        } else {
            // 无有效ip
        }
    }

    if (validIp) {
        // 通过HTTPDNS获取IP成功，进行URL替换和HOST头设置
        NSLog(@"Get IP(%@) for host(%@) from HTTPDNS Successfully!", validIp, url.host);
        [tipsInfo appendFormat:@"Get IP(%@) for host(%@) from HTTPDNS Successfully!", validIp, url.host];

        NSRange hostFirstRange = [originalUrl rangeOfString:url.host];
        if (NSNotFound != hostFirstRange.location) {
            NSString *newUrl = [originalUrl stringByReplacingCharactersInRange:hostFirstRange withString:validIp];
            NSLog(@"New URL: %@", newUrl);
            request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:newUrl]];
            // 设置请求HOST字段
            [request setValue:url.host forHTTPHeaderField:@"host"];
        }
    } else {
        // 本处演示如何做好降级处理
        // 通过HTTPDNS无法获取IP，直接使用原有的URL进行网络请求
        request = [[NSMutableURLRequest alloc] initWithURL:url];
        NSLog(@"Get IP for host(%@) from HTTPDNS failed!", url.host);
        [tipsInfo appendFormat:@"Get IP for host(%@) from HTTPDNS failed!", url.host];
    }

    // NSURLSession例子
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    [configuration setProtocolClasses:@[[HttpDnsNSURLProtocolImpl class]]];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:nil];
    NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"error: %@", error);
        } else {
            if (validIp != nil) {
                NSString *responseStr = [NSString stringWithFormat:@"response: %@",response];
                if (responseStr != nil) {
                    [tipsInfo appendFormat:@"\n\n %@",responseStr];
                }

                NSString *dataStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
                if (dataStr != nil) {
                    [tipsInfo appendFormat:@"\n\n data:\n %@",dataStr];
                }
            }

            if (completionHandler) {
                completionHandler(validIp,tipsInfo);
            }
            NSLog(@"response: %@", response);
            NSLog(@"data: %@", data);
        }
    }];
    [task resume];
}

@end
