//
//  WGCompressManager.h
//  Demo
//
//  Created by VS on 23/01/2017.
//  Copyright © 2017 JianWei. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WGCompressManager : NSObject

/**
 * 压缩数据
 * 参数 data 要压缩的数据
 * 参数 compressType 压缩类型 1 -> gzip压缩
 * 返回 压缩后的数据
 */
+ (nonnull NSData *)writeWithData:(nonnull NSData *)data andCompressType:(Byte)compressType;

/**
 * 解压数据
 * 参数 data 要解压的数据
 * 参数 compressType 压缩类型 1 -> gzip压缩
 * 返回 解压后的数据
 */
+ (nonnull NSData *)readWithData:(nonnull NSData *)data andCompressType:(Byte)compressType;

@end
