//
//  CPCLCommand.m
//  GSDK
//
//  Created by max on 2020/11/02.
//  Copyright © 2020 Handset. All rights reserved.
//

#import "CPCLCommand.h"
#import "CPCLData.h"
@interface CPCLCommand()
@property(nonatomic, strong) NSMutableData *mCommandData;
@property (nonatomic, assign) int fontWidScale;
@property (nonatomic, assign) int fontHeiScale;

@end

@implementation CPCLCommand

-(id) init {
    
    self = [super init];
    if (self) {
        self.mCommandData = [NSMutableData data];
        self.fontWidScale = 1;
        self.fontHeiScale = 1;
    }
    
    return self;
}

/**
 * 方法说明：将字符串转成十六进制码
 * @param  str  命令字符串
 */
-(void) addStrToCommand:(NSString *) str {
    NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    if (self.mCommandData) {
        [self.mCommandData appendData:[str dataUsingEncoding:encoding]];
    }
}

-(void) addNSDataToCommand:(NSData*) data {
    if (self.mCommandData) {
        [self.mCommandData appendData:data];
    }
}


/**
 * 方法说明：初始化
 * @param offset 标签横向偏移量
 * @param height 标签最大高度
 * @param qty 打印标签的张数
 */
-(void)addInitializePrinterwithOffset:(int)offset withHeight:(int)height withQTY:(int)qty {
    NSString *string = [NSString stringWithFormat:@"! %d 200 200 %d %d\r\n",offset,height,qty];
    //NSLog(@"%@",string);
    [self addStrToCommand: string];
}


/**
 * 方法说明：打印标签
 */
-(void)addPrint {
    NSString *string = [NSString stringWithFormat:@"PRINT\r\n"];
    //NSLog(@"%@",string);
    [self addStrToCommand: string];
}


/**
 * 方法说明:获得打印命令
 * @return NSData
 */
-(NSData*) getCommand {
    return self.mCommandData;
}


/**
 * 方法说明：在标签上添加文本
 * @param type 指令
 * @param font 字体类型
 * @param x 横向起始位置
 * @param y 纵向起始位置
 * @param text 打印的文本
 */
-(void)addText:(TEXTCOMMAND)type withFont:(TEXTFONT)font withXstart:(int)x withYstart:(int)y withContent:(NSString*)text {
    NSString *commandstr;
    switch (type) {
        case 1:
            commandstr = @"VTEXT";
            break;
        case 2:
            commandstr = @"TEXT90";
            break;
        case 3:
            commandstr = @"TEXT180";
            break;
        case 4:
            commandstr = @"TEXT270";
            break;
        default:
            commandstr = @"TEXT";
            break;
    }
    NSString *string = [NSString stringWithFormat:@"%@ %u 0 %d %d %@\r\n",commandstr,font,x,y,text];
    //NSLog(@"%@",string);
    [self addStrToCommand: string];
}

/**
 * 方法说明：在标签上添加水印文本（2021-07-23新增）
 * @param type 指令
 * @param font 字体类型
 * @param x 横向起始位置
 * @param y 纵向起始位置
 * @param text 打印的文本
 * @param bold 是否加粗
 * @param w 宽度放大倍数，有效放大倍数为 1 到 16
 * @param h 高度放大倍数，有效放大倍数为 1 到 16
*/
-(void)drawWatermarks:(TEXTCOMMAND)type withFont:(TEXTFONT)font withXstart:(int)x withYstart:(int)y withContent:(NSString*)text withBold:(BOOL)bold withWidthScale:(int)w withHeightScale:(int)h {
    NSString *commandstr;
    switch (type) {
        case 1:
            commandstr = @"WATERMARK";
            break;
        case 2:
            commandstr = @"WATERMARK90";
            break;
        case 3:
            commandstr = @"WATERMARK180";
            break;
        case 4:
            commandstr = @"WATERMARK270";
            break;
        default:
            commandstr = @"WATERMARK";
            break;
    }
    
    int value = (bold)? 1: 0;
    
    // 打开字体放大
    if (w > 1 || h > 1) {
        [self addStrToCommand: [NSString stringWithFormat:@"SETMAG %d %d\r\n",w,h]];
    }
    
    // 如果是加粗，预先进行加粗
    if (value == 1) {
        [self addStrToCommand: @"SETBOLD 1\r\n"];
    }
    
    NSString *string = [NSString stringWithFormat:@"%@ %u 0 %d %d %@\r\n",commandstr,font,x,y,text];
    [self addStrToCommand: string];
    
    // 关闭加粗
    if (value == 1) {
        [self addStrToCommand: @"SETBOLD 0\r\n"];
    }
    
    if (w > 1 || h > 1) {
        [self addStrToCommand: @"SETMAG 0 0\r\n"];
    }
    
}

/**
 * 方法说明：在标签上添加多行文本，以"\n"标示换行
 * @param font 字体类型
 * @param x 横向起始位置
 * @param y 纵向起始位置
 * @param text 打印的文本
*/
-(void)addMultiLineWithFont:(TEXTFONT)font withXstart:(int)x withYstart:(int)y withContent:(NSString*)text {
    NSString *commandstr;
    int type = T;
    switch (type) {
        case 1:
            commandstr = @"VTEXT";
            break;
        case 2:
            commandstr = @"TEXT90";
            break;
        case 3:
            commandstr = @"TEXT180";
            break;
        case 4:
            commandstr = @"TEXT270";
            break;
        default:
            commandstr = @"TEXT";
            break;
    }
    
    
    NSArray *array = [text componentsSeparatedByString:@"\n"];
    [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *temp = (NSString *)obj;
        int yy = y + (int)idx*[self getCharacterHei:font];
        NSString *string = [NSString stringWithFormat:@"%@ %u 0 %d %d %@\r\n",commandstr,font,x,yy,temp];
        [self addStrToCommand: string];
    }];
    

}

/**
 * 方法说明：在标签上添加多行文本，根据文本宽高自动换行
 * @param font 字体类型
 * @param x 横向起始位置
 * @param y 纵向起始位置
 * @param width 文本宽度
 * @param fixHeight 高度约束，默认为0，自动计算当前高度，若手动输入高度，则高度不够，后面字符将不被显示
 * @param text 打印的文本
*/
-(void)addCustomMultiLineTextWithFont:(TEXTFONT)font withXstart:(int)x withYstart:(int)y withRowWidth:(int)width withFixHeight:(int)fixHeight withContent:(NSString*)text {
    int rowWid = width;
    NSMutableString *rowStr = [NSMutableString string];
    NSMutableArray *rowArr = [NSMutableArray array];
    for (int i = 0; i < text.length; i ++) {
        NSString *temp = [text substringWithRange:NSMakeRange(i, 1)];
        int textWid = [self getTextWid:temp withFont:font];
        [rowStr appendString:temp];
        rowWid = rowWid - textWid;
        if (rowWid <= 0) {
            [rowArr addObject:rowStr];
            rowWid = width;
            rowStr = [NSMutableString string];
        }
        
        // 结尾
        if (i == (text.length - 1) && rowWid > 0) {
            [rowArr addObject:rowStr];
        }
    }
    
    if (rowArr.count) {
        if (fixHeight <= 0) {
            [rowArr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *temp = (NSString *)obj;
                int yy = y + (int)idx*[self getCharacterHei:font]*self.fontHeiScale;
                [self addText:T withFont:font withXstart:x withYstart:yy withContent:temp];
            }];
        } else {
            __block int height = fixHeight;
            [rowArr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *temp = (NSString *)obj;
                int texthei = self.fontHeiScale*[self getCharacterHei:font];
                height = height - texthei;
                if (height < 0) {
                    *stop = YES;
                } else {
                    int yy = y + (int)idx*[self getCharacterHei:font];
                    [self addText:T withFont:font withXstart:x withYstart:yy withContent:temp];
                }
                
            }];
        }
        
    }

}

/**
 * 方法说明：在标签上添加反色文本
 * @param type 指令
 * @param font 字体类型
 * @param x 横向起始位置
 * @param y 纵向起始位置
 * @param text 打印的文本
 */
-(void)addReverseText:(TEXTCOMMAND)type withFont:(TEXTFONT)font withXstart:(int)x withYstart:(int)y withContent:(NSString*)text {
    NSString *commandstr;
    switch (type) {
        case 1:
            commandstr = @"VTEXT";
            break;
        case 2:
            commandstr = @"TEXT90";
            break;
        case 3:
            commandstr = @"TEXT180";
            break;
        case 4:
            commandstr = @"TEXT270";
            break;
        default:
            commandstr = @"TEXT";
            break;
    }
    NSString *string = [NSString stringWithFormat:@"%@ %u 0 %d %d %@\r\n",commandstr,font,x,y,text];
    //NSLog(@"%@",string);
    [self addStrToCommand: string];
    
    if (type == T) {
        int textWid = [self getTextWid:text withFont:font];//text.length*32;
        int texthei = self.fontHeiScale*[self getCharacterHei:font];
        
        NSString *string1 = [NSString stringWithFormat:@"INVERSE-LINE %d %d %d %d %d\r\n",x,y,x+textWid,y,texthei];
        [self addStrToCommand: string1];
    } else if (type == VT || type == T90){
        int textWid = [self getTextWid:text withFont:font];//text.length*32;
        int texthei = self.fontHeiScale*[self getCharacterHei:font];
        
        NSString *string1 = [NSString stringWithFormat:@"INVERSE-LINE %d %d %d %d %d\r\n",x,y - textWid,x+texthei,y - textWid,textWid];
        //NSLog(@"%@",string);
        [self addStrToCommand: string1];
    } else if (type == T270) {
        int textWid = [self getTextWid:text withFont:font];//text.length*32;
        int texthei = self.fontHeiScale*[self getCharacterHei:font];
        
        NSString *string1 = [NSString stringWithFormat:@"INVERSE-LINE %d %d %d %d %d\r\n",x - texthei,y,x,y,textWid];
        //NSLog(@"%@",string);
        [self addStrToCommand: string1];
    } else if (type == T180) {
        int textWid = [self getTextWid:text withFont:font];//text.length*32;
        int texthei = self.fontHeiScale*[self getCharacterHei:font];
        
        NSString *string1 = [NSString stringWithFormat:@"INVERSE-LINE %d %d %d %d %d\r\n",x - textWid,y -texthei ,x,y -texthei,texthei];
        //NSLog(@"%@",string);
        [self addStrToCommand: string1];
    }
}

/**
 * 方法说明：在标签上添加多行反色文本，以‘\n’标示换行
 * @param font 字体类型
 * @param x 横向起始位置
 * @param y 纵向起始位置
 * @param text 打印的文本
*/
-(void)addMultiLineReverseTextWithFont:(TEXTFONT)font withXstart:(int)x withYstart:(int)y withContent:(NSString*)text {
    NSArray *array = [text componentsSeparatedByString:@"\n"];
    [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *temp = (NSString *)obj;
        int yy = y + (int)idx*[self getCharacterHei:font];
        [self addReverseText:T withFont:font withXstart:x withYstart:yy withContent:temp];
    }];
}

/**
 * 方法说明：在标签上添加多行反色文本，根据文本宽高自动换行
 * @param font 字体类型
 * @param x 横向起始位置
 * @param y 纵向起始位置
 * @param width 文本宽度
 * @param fixHeight 高度约束，默认为0，自动计算当前高度，若手动输入高度，则高度不够，后面字符将不被显示
 * @param text 打印的文本
*/
-(void)addCustomMultiLineReverseTextWithFont:(TEXTFONT)font withXstart:(int)x withYstart:(int)y withRowWidth:(int)width withFixHeight:(int)fixHeight withContent:(NSString*)text {
    int rowWid = width;
    NSMutableString *rowStr = [NSMutableString string];
    NSMutableArray *rowArr = [NSMutableArray array];
    for (int i = 0; i < text.length; i ++) {
        NSString *temp = [text substringWithRange:NSMakeRange(i, 1)];
        int textWid = [self getTextWid:temp withFont:font];
        [rowStr appendString:temp];
        rowWid = rowWid - textWid;
        if (rowWid <= 0) {
            [rowArr addObject:rowStr];
            rowWid = width;
            rowStr = [NSMutableString string];
        }
        
        // 结尾
        if (i == (text.length - 1) && rowWid > 0) {
            [rowArr addObject:rowStr];
        }
    }
    
    if (rowArr.count) {
        if (fixHeight <= 0) {
            [rowArr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *temp = (NSString *)obj;
                int yy = y + (int)idx*[self getCharacterHei:font]*self.fontHeiScale;
                [self addReverseText:T withFont:font withXstart:x withYstart:yy withContent:temp];
            }];
        } else {
            __block int height = fixHeight;
            [rowArr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *temp = (NSString *)obj;
                int texthei = self.fontHeiScale*[self getCharacterHei:font];
                height = height - texthei;
                if (height < 0) {
                    *stop = YES;
                } else {
                    int yy = y + (int)idx*[self getCharacterHei:font];
                    [self addReverseText:T withFont:font withXstart:x withYstart:yy withContent:temp];
                }
                
            }];
        }
        
    }
}

/**
 * 方法说明：字体加粗：命令在设定后保持有效。这意味着要打印的下一部分标签内容将使用最 近设置的加粗指令值。要取消加粗请发送  setBold:0
 * @param isBold 是否加粗字体
*/
- (void)setBold:(BOOL)isBold {
    int value = (isBold)? 1: 0;
    NSString *string = [NSString stringWithFormat:@"SETBOLD %d\r\n",value];
    [self addStrToCommand: string];
}

// 判断一个字符是不是中文。


- (BOOL)isChinese:(NSString *)str
{
    NSString *match = @"(^[\u4e00-\u9fa5]+$)";//正常中文字符
    NSString *match2 = @"。？！，、；：“”‘'（）《》〈〉【】『』「」﹃﹄〔〕…—～﹏￥";// 中文标点符号
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF matches %@", match];
    if ([predicate evaluateWithObject:str] || [match2 containsString:str]) {
        return  YES;
    } else {
        return NO;
    }
    return YES;
}

- (int)getTextWid:(NSString *)text withFont:(TEXTFONT)font{
    int ChineseCount = 0;
    int EnglishCount = 0;
    for(int i =0; i < [text length]; i++)
    {
        NSString *temp = [text substringWithRange:NSMakeRange(i, 1)];
        if ([self isChinese:temp]) {
            ChineseCount ++;
        }
    }
    EnglishCount = (int)text.length - ChineseCount;
    
    return self.fontWidScale*EnglishCount*[self getEnglishCharacterWid:font] + self.fontWidScale*ChineseCount*[self getChineseCharacterWid:font];
}

// 中文宽度
- (int)getChineseCharacterWid:(TEXTFONT)font {
    switch (font) {
        case FONT_00: return 24; break;
        case FONT_01: return 24; break;
        case FONT_02: return 24; break;
        case FONT_03: return 20; break;
        case FONT_04: return 32; break;
        case FONT_05: return 24; break;
        case FONT_06: return 24; break;
        case FONT_07: return 24; break;
        case FONT_08: return 24; break;
        case FONT_010: return 48; break;
        case FONT_011: return 24; break;
        case FONT_013: return 24; break;
        case FONT_020: return 16; break;
        case FONT_024: return 24; break;
        case FONT_041: return 16; break;
        case FONT_042: return 24; break;
        case FONT_043: return 32; break;
        case FONT_044: return 48; break;
        case FONT_045: return 64; break;
        case FONT_046: return 28; break;
        case FONT_047: return 42; break;
        case FONT_048_00: return 28; break;
        case FONT_055: return 16; break;
        case FONT_028: return 28; break;
            
        default:
            break;
    }
    
    return 32;
}

// 英文宽度
- (int)getEnglishCharacterWid:(TEXTFONT)font {
    switch (font) {
        case FONT_00: return 12; break;
        case FONT_01: return 9; break;
        case FONT_02: return 12; break;
        case FONT_03: return 10; break;
        case FONT_04: return 16; break;
        case FONT_05: return 9; break;
        case FONT_06: return 12; break;
        case FONT_07: return 12; break;
        case FONT_08: return 12; break;
        case FONT_010: return 24; break;
        case FONT_011: return 8; break;
        case FONT_013: return 12; break;
        case FONT_020: return 8; break;
        case FONT_024: return 12; break;
        case FONT_041: return 8; break;
        case FONT_042: return 12; break;
        case FONT_043: return 16; break;
        case FONT_044: return 24; break;
        case FONT_045: return 32; break;
        case FONT_046: return 14; break;
        case FONT_047: return 21; break;
        case FONT_048_00: return 14; break;
        case FONT_055: return 8; break;
        case FONT_028: return 14; break;
        default:
            break;
    }
    
    return 32;
}

// 统一高度
- (int)getCharacterHei:(TEXTFONT)font {
    switch (font) {
        case FONT_00: return 24; break;
        case FONT_01: return 24; break;
        case FONT_02: return 24; break;
        case FONT_03: return 20; break;
        case FONT_04: return 32; break;
        case FONT_05: return 24; break;
        case FONT_06: return 24; break;
        case FONT_07: return 24; break;
        case FONT_08: return 24; break;
        case FONT_010: return 48; break;
        case FONT_011: return 24; break;
        case FONT_013: return 24; break;
        case FONT_020: return 16; break;
        case FONT_024: return 24; break;
        case FONT_041: return 12; break;
        case FONT_042: return 20; break;
        case FONT_043: return 24; break;
        case FONT_044: return 32; break;
        case FONT_045: return 48; break;
        case FONT_046: return 19; break;
        case FONT_047: return 27; break;
        case FONT_048_00: return 25; break;
        case FONT_055: return 16; break;
        case FONT_028: return 28; break;
        default:
            break;
    }
    
    return 32;
}

/**
 * 方法说明：将字体放大指定的放大倍数
 * @param w 宽度放大倍数，有效放大倍数为 1 到 16
 * @param h 高度放大倍数，有效放大倍数为 1 到 16
 */
-(void)addSetmagWithWidthScale:(int)w withHeightScale:(int)h {
    NSString *string = [NSString stringWithFormat:@"SETMAG %d %d\r\n",w,h];
    if (w < 1 || w > 16) {
        self.fontWidScale = 1;
    } else {
        self.fontWidScale = w;
    }
    
    if (h < 1 || h > 16) {
        self.fontHeiScale = 1;
    } else {
        self.fontHeiScale = h;
    }
    
    [self addStrToCommand: string];
}


/**
 * 方法说明：以指定的宽度和高度纵向和横向打印条码
 * @param command 横向或纵向打印
 * @param type 条码种类
 * @param width 条码窄条的单位宽度
 * @param ratio 条码宽条与窄条的比率
 * @param height  条码的单位高度
 * @param x 横向起始位置
 * @param y 纵向起始位置
 * @param text 条码内容
 */
-(void)addBarcode:(COMMAND)command withType:(CPCLBARCODETYPE)type withWidth:(int)width withRatio:(BARCODERATIO)ratio withHeight:(int)height withXstart:(int)x withYstart:(int)y withString:(NSString*)text {
    NSString *commandstr;
    switch (command) {
        case 1:
            commandstr = @"VBARCODE";
            break;
        default:
            commandstr = @"BARCODE";
            break;
    }
    
    NSString *cpclBarTypeStr;
    switch (type) {
        case 1:
            cpclBarTypeStr = @"128";
            break;
            
        case 2:
            cpclBarTypeStr = @"UPCA";
            break;
      
        case 3:
            cpclBarTypeStr = @"UPCE";
            break;
            
        case 4:
            cpclBarTypeStr = @"EAN13";
            break;
            
        case 5:
            cpclBarTypeStr = @"EAN8";
            break;
        case 6:
            cpclBarTypeStr = @"39";
            break;
        case 7:
            cpclBarTypeStr = @"93";
            break;
        case 8:
            cpclBarTypeStr = @"CODABAR";
            break;
            
        default:
            cpclBarTypeStr = @"128";
            break;
    }
    
    NSString *string = [NSString stringWithFormat:@"%@ %@ %d %u %d %d %d %@\r\n",commandstr,cpclBarTypeStr,width,ratio,height,x,y,text];
    [self addStrToCommand: string];
}


/**
 * 方法说明：打印二维码
 * @param command 横向或纵向打印
 * @param x 横向起始位置
 * @param y 纵向起始位置
 * @param n QR Code 规范编号,1 或 2，默认推荐为 2
 * @param u 模块的单位宽度/单位高度 1-32，默认为 6
 * @param text 二维码内容
 */
-(void)addQrcode:(COMMAND)command withXstart:(int)x withYstart:(int)y with:(int)n with:(int)u withString:(NSString*)text {
    NSString *commandstr;
    switch (command) {
        case 1:
            commandstr = @"VBARCODE";
            break;
        default:
            commandstr = @"BARCODE";
            break;
    }
    
    NSString *string = [NSString stringWithFormat:@"%@ QR %d %d M %d U %d\r\n",commandstr,x,y,n,u];
    
    // {date}格式如下:
    // <纠错等级><掩码><输入模式>,<所需生成二维码的数据>
    NSString *string1 = [NSString stringWithFormat:@"MA,%@\r\nENDQR\r\n",text];
    [self addStrToCommand: string];
    [self addStrToCommand: string1];
}


/**
 * 方法说明：添加条码注释
 * @param font 注释条码时要使用的字体号
 * @param offset 文本距离条码的单位偏移量
 */
-(void)addBarcodeTextWithFont:(int)font withOffset:(int)offset {
    NSString *string = [NSString stringWithFormat:@"BARCODE-TEXT %d 0 %d\r\n",font,offset];
    //NSLog(@"%@",string);
    [self addStrToCommand: string];
}


/**
 * 方法说明：禁用条码注释
 */
-(void)addBarcodeTextOff {
    [self addStrToCommand: [NSString stringWithFormat:@"BARCODE-TEXT OFF\r\n"]];
    //NSLog(@"BARCODE-TEXT OFF");
}


/**
 * 打印图片
 * @param command 指令
 * @param x 起始点的X 坐标
 * @param y 起始点的 Y 坐标
 * @param img 图片
 * @param maxWidth 最大宽度
 */
-(void)addGraphics:(GRAPHICS)command WithXstart:(int)x withYstart:(int)y withImage:(UIImage*)img withMaxWidth:(int)maxWidth {
    NSString *commandstr;
    switch (command) {
        case 1:
            commandstr = @"COMPRESSED-GRAPHICS";
            break;
        default:
            commandstr = @"EXPANDED-GRAPHICS";
            break;
    }

    CPCLData *p = [[CPCLData alloc]initWithUIImage:img maxWidth:maxWidth];
    NSData *data = [p printCPCLData];
    NSInteger w  = p.w;
    NSInteger h =  p.h;
    NSString *string = [NSString stringWithFormat:@"%@ %ld %ld %d %d ",commandstr,(long)w,(long)h,x,y];
    
    //NSLog(@"%@",string);
    
    [self addStrToCommand:string];
    
    [self.mCommandData appendData:data];
    
    [self addStrToCommand:@"\r\n"];

}


/**
 * 方法说明：打印任何长度、宽度和角度方向的线条
 * @param x 起始点的X 坐标
 * @param y 起始点的 Y 坐标
 * @param xend 终止点的 X 坐标
 * @param yend 终止点的 Y 坐标
 * @param width 线条的单位宽度
 */
-(void)addLineWithXstart:(int)x withYstart:(int)y withXend:(int)xend withYend:(int)yend  withWidth:(int)width {
    NSString *string = [NSString stringWithFormat:@"LINE %d %d %d %d %d\r\n",x,y,xend,yend,width];
    //NSLog(@"%@",string);
    [self addStrToCommand: string];
}


/**
 * 方法说明：打印指定线条宽度的矩形
 * @param x 左上角的X 坐标
 * @param y 左上角的 Y 坐标
 * @param xend 右下角的 X 坐标
 * @param yend 右下角的 Y 坐标
 * @param thickness 形成矩形框的线条的单位宽度
 */
-(void)addBoxWithXstart:(int)x  withYstart:(int)y withXend:(int)xend withYend:(int)yend  withThickness:(int)thickness {
    NSString *string = [NSString stringWithFormat:@"BOX %d %d %d %d %d\r\n",x,y,xend,yend,thickness];
    //NSLog(@"%@",string);
    [self addStrToCommand: string];
}


/**
 * 方法说明：绘制反显区域，应先添加内容后再添加反显区域
 * @param x 起始点的X 坐标
 * @param y 起始点的 Y 坐标
 * @param xend  终止点的 X 坐标
 * @param yend 终止点的 Y 坐标
 * @param width 反色区域高度
 */
-(void)addInverseLineWithXstart:(int)x withYstart:(int)y withXend:(int)xend withYend:(int)yend  withWidth:(int)width {
    NSString *string = [NSString stringWithFormat:@"INVERSE-LINE %d %d %d %d %d\r\n",x,y,xend,yend,width];
    //NSLog(@"%@",string);
    [self addStrToCommand: string];
}


/**
 * 方法说明：控制字段的对齐方式
 * @param align 对齐方式
 */
-(void)addJustification:(ALIGNMENT)align {
    NSString *str;
    switch (align) {
        case 1:
            str = @"LEFT";
            break;
        case 2:
            str = @"RIGHT";
            break;
        default:
            str = @"CENTER";
            break;
    }
    [self addStrToCommand: [NSString stringWithFormat:@"%@\r\n",str]];
  
}


/**
 * 方法说明：设置打印宽度
 * @param width 页面的单位宽度
 */
-(void)addPagewidth:(int)width {
    NSString *string = [NSString stringWithFormat:@"PAGE-WIDTH %d\r\n",width];
    //NSLog(@"%@",string);
    [self addStrToCommand: string];
}


/**
 * 方法说明：设置打印速度
 * @param level 打印速度
 */
-(void)addSpeed:(CPCLSPEED)level {
    NSString *string = [NSString stringWithFormat:@"SPEED %d\r\n",level];
    //NSLog(@"%@",string);
    [self addStrToCommand: string];
}


/**
 * 让方法说明：蜂鸣器发出给定时间长度的声音
 * @param beep_length 蜂鸣持续时间，以 1/8 秒为单位递增
 */
-(void)addBeep:(int)beep_length {
    NSString *string = [NSString stringWithFormat:@"BEEP %d\r\n",beep_length];
    //NSLog(@"%@",string);
    [self addStrToCommand: string];
}

-(void)queryPrinterStatus {
    unsigned char postfix[] = {0x1B, 0x68};
    [self.mCommandData  appendData: [NSData dataWithBytes:postfix length:sizeof(postfix)]];
}

@end
