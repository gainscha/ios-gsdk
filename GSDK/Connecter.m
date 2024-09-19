//
//  Connecter.m
//  GSDK
//
//  Created by max on 2020/10/30.
//  Copyright © 2020 Handset. All rights reserved.
//

#import "Connecter.h"

@interface Connecter()

@end

@implementation Connecter

-(void)connect{}
-(void)connect:(void(^)(ConnectState state))connectState{}
-(void)close{}
-(void)write:(NSData *)data receCallBack:(void(^)(NSData *data))callBack{}
-(void)write:(NSData *)data{}
-(void)read:(void (^)(NSData *data))data{}

@end
