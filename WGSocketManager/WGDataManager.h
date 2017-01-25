//
//  WGDataManager.h
//  Demo
//
//  Created by VS on 23/01/2017.
//  Copyright © 2017 JianWei. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WGDataManager : NSObject

/**
 * 数据 -> 二进制数据
 * 参数 data 要转换的数据(NSArray / NSDictionary)
 * 参数 dataType 数据类型 1 -> JSON
 * 返回 二进制数据
 */
+ (nonnull NSData *)writeWithData:(nonnull id)data andDataType:(Byte)dataType;

/**
 * 二进制数据 -> 数据
 * 参数 data 二进制数据
 * 参数 dataType 数据类型 1 -> JSON
 * 返回 数据(NSArray / NSDictionary)
 */
+ (nonnull id)readWithDada:(nonnull NSData *)data andDataType:(Byte)dataType;

@end
