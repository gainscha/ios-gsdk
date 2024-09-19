//
//  LifePrinterCommand.h
//  GSDK
//
//  Created by Onelong on 2024/2/19.
//  Copyright © 2024 handset. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LifePrinterCommand : NSObject
/**
 * 查询基本信息指令
 *
 */
+ (NSData*) getBaseInfo;


/**
 * 查询工作信息指令
 *
 */
+ (NSData*) getWorkInfo;

/**
 * 查询状态信息指令
 *
 */
+ (NSData*) getStatusInfo;

/**
 * 查询用户信息指令
 *
 */
+ (NSData*) getUserInfo;

/**
 * 设置蜂鸣器提示开关指令
 * @param on 是否开启
 */
+ (NSData*) setSound:(BOOL) on;

/**
 * 设置关机时间指令
 * @param type
 * type=0 不关机
 * type=1 5分钟
 * type=2 10分钟
 * type=3 15分钟
 * type=4 30分钟
 * type=5 1小时
 * type=6 2小时
 * type=7 4小时
 */
+ (NSData*) setPowerOff:(int)type;

/**
 * 设置打印耗材的宽度和高度
 * 说明：
 * w 打印宽度，范围0-48mm
 * h 打印高度，范围0-170mm
 * @param w  打印宽度，范围0-48mm
 * @param h 打印高度，范围0-170mm
 */
+ (NSData*) setSizeWith:(int)w  height:(int) h;

/**
 * 设置两张标签纸之间的间隙高度或者和黑标纸的黑标高度
 * 说明：m 两张标签纸之间的间隙高度或两张
 * 黑标纸之间的黑标高度，范围0-3mm
 * @param gap  黑标纸之间的黑标高度，范围0-3mm
 */
+ (NSData*) setGap:(int)gap;

/**
 * 学习标签，并走纸到下一张标签间隙
 */
+ (NSData*) home;

/**
 * 连续纸、标签纸、黑标纸之间切换
 * @param m
 * m=0 切换成连续纸
 * m=1 切换成标签纸
 * m=2 切换成黑标纸
 */
+ (NSData*) changeMode:(int)m;

/**
 * 设置打印浓度
 * @param m
 * m 打印浓度1-5档
 */
+ (NSData*) setDensity:(int)m;

/**
 * 完全执行打印
 * 说明：此语法用于异常纸张上报后，客户选择继续打印
 */
+ (NSData*) continuePrint;

/**
 * 打印自检页
 */
+ (NSData*) selfTest;

@end

NS_ASSUME_NONNULL_END

