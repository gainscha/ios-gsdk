//
//  Utils.m
//  GSDK
//
//  Created by max on 2020/11/02.
//  Copyright © 2020 Handset. All rights reserved.
//

#import "GPUtils.h"

typedef struct ARGBPixel{
    u_int8_t red;
    u_int8_t green;
    u_int8_t blue;
    u_int8_t alpha;
}ARGBPixel;

typedef NS_ENUM(NSInteger,BitPixels) {
    BPAlpha = 0,
    BPBlue = 1,
    BPGreen = 2,
    BPRed = 3
};

@implementation GPUtils

+(NSString *)printZplCmd:(UIImage *)image {
        image = [self grayImage:image];
        CGSize size =[image size];
        int width =size.width;
        int height =size.height;
            
        // 像素将画在这个数组
        uint32_t *pixels = (uint32_t *)malloc(width *height *sizeof(uint32_t));
        // 清空像素数组
        memset(pixels, 0, width*height*sizeof(uint32_t));
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        // 用 pixels 创建一个 context
        CGContextRef context =CGBitmapContextCreate(pixels, width, height, 8, width*sizeof(uint32_t), colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedLast);
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), [image CGImage]);
            
        int tt = 1;
        CGFloat intensity;
        int bw;
        NSMutableString *yw = [NSMutableString string];
        for (int y = 0; y <height; y++) {
            for (int x =0; x <width; x ++) {
                uint8_t *rgbaPixel = (uint8_t *)&pixels[y*width+x];
                intensity = (rgbaPixel[tt] + rgbaPixel[tt + 1] + rgbaPixel[tt + 2]) / 3. / 255.;

                // 若为彩色图片
    //            bw = intensity ==1?255:0;
    //            int bit = (bw)?0:1;
                    
                // 若为黑色图片
                bw = (intensity > 0.45)?255:0;
                int bit = (bw)?0:1;
                
                [yw appendFormat:@"%d",(bit)];
                
                rgbaPixel[tt] = bw;
                rgbaPixel[tt + 1] = bw;
                rgbaPixel[tt + 2] = bw;
            }
        }

        int imgW = width;
        int imgH = height;
        int w8 = imgW / 8;
        int remain = imgW % 8;
        NSMutableString *result = [NSMutableString string];
        
        for (int i = 0; i < imgH; i ++) {
            for (int j = 0; j < w8; j ++) {
                [result appendString:[self returnHexString:[yw substringWithRange:NSMakeRange(8*j + i*imgW, 8)]]];
                }
                if (remain > 0) {
                    NSString *jk = [yw substringWithRange:NSMakeRange(imgW - remain + i*imgW, remain)];
                    if (jk.length == 1) jk = [NSString stringWithFormat:@"%@0000000",jk];
                    if (jk.length == 2) jk = [NSString stringWithFormat:@"%@000000",jk];
                    if (jk.length == 3) jk = [NSString stringWithFormat:@"%@00000",jk];
                    if (jk.length == 4) jk = [NSString stringWithFormat:@"%@0000",jk];
                    if (jk.length == 5) jk = [NSString stringWithFormat:@"%@000",jk];
                    if (jk.length == 6) jk = [NSString stringWithFormat:@"%@00",jk];
                    if (jk.length == 7) jk = [NSString stringWithFormat:@"%@0",jk];
                    [result appendString:[self returnHexString:jk]];
                }
                
            }
        return result;
}

// 二进制字符串转16进制字符串
+ (NSString *)returnHexString:(NSString *)nb {
    long nice = strtol([nb UTF8String], NULL, 2);
    NSString * hexString=[[NSString alloc]initWithFormat:@"%lx",nice];
    
    if ([hexString length] == 2) {
        return hexString;
    } else {
        return [NSString stringWithFormat:@"0%@",hexString];
    }
    return hexString;
}

+(UIImage *)imageWithscaleImage:(UIImage *)image andScaleWidth:(CGFloat)maxWidth andScaleHeight:(CGFloat)maxHeight {
    CGFloat width = image.size.width;
    CGFloat height = image.size.height;
    if (maxHeight == 0) {
        maxHeight = (int)(maxWidth * height / width);
    }

    if (maxWidth == 0) {
        maxWidth = (int)(maxHeight * width / height);
    }

    CGSize size = CGSizeMake(maxWidth, maxHeight + 24);
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, maxWidth, maxHeight + 24)];
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resultImage;
}


//
+(NSData *)escBitmapDataWithImage:(UIImage *)image andScaleWidth:(CGFloat)maxWidth andScaleHeight:(CGFloat)maxHeight{
    image = [self imageWithscaleImage:image andScaleWidth:maxWidth andScaleHeight:maxHeight];
    CGImageRef imageRef = image.CGImage;
    // Create a bitmap context to draw the uiimage into
    CGContextRef context = [self bitmapRGBA8Context:image];
    
    if(!context) {
        return nil;
    }
    
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    
    CGRect rect = CGRectMake(0, 0, width, height);
    
    // Draw image into the context to get the raw image data
    CGContextDrawImage(context, rect, imageRef);
    
    // Get a pointer to the data
    uint32_t *bitmapData = (uint32_t *)CGBitmapContextGetData(context);
    
    
    if(bitmapData) {
        
        uint8_t *m_imageData = (uint8_t *) malloc(width * height/8 + 8*height/8);
        memset(m_imageData, 0, width * height/8 + 8*height/8);
        int result_index = 0;
        
        for(int y = 0; (y + 24) < height; ) {
            m_imageData[result_index++] = 27;
            m_imageData[result_index++] = 51;
            m_imageData[result_index++] = 0;
            
            m_imageData[result_index++] = 27;
            m_imageData[result_index++] = 42;
            m_imageData[result_index++] = 33;
            
            m_imageData[result_index++] = width%256;
            m_imageData[result_index++] = width/256;
            for(int x = 0; x < width; x++) {
                int value = 0;
                for (int temp_y = 0 ; temp_y < 8; ++temp_y)
                {
                    uint8_t *rgbaPixel = (uint8_t *) &bitmapData[(y+temp_y) * width + x];
                    uint32_t gray = 0.3 * rgbaPixel[BPRed] + 0.59 * rgbaPixel[BPGreen] + 0.11 * rgbaPixel[BPBlue];
                    
                    if (gray < 127)
                    {
                        value += 1<<(7-temp_y)&255;
                    }
                    
                }
                m_imageData[result_index++] = value;
                
                value = 0;
                for (int temp_y = 8 ; temp_y < 16; ++temp_y)
                {
                    uint8_t *rgbaPixel = (uint8_t *) &bitmapData[(y+temp_y) * width + x];
                    uint32_t gray = 0.3 * rgbaPixel[BPRed] + 0.59 * rgbaPixel[BPGreen] + 0.11 * rgbaPixel[BPBlue];
                    
                    if (gray < 127)
                    {
                        value += 1<<(7-temp_y%8)&255;
                    }
                    
                }
                m_imageData[result_index++] = value;
                
                value = 0;
                for (int temp_y = 16 ; temp_y < 24; ++temp_y)
                {
                    uint8_t *rgbaPixel = (uint8_t *) &bitmapData[(y+temp_y) * width + x];
                    uint32_t gray = 0.3 * rgbaPixel[BPRed] + 0.59 * rgbaPixel[BPGreen] + 0.11 * rgbaPixel[BPBlue];
                    
                    if (gray < 127)
                    {
                        value += 1<<(7-temp_y%8)&255;
                    }
                    
                }
                m_imageData[result_index++] = value;
            }
            m_imageData[result_index++] = 13;
            m_imageData[result_index++] = 10;
            y += 24;
        }
        
        NSMutableData *data = [[NSMutableData alloc] initWithCapacity:0];
        [data appendBytes:m_imageData length:result_index];
        
        free(bitmapData);
        return data;
    }
    
    NSLog(@"Error getting bitmap pixel data\n");
    CGContextRelease(context);
    
    return nil ;
}

+ (CGContextRef)bitmapRGBA8Context:(UIImage *)image
{
    CGImageRef imageRef = image.CGImage;
    if (!imageRef) {
        return NULL;
    }
    
    CGContextRef context = NULL;
    CGColorSpaceRef colorSpace;
    uint32_t *bitmapData;
    
    size_t bitsPerPixel = 32;
    size_t bitsPerComponent = 8;
    size_t bytesPerPixel = bitsPerPixel / bitsPerComponent;
    
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    
    size_t bytesPerRow = width * bytesPerPixel;
    size_t bufferLength = bytesPerRow * height;
    
    colorSpace = CGColorSpaceCreateDeviceRGB();
    
    if(!colorSpace) {
      //  Log(@"Error allocating color space RGB\n");
        return NULL;
    }
    
    // Allocate memory for image data
    bitmapData = (uint32_t *)malloc(bufferLength);
    
    if(!bitmapData) {
        //Log(@"Error allocating memory for bitmap\n");
        CGColorSpaceRelease(colorSpace);
        return NULL;
    }
    
    //Create bitmap context
    context = CGBitmapContextCreate(bitmapData,
                                    width,
                                    height,
                                    bitsPerComponent,
                                    bytesPerRow,
                                    colorSpace,
                                    kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedLast);    // RGBA
    if(!context) {
        free(bitmapData);
       // Log(@"Bitmap context not created");
    }
    CGColorSpaceRelease(colorSpace);
    return context;
}


+ (UIImage *)resizeImage:(UIImage *)image withWidth:(int)width withHeight:(int)height {
    CGSize size = CGSizeMake(width, height);
    UIGraphicsBeginImageContextWithOptions(size, NO, 1.0f);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resultImage;
}

/**
 *  方法说明：图片缩放
 *  @return 缩放后图片
 */
+(UIImage *)imageWithScaleImage:(UIImage *)image andScaleWidth:(int)width {
    width = (int)((width + 7) / 8 * 8);
    int height = image.size.height * width / image.size.width;
    CGSize size = CGSizeMake(width, height);
    UIGraphicsBeginImageContextWithOptions(size, NO, 1.0f);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resultImage;
}

/**
 *  方法说明：ESC指令图片数据
 *  @return ESC图片数据
 */
+(NSData *)printEscData:(UIImage *)image {
    return [self printImageData:[self getBitmapImageData:image printPoint:0x01 notPrintPoint:0x00]];
}

/**
 *  方法说明：Tsc指令图片数据
 *  @return Tsc图片数据
 */
+(NSData *)printTscData:(UIImage *)image {
    return [self printImageData:[self getBitmapImageData:image printPoint:0x00 notPrintPoint:0x01]];
}

/**
 *  方法说明：Tsc指令图片数据
 *  @param image 图片
 *  @param mode 打印机图片打印模式
 *  @return Tsc图片数据
 */
+(NSData *)printTscData:(UIImage *)image andMode:(int)mode {
    uint8_t printPorint = 0x00;
    uint8_t notPrintPoint = 0x01;
    if (mode == 3) {
        printPorint = 0x01;
        notPrintPoint = 0x00;
    }
    return [self printImageData:[self getBitmapImageData:image printPoint:printPorint notPrintPoint:notPrintPoint]];
}

/**
 *  方法说明：将图片数据处理成打印机图片数据
 *  @return 打印机图片数据
 */
+(NSData *)printImageData:(NSDictionary *)bi {
    const char *bytes = [bi[@"bitmap"] bytes];
    int width = [bi[@"width"] intValue];
    int height = [bi[@"height"] intValue];
    int w8 = width / 8;
    int remain = width % 8;
    NSMutableData *data = [[NSMutableData alloc]init];
    for (int i = 0; i < height; i++) {
        for (int j = 0; j < w8; j++) {
            u_int8_t n = 0;
            for (int k = 0 ; k < 8; k++) {
                int index = i * width + k + j * 8;
                u_int8_t ch = bytes[index];
                [self updatePrintPoint:ch :&n];
            }
            [data appendBytes:&n length:1];
        }
        if (remain > 0) {
            uint8_t n = 0;
            for (int k = 1; k <= remain; k++) {
                int index = i * width + width - remain + k;
                uint8_t ch = bytes[index];
                [self updatePrintPoint:ch :&n];
            }
            [data appendBytes:&n length:1];
        }
    }
    return data;
}

+(void)updatePrintPoint:(uint8_t)ch :(uint8_t *)n {
    *n = *n << 1;
    *n = *n | ch;
}

/**
 *  方法说明：将图片数据进行二值化处理
 *  @param printP 可打印点
 *  @param nPrintP 不可打印点
 *  @return NSDictionary 处理后图片数据和图片宽高
 */
+(NSDictionary *)getBitmapImageData:(UIImage *)m_image printPoint:(u_int8_t)printP notPrintPoint:(u_int8_t)nPrintP {
    CGImageRef cgImage = [m_image CGImage];
    size_t width = CGImageGetWidth(cgImage);
    size_t height = CGImageGetHeight(cgImage);
    
    u_int32_t *pixels = malloc(width * height *sizeof(u_int32_t));
    memset(pixels, 0, width * height * sizeof(u_int32_t));
    NSMutableData* data = [[NSMutableData alloc] init];
    //初始化图片通道为RGB通道
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    //获取图片RGB通道数据，并赋值给pixels
    CGContextRef context = CGBitmapContextCreate(pixels, width, height, 8, width * sizeof(u_int32_t), colorSpaceRef, kCGBitmapByteOrder32Little|kCGImageAlphaPremultipliedLast);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage);
    int total = (int)width * (int)height;
    //灰度化
    [self grayForImageData:pixels width:width height:height];
    //二值化阀值
    int iterative = [self iterativeBinaryzation:pixels withTotalPixel:total];
    if (iterative < 1 || iterative > 255) {
        iterative = 127;
    }

    //将图片数据进行二值化处理，并将数据存至data中
    for (int h = 0; h < height; h++) {
        for (int w = 0; w < width; w++) {
            int pIndex = w + h * (int)width;
            //获取像素点
            u_int8_t *pixel = (u_int8_t *)&pixels[pIndex];
            //获取像素点的b(Blue)通道值
            u_int8_t a = pixel[0];
            u_int8_t b = pixel[1];
            u_int8_t ch;
            if (b < iterative && a >60) {
                ch = printP;
            } else {
                ch = nPrintP;
            }
            [data appendBytes:&ch length:1];
        }
    }
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpaceRef);
    free(pixels);
    return @{@"bitmap":data,@"width":@(width),@"height":@(height)};
}

/**
 *  图像二值化处理
 */
+(UIImage *)binaryzation:(UIImage *)image {
    CGImageRef imageRef = image.CGImage;
    int width = image.size.width;
    int height = image.size.height;
    int memorySize = width * height *sizeof(u_int32_t);
    u_int32_t *pixels = (u_int32_t *)malloc(memorySize);
    memset(pixels, 0, memorySize);
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixels, width, height, 8, width * sizeof(u_int32_t), colorSpaceRef, kCGBitmapByteOrder32Little|kCGImageAlphaPremultipliedLast);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    int totalPixels = width * height;
    [self grayForImageData:pixels width:width height:height];
    int threshold = [self iterativeBinaryzation:pixels withTotalPixel:totalPixels];
    if (threshold < 1 || threshold > 255) {
        threshold = 127;
    }
    //NSLog(@"threshold -> %d",threshold);
    for (int i = 0; i < totalPixels; i++) {
        u_int8_t *pixel = (u_int8_t *)&pixels[i];
        u_int8_t b = pixel[1];//blue通道
        u_int8_t a = pixel[0];//alpha通道
        if (threshold > b && a > 100) {
            pixel[0] = 255;
            pixel[1] = 0;
            pixel[2] = 0;
            pixel[3] = 0;
        } else {
            pixel[0] = 255;
            pixel[1] = 255;
            pixel[2] = 255;
            pixel[3] = 255;
        }
    }
    CGImageRef c_image = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpaceRef);
    UIImage *resultImage= [UIImage imageWithCGImage:c_image];
    free(pixels);
    CGImageRelease(c_image);
    return resultImage;
}

/**
 * 二值化自适应阀值
 */
+(int)iterativeBinaryzation:(void *)pixels withTotalPixel:(int)total {
    if (pixels == NULL) {
        @throw [[NSException alloc]initWithName:@"NULLPointerException" reason:@"pixels is null" userInfo:nil];
    }
    int averageBinaryzation = [self averageValueBinaryzation:pixels withTotalPixel:total];
    int lastBinaryzaion = 256;
    int binaryzation = averageBinaryzation;
    while ((binaryzation - lastBinaryzaion)!=0) {
        int c1 = 0;
        int j1 = 0;
        int c2 = 0;
        int j2 = 0;
        for (int i = 0; i < total; i++) {
            u_int8_t * pixel = (u_int8_t *)&pixels[i];
            u_int8_t b = pixel[1];
            if (binaryzation > b) {
                c1 += b;
                j1++;
            } else {
                c2 += b;
                j2++;
            }
        }
        if(j1 == 0){
            j1 = 1;
        }
        if (j2 == 0) {
            j2 = 1;
        }
        binaryzation = (c1 / j1 + c2 /j2)/2;
        lastBinaryzaion = binaryzation;
    }
    return binaryzation;
}

/**
 *  图像灰度化处理
 *  @param  image 原图像
 */
+(UIImage *)grayImage:(UIImage *)image {
    CGImageRef imageRef = image.CGImage;
    int width = image.size.width;
    int height = image.size.height;
    int menorySize = width * height * sizeof(u_int32_t);
    u_int32_t *pixels = (u_int32_t *)malloc(menorySize);
    memset(pixels, 0, menorySize);
    CGColorSpaceRef colorRef = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixels, width, height, 8, width * sizeof(u_int32_t), colorRef, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedLast);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    for (int h = 0; h < height; h++) {
        for (int w = 0; w < width; w++) {
            u_int8_t *pixel = (u_int8_t *)&pixels[h * width + w];
            u_int8_t r = pixel[3];
            u_int8_t g = pixel[2];
            u_int8_t b = pixel[1];
            u_int8_t grey = (u_int8_t)(0.11 * r + 0.59 * g + 0.3 * b);
            pixel[1] = grey;
            pixel[2] = grey;
            pixel[3] = grey;
        }
    }
    CGImageRef c_image = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGColorSpaceRelease(colorRef);
    free(pixels);
    UIImage *resultImage = [UIImage imageWithCGImage:c_image];
    CGImageRelease(c_image);
    return resultImage;
}

+(int)averageValueBinaryzation:(void *)pixels withTotalPixel:(int)total {
    int grayValue = 0;
    for (int i = 0; i<total; i++) {
        u_int8_t * pixel = (u_int8_t *)&pixels[i];
        grayValue += pixel[3];
    }
    return grayValue / total;
}

/**
 *  灰度化
 */
+(void)grayForImageData:(u_int32_t *)pixels width:(size_t)width height:(size_t)height {
    for (int h = 0; h < height; h++) {
        for (int w = 0; w < width; w ++) {
            int pIndex = w + h * (int)width;
            uint8_t *pixel = (uint8_t *)&pixels[pIndex];
            uint8_t red = pixel[1];
            uint8_t green = pixel[2];
            uint8_t blue = pixel[3];
            uint8_t gray = (int)(0.11 * red + 0.59 * green + 0.3 * blue);
            pixel[1] = gray;
            pixel[2] = gray;
            pixel[3] = gray;
        }
    }
}

@end
