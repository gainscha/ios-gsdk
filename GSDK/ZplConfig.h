//
//  ZplConfig.h
//  GSDK
//
//  Created by max on 2021/3/1.
//  Copyright © 2021 max. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM (NSUInteger,ZPLORIENTATION) {
    ZPL_NORMAL = 0,
    ZPL_ROATED = 1,
    ZPL_INVERTED = 2,
    ZPL_BOTTOM = 3
};

@interface BarCodeConfig : NSObject
@property(nonatomic, assign) ZPLORIENTATION orienftation;  //条码方向
@property(nonatomic, assign) int barHeight;                //条码高度 (dot)
@property(nonatomic, assign) int wh;                       //条码宽窄比，默认2，范围 1 ～ 10
@property(nonatomic, assign) BOOL isNote;                  //是否显示条码文字，默认YES
@property(nonatomic, assign) BOOL isAbove;                 //条码文字是否在上方，默认NO,在下方
@end

@interface QrCodeConfig : NSObject
@property(nonatomic, assign) int mode;                     //模式 默认值: 2(增强型) 其他值: 1(原始型)
@property(nonatomic, assign) int mFactor;                  //放大因子 默认值:2(200dpi 机器)/3(300dpi 机器) 其他值:1 到 10
@property(nonatomic, strong) NSString *ecclever;           //纠错率：默认值:Q(参数为空)/M(参数非法) 其他值:H = 超高纠错等级 Q = 高纠错等级 M = 普通纠错等级 L = 高密度等级
@property(nonatomic, assign) int maskValue;                //掩码 默认值: 7 其他值: 0 到 7
@end

