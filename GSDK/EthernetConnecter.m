//
//  EthernetConnecter.m
//  GSDK
//
//  Created by max on 2020/10/30.
//  Copyright © 2020 Handset. All rights reserved.
//

#import "EthernetConnecter.h"
#include <netinet/in.h>
#include <sys/socket.h>
#include <arpa/inet.h>

@interface EthernetConnecter(){
    BOOL isLooper;
}
@property(nonatomic,assign)BOOL isConnected;
@end

@implementation EthernetConnecter

-(void)connectIP:(NSString *)ip port:(int)port connectState:(void (^)(ConnectState state))connectState callback:(void (^)(NSData *))callback {
    self.readData = callback;
    [self connectIP:ip port:port connectState:connectState];
}

-(void)connectIP:(NSString *)ip port:(int)port connectState:(void (^)(ConnectState))connectState {
    self.ip = ip;
    self.port = port;
    self.state = connectState;
    [self connect];
}

-(void)connect {
    sockfd = -1;
    self.state(CONNECT_STATE_CONNECTING);
    [self initEthernetConnecter];
}

-(void)connect:(void (^)(ConnectState))connectState {
    self.state = connectState;
    [self connect];
}

int sockfd = -1;
int len = 0;
in_addr_t addr_in;
unsigned short port;
struct sockaddr_in ser_addr;

-(void)initEthernetConnecter {
    isLooper = NO;
    sockfd = socket(AF_INET,SOCK_STREAM,IPPROTO_IP);
    if (-1 == sockfd) {
        self.state(CONNECT_STATE_FAILT);
        perror("Failed to sockfd");
        return;
    }
    NSString *ip = self.ip;
    memset(&ser_addr,0,sizeof(ser_addr));
    ser_addr.sin_family = AF_INET;
    ser_addr.sin_port = htons(9100);
    ser_addr.sin_addr.s_addr = inet_addr([ip UTF8String]);
    if(-1 == connect(sockfd,(const struct sockaddr *)&ser_addr,sizeof(ser_addr)))
    {
        perror("Failed to connect");
        [self closePort];
        self.state(CONNECT_STATE_FAILT);
        return ;
    }
    isLooper = YES;
    [self read];
    self.state(CONNECT_STATE_CONNECTED);
}

/**
 *  关闭端口
 */
-(void)close {
    [self closePort];
    //更新连接状态
    if (self.state) {
        self.state(CONNECT_STATE_DISCONNECT);
    }
}

-(void)closePort {
    if (sockfd > 0) {
        close(sockfd);
        sockfd = -1;
    }
    isLooper = NO;
}

/**
 *  读取数据
 */
-(void)read {
    [self recvData];
}

/**
 *  接收数据
 */
-(void)recvData {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        char recv_buf[256];
        @try
        {
            while (self->isLooper) { // old:while (isLooper) {
                memset(recv_buf, 0, 256);
                long recv_len = recv(sockfd,recv_buf,32,0);
                if (self.readData && recv_len > 0) {
                    NSData *data = [NSData dataWithBytes:recv_buf length:recv_len];
                    self.readData(data);
                    sleep(10);
                }else if(recv_len<0){
                    NSLog(@"[EthernetConnecter] receiver data error -> recv_len<0");
                    [self close];
                    free(recv_buf);
                }
            }
        }
        @catch(NSException *exception)
        {
            NSLog(@"[EthernetConnecter] receiver data error -> %@",exception);
            [self close];
            free(recv_buf);
        }
    });
}

/**
 *  读取数据
 *  使用block方式返回接收数据
 */
-(void)read:(void (^)(NSData *))data {
    self.readData = data;
    [self read];
}

/**
 *  写数据
 *  @param data 需要写入输出流中的数据
 *  @parma receCallBack 接收到数据时回调
 */
-(void)write:(NSData *)data receCallBack:(void (^)(NSData *))callBack {
    self.readData = callBack;
    [self write:data];
}

/**
 *  写数据
 *  @param data 需要写入输出流中的数据
 */
-(void)write:(NSData *)data {
    if (sockfd == -1) {
        return;
    }
    signal(SIGPIPE, SIG_IGN);
    char *send_buf = (char *)[data bytes];
    ssize_t kk = send(sockfd, send_buf,[data length], 0);
    //收到断开服务器，重新连接
    if (kk == -1) [self close];
}

@end

