//
//  WGDataManager.m
//  Demo
//
//  Created by VS on 23/01/2017.
//  Copyright © 2017 JianWei. All rights reserved.
//

#import "WGDataManager.h"

@implementation WGDataManager

/**
 * 数据 -> 二进制数据
 * 参数 data 要转换的数据(NSArray / NSDictionary)
 * 参数 dataType 数据类型 1 -> JSON
 * 返回 二进制数据
 */
+ (nonnull NSData *)writeWithData:(nonnull id)data andDataType:(Byte)dataType {

    NSData *newData = nil;
    
    // 如果是JSON格式
    if (dataType == 1 && ([data isKindOfClass:[NSArray class]] || [data isKindOfClass:[NSDictionary class]])) {
        
        newData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:nil];
    }
    return newData;
}

/**
 * 二进制数据 -> 数据
 * 参数 data 二进制数据
 * 参数 dataType 数据类型 1 -> JSON
 * 返回 数据(NSArray / NSDictionary)
 */
+ (nonnull id)readWithDada:(nonnull NSData *)data andDataType:(Byte)dataType {
    
    id newData = nil;
    
    // 如果是JSON格式
    if (dataType == 1) {
        
        newData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    }
    return newData;
}

@end
