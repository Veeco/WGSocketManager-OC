//
//  WGEncodeManager.h
//  Demo
//
//  Created by VS on 23/01/2017.
//  Copyright © 2017 JianWei. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WGEncodeManager : NSObject

/**
 * 加密数据
 * 参数 data 要加密的数据
 * 参数 encodeType 加密类型 1 -> 异或加密
 * 返回 加密后的数据
 */
+ (nonnull NSData *)writeWithData:(nonnull NSData *)data encodeType:(Byte)encodeType encodeKey:(nonnull NSString *)encodeKey;

/**
 * 解密数据
 * 参数 data 要解密的数据
 * 参数 encodeType 加密类型 1 -> 异或加密
 * 返回 解密后的数据
 */
+ (nonnull NSData *)readWithData:(nonnull NSData *)data encodeType:(Byte)encodeType encodeKey:(nonnull NSString *)encodeKey;

@end
