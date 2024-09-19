//
//  Utils.h
//  GSDK
//
//  Created by max on 2020/11/02.
//  Copyright © 2020 Handset. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface GPUtils : NSObject

/**
 *  将图片转换为点阵图数据
 *
 *  @return 转化后的点阵图数据
 */
+(NSData *)escBitmapDataWithImage:(UIImage *)image andScaleWidth:(CGFloat)maxWidth andScaleHeight:(CGFloat)maxHeight;

/**
 *  方法说明：图片缩放
 *  @return 缩放后图片
 */
+(UIImage *)imageWithScaleImage:(UIImage *)image andScaleWidth:(int)width;

+(NSData *)printEscData:(UIImage *)image;

+(NSData *)printTscData:(UIImage *)image;

+(NSString *)printZplCmd:(UIImage *)image;

/**
 *  方法说明：Tsc指令图片数据
 *  @param image 图片
 *  @param mode 打印机图片打印模式
 *  @return Tsc图片数据
 */
+(NSData *)printTscData:(UIImage *)image andMode:(int)mode;

/**
 *  图像二值化处理
 */
+(UIImage *)binaryzation:(UIImage *)image;

/**
 *  图像灰度化处理
 *  @param  image 原图像
 */
+(UIImage *)grayImage:(UIImage *)image;

+(UIImage *)resizeImage:(UIImage *)image withWidth:(int)width withHeight:(int)height;

@end
