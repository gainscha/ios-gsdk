//
//  Connecter.m
//  GSDK
//
//  Created by max on 2020/10/30.
//  Copyright © 2020 Handset. All rights reserved.
//

#import "BLEConnecter.h"

//GAP
#define UUIDSTR_GAP_SERVICE @"1800"

//Device Info service
#define UUIDSTR_DEVICE_INFO_SERVICE             @"180A"
#define UUIDSTR_MANUFACTURE_NAME_CHAR           @"2A29"
#define UUIDSTR_MODEL_NUMBER_CHAR               @"2A24"
#define UUIDSTR_SERIAL_NUMBER_CHAR              @"2A25"
#define UUIDSTR_HARDWARE_REVISION_CHAR          @"2A27"
#define UUIDSTR_FIRMWARE_REVISION_CHAR          @"2A26"
#define UUIDSTR_SOFTWARE_REVISION_CHAR          @"2A28"
#define UUIDSTR_SYSTEM_ID_CHAR                  @"2A23"
#define UUIDSTR_IEEE_11073_20601_CHAR           @"2A2A"

#define UUIDSTR_ISSC_PROPRIETARY_SERVICE        @"ServiceName"
#define UUIDSTR_CONNECTION_PARAMETER_CHAR       @"49535343-6DAA-4D02-ABF6-19569ACA69FE"
#define UUIDSTR_AIR_PATCH_CHAR                  @"49535343-ACA3-481C-91EC-D85E28A60318"
#define UUIDSTR_ISSC_TRANS_TX                   @"TxName"
#define UUIDSTR_ISSC_TRANS_RX                   @"RxName"
#define UUIDSTR_ISSC_MP                         @"49535343-ACA3-481C-91EC-D85E28A60318"

#define ISSC_RestoreIdentifierKey               @"ISSC_RestoreIdentifierKey"

@interface BLEConnecter()<CBCentralManagerDelegate,CBPeripheralDelegate>
{
    BOOL connected;
    //设置每个数据包大小
    NSUInteger sendMaxByte;
    //数据长度
    NSUInteger total;
    //已发送数据长度
    NSUInteger progress;
}

@property(nonatomic,strong)CBCentralManager *manager;

@property(nonatomic,strong) CBCharacteristic *manufactureNameChar;
@property(nonatomic,strong) CBCharacteristic *modelNumberChar;
@property(nonatomic,strong) CBCharacteristic *serialNumberChar;
@property(nonatomic,strong) CBCharacteristic *hardwareRevisionChar;
@property(nonatomic,strong) CBCharacteristic *firmwareRevisionChar;
@property(nonatomic,strong) CBCharacteristic *softwareRevisionChar;
@property(nonatomic,strong) CBCharacteristic *systemIDChar;
@property(nonatomic,strong) CBCharacteristic *certDataListChar;
@property(nonatomic,strong) CBCharacteristic *specificChar1;
@property(nonatomic,strong) CBCharacteristic *specificChar2;
// 数据队列，大约太多数据可能会暴掉，但是目前没测试出来
@property(nonatomic,strong)NSMutableArray *dataList;
// 防止并发写入
@property(nonatomic,assign)BOOL isBusy;
// 自定义流控标志
@property(nonatomic,assign)BOOL stoped;
@end

@implementation BLEConnecter


-(NSMutableArray *)dataList {
    if (!_dataList) {
        _dataList = [[NSMutableArray alloc]init];
    }
    return _dataList;
}

- (void)configureTransparentServiceUUID: (NSString *)serviceUUID txUUID:(NSString *)txUUID rxUUID:(NSString *)rxUUID {
    if (serviceUUID) {
        _transServiceUUID = [CBUUID UUIDWithString:serviceUUID];
        _transTxUUID = [CBUUID UUIDWithString:txUUID];
        _transRxUUID = [CBUUID UUIDWithString:rxUUID];
    }
    else {
        _transServiceUUID = nil;
        _transTxUUID = nil;
        _transRxUUID = nil;
    }
}

- (void)configureDeviceInformationServiceUUID:(NSString *)UUID1 UUID2:(NSString *)UUID2 {
    if (UUID1 || UUID2) {
        if (UUID1 != nil) {
            _disUUID1 = [CBUUID UUIDWithString:UUID1];
        }
        else _disUUID1 = nil;
        
        if (UUID2 != nil) {
            _disUUID2 = [CBUUID UUIDWithString:UUID2];
        }
        else _disUUID2 = nil;
    }
    else {
        _disUUID1 = nil;
        _disUUID2 = nil;
    }
}

/**
 *  方法说明: 开始扫描
 */
-(void)scanForPeripheralsWithServices:(nullable NSArray<CBUUID *> *)serviceUUIDs options:(nullable NSDictionary<NSString *, id> *)options discover:(void(^)(CBPeripheral *peripheral,NSDictionary<NSString *, id> *advertisementData,NSNumber *RSSI))discover {
    self.discover = discover;
    [_manager scanForPeripheralsWithServices:serviceUUIDs options:options];
}


/**
 *  方法说明: 停止扫描
 */
-(void)stopScan {
    [_manager stopScan];
}

-(void)close {
    [self closePeripheral:self.connPeripheral];
}

/**
 *  方法说明: 连接蓝牙设备
 */
-(void)connectPeripheral:(CBPeripheral *)peripheral options:(nullable NSDictionary<NSString *,id> *)options timeout:(NSUInteger)timeout connectBlack:(void(^)(ConnectState state))connectState {
    self.isBusy = NO;
    self.stoped = NO;
    [self.dataList removeAllObjects];
    if (peripheral == nil) {
        connectState(NOT_FOUND_DEVICE);
        return;
    }
    self.state = connectState;
    connected = NO;
    connectState(CONNECT_STATE_CONNECTING);
    [self connectPeripheral:peripheral options:options];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, timeout * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if(!self->connected) {
            [self->_manager cancelPeripheralConnection:self.connPeripheral];
            self.connPeripheral = nil;
            connectState(CONNECT_STATE_TIMEOUT);
        }
    });
}

/**
 *  方法说明: 关闭外设连接
 */
-(void)closePeripheral:(CBPeripheral *)peripheral {
    if (peripheral) {
        if(self.transparentDataReadOrNotifyChar){
            [peripheral setNotifyValue:NO forCharacteristic:self.transparentDataReadOrNotifyChar];
        }
        [_manager cancelPeripheralConnection:peripheral];
    }
}

/**
 *  方法说明: 更新连接状态
 *  @param connectState 返回状态block
 */
-(void)updateConnectState:(ConnectState)connectState {
    //更新连接状态
    if (self.state) {
        self.state(connectState);
    }
}

/**
 *  连接蓝牙设备
 */
-(void)connectPeripheral:(CBPeripheral *)peripheral options:(nullable NSDictionary<NSString *,id> *)options {
    self.isBusy = NO;
    self.stoped = NO;
    [self.dataList removeAllObjects];
    if (peripheral!=nil) {
        self.transparentDataWriteChar = nil;
        self.transparentDataReadOrNotifyChar = nil;
        self.connPeripheral = peripheral;
        [self.connPeripheral setDelegate:self];
        [_manager connectPeripheral:peripheral options:options];
    } else {
        if (self.state) {
            self.state(NOT_FOUND_DEVICE);
        }
    }
}

/**
 *  方法说明: 指定外设UUID连接
 *  @param identifier        外设UUID
 *  @param time              设置超时时间（0 < time）时间单位秒(s)
 *  @param connectState      连接状态
 */
-(void)connectPeripheralFormUUID:(NSString *_Nullable)identifier timeout:(NSUInteger)time connectState:(void(^)(ConnectState state))connectState {
//    NSLog(@"------- connectPeripheralFormUUID");
    self.isBusy = NO;
    self.stoped = NO;
    [self.dataList removeAllObjects];
    self.state = connectState;
    connected = NO;
    __weak __typeof(self)weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf->connected) {
            connectState(CONNECT_STATE_TIMEOUT);
            if (strongSelf.connPeripheral) {
                [strongSelf.manager cancelPeripheralConnection:strongSelf.connPeripheral];
            }
        }
    });
    
//    NSArray *peripherals = [_manager retrieveConnectedPeripheralsWithServices:[NSArray arrayWithObject:[CBUUID UUIDWithString:@"49535343-FE7D-4AE5-8FA9-9FAFD205E455"]]];
//    NSLog(@"%@",_manager);
//    NSLog(@"%@",[NSArray arrayWithObject:identifier]);
//    
    NSArray *peripherals = [_manager retrievePeripheralsWithIdentifiers:[NSArray arrayWithObject:[[NSUUID alloc]initWithUUIDString:identifier]]];
//    NSLog(@"%@",peripherals);
    if (peripherals) {
        for (CBPeripheral *peripheral in peripherals) {
//            NSLog(@"------- %@", peripheral);
            connectState(CONNECT_STATE_CONNECTING);
            [self connectPeripheral:peripheral options:nil];
        }
    } else {
        connectState(NOT_FOUND_DEVICE);
    }
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.characteristicWriteType = CBCharacteristicWriteWithResponse;
        [self initParament];
    }
    return self;
}

/**
 *  方法说明：初始化参数
 */
-(void)initParament {
    _manager = [CBCentralManager alloc];
    if ([_manager respondsToSelector:@selector(initWithDelegate:queue:options:)]) {
//                _manager = [_manager initWithDelegate:self queue:dispatch_get_main_queue() options:@{CBCentralManagerOptionRestoreIdentifierKey: ISSC_RestoreIdentifierKey,CBCentralManagerOptionShowPowerAlertKey:@(YES)}];
        _manager = [_manager initWithDelegate:self queue:dispatch_get_main_queue() options:@{CBCentralManagerOptionShowPowerAlertKey:@(YES)}];
    }
    else {
        _manager = [_manager initWithDelegate:self queue:nil];
    }
    _transServiceUUID = nil;
    _transTxUUID = nil;
    _transRxUUID = nil;
    _disUUID1 = nil;
    _disUUID2 = nil;
    self.serviceUUID = @[@{UUIDSTR_ISSC_PROPRIETARY_SERVICE:@"49535343-FE7D-4AE5-8FA9-9FAFD205E455",UUIDSTR_ISSC_TRANS_TX:@"49535343-1E4D-4BD9-BA61-23C647249616",UUIDSTR_ISSC_TRANS_RX:@"49535343-8841-43F4-A8D4-ECBE34729BB3"},@{UUIDSTR_ISSC_PROPRIETARY_SERVICE:@"E7810A71-73AE-499D-8C15-FAA9AEF0C3F2",UUIDSTR_ISSC_TRANS_TX:@"BEF8D6C9-9C21-4C9E-B632-BD58C1009F9F",UUIDSTR_ISSC_TRANS_RX:@"BEF8D6C9-9C21-4C9E-B632-BD58C1009F9F"}];
}

-(void)parseData:(NSData*)data{
    Byte *bytes = (Byte *)[data bytes];
    NSString *hexStr=@"";
    for(int i=0; i < [data length]; i++) {
        NSString *newHexStr = [NSString stringWithFormat:@"%x",bytes[i]&0xff];
        if([newHexStr length]==1){
            hexStr = [NSString stringWithFormat:@"%@0%@",hexStr,newHexStr];
        }
        else{
            hexStr = [NSString stringWithFormat:@"%@%@",hexStr,newHexStr];
        }
    }
    hexStr = [hexStr uppercaseString];
    if([hexStr isEqualToString:@"1F051314"]){
        self.stoped = YES;
    }else if([hexStr isEqualToString:@"1F051122"]){
        self.stoped = NO;
        @synchronized (self.dataList) {
            if(self.dataList.count > 0){
                NSData* d = self.dataList.firstObject;
                [self writeValue:d forCharacteristic:self.transparentDataWriteChar type:CBCharacteristicWriteWithoutResponse];
                [self.dataList removeObjectAtIndex:0];
                if (self.writeProgress) {
                    progress += 1;
                    self.writeProgress(total, progress);
                }
            }
        }
    }
}

-(void)didUpdateState:(void(^)(NSInteger state))state {
    self.updateState = state;
}


#pragma CBCentralManagerDelegate
/*
 Invoked whenever the central manager's state is updated.
 */
- (void) centralManagerDidUpdateState:(CBCentralManager *)central {
    self.updateState([central state]);
}

//- (void) centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)dict {
//}

/*
 Invoked when the central discovers heart rate peripheral while scanning.
 */
- (void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)aPeripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    if (self.discover) {
        self.discover(aPeripheral, advertisementData, RSSI);
    }
}

/*
 Invoked when the central manager retrieves the list of known peripherals.
 Automatically connect to first known peripheral
 */
- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals {
    //    PrintLog(@"[BLEConnecter] didRetrrievePeripherals -> %@",peripherals);
}

/*
 Invoked whenever a connection is succesfully created with the peripheral.
 Discover available services on the peripheral
 */
- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)aPeripheral {
    connected = YES;
    [self.connPeripheral setDelegate:self];
    [self.connPeripheral discoverServices:nil];
}

/*
 Invoked whenever an existing connection with the peripheral is torn down.
 Reset local variables
 */
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)aPeripheral error:(NSError *)error {
    //    NSLog(@"error -> %@",error);
    if (connected) {
        if (self.state) {
            self.state(CONNECT_STATE_DISCONNECT);
        }
    } else {
        if (self.state) {
            self.state(CONNECT_STATE_FAILT);
        }
    }
    connected = NO;
    //    self.connPeripheral = nil;
}

/*
 Invoked whenever the central manager fails to create a connection with the peripheral.
 */
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)aPeripheral error:(NSError *)error {
    if (self.state) {
        self.state(CONNECT_STATE_FAILT);
        self.connPeripheral = nil;
    }
}

#pragma mark - CBPeripheral delegate methods
/*
 Invoked upon completion of a -[discoverServices:] request.
 Discover available characteristics on interested services
 */
- (void) peripheral:(CBPeripheral *)aPeripheral didDiscoverServices:(NSError *)error {
    for (CBService *service in aPeripheral.services) {
        [aPeripheral discoverCharacteristics:nil forService:service];
    }
}

/*
 Invoked upon completion of a -[discoverCharacteristics:forService:] request.
 Perform appropriate operations on interested characteristics
 */
- (void) peripheral:(CBPeripheral *)aPeripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (self.transparentDataWriteChar == nil && self.transparentDataReadOrNotifyChar == nil) {
        for (NSDictionary *dict in self.serviceUUID) {
            NSString *serviceName = [dict objectForKey:UUIDSTR_ISSC_PROPRIETARY_SERVICE];
            if(serviceName == nil) {
                return;
            }
            
            for (CBCharacteristic *characteristic in service.characteristics) {
                if (_transServiceUUID && [service.UUID isEqual:_transServiceUUID]) {
                    if ([characteristic.UUID isEqual:_transRxUUID]) {
                        [self setTransparentDataWriteChar:characteristic];
                        if (self.state) {
                            self.state(CONNECT_STATE_CONNECTED);
                        }
                    }
                    else if ([characteristic.UUID isEqual:_transTxUUID]) {
                        [self setTransparentDataReadOrNotifyChar:characteristic];
                    }
                }
                
                else if ([service.UUID isEqual:[CBUUID UUIDWithString:serviceName]]) {
                    NSString *RxUUID = [dict objectForKey: UUIDSTR_ISSC_TRANS_RX];
                    //NSLog(@"Rx:%@",RxUUID);
                    NSString *TxUUID = [dict objectForKey:UUIDSTR_ISSC_TRANS_TX];
                    //NSLog(@"Tx:%@",TxUUID);
                    
                    if ((_transServiceUUID == nil) && [characteristic.UUID isEqual:[CBUUID UUIDWithString:RxUUID]]) {
                        NSLog(@"write char");
                        [self setTransparentDataWriteChar:characteristic];
                    }
                    if ((_transServiceUUID == nil) && [characteristic.UUID isEqual:[CBUUID UUIDWithString:TxUUID]]) {
                        NSLog(@"notify char");
                        [self setTransparentDataReadOrNotifyChar:characteristic];
                        [self.connPeripheral setNotifyValue:YES forCharacteristic:characteristic];
                    }
                    else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_CONNECTION_PARAMETER_CHAR]]) {
                        [self setConnectionParameterChar:characteristic];
                    }
                    else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_AIR_PATCH_CHAR]]) {
                        [self setAirPatchChar:characteristic];
                    }
                }
                else if([service.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_DEVICE_INFO_SERVICE]]) {
                    
                    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_MANUFACTURE_NAME_CHAR]]) {
                        [self setManufactureNameChar:characteristic];
                    }
                    else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_MODEL_NUMBER_CHAR]]) {
                        [self setModelNumberChar:characteristic];
                    }
                    else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_SERIAL_NUMBER_CHAR]]) {
                        [self setSerialNumberChar:characteristic];
                    }
                    else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_HARDWARE_REVISION_CHAR]]) {
                        [self setHardwareRevisionChar:characteristic];
                    }
                    else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_FIRMWARE_REVISION_CHAR]]) {
                        [self setFirmwareRevisionChar:characteristic];
                    }
                    else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_SOFTWARE_REVISION_CHAR]]) {
                        [self setSoftwareRevisionChar:characteristic];
                    }
                    else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_SYSTEM_ID_CHAR]]) {
                        [self setSystemIDChar:characteristic];
                    }
                    else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_IEEE_11073_20601_CHAR]]) {
                        [self setCertDataListChar:characteristic];
                    }
                    else if (_disUUID1 && [characteristic.UUID isEqual:_disUUID1]) {
                        [self setSpecificChar1:characteristic];
                    }
                    else if (_disUUID2 && [characteristic.UUID isEqual:_disUUID2]) {
                        [self setSpecificChar2:characteristic];
                    }
                }
                if (self.transparentDataWriteChar != nil && self.transparentDataReadOrNotifyChar != nil) {
                    if(self.state){
                        self.state(CONNECT_STATE_CONNECTED);
                    }
                    break;
                }
            }
            if (self.transparentDataWriteChar != nil && self.transparentDataReadOrNotifyChar != nil) {
                if(self.state){
                    self.state(CONNECT_STATE_CONNECTED);
                }
                break;
            }
        }
    }
}

/*
 Invoked upon completion of a -[readValueForCharacteristic:] request or on the reception of a notification/indication.
 */
- (void) peripheral:(CBPeripheral *)aPeripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (aPeripheral == nil) {
        return;
    }
//    NSLog(@"[BLEConnecter] peripheral:didUpdateValueForCharacteristic:error: %@",error);
    NSData *data = [characteristic value];
    if ([data length] > 0) {
        [self parseData:data];
        if(self.readData) {
            self.readData(data);
        }
    }
}

- (void) peripheral:(CBPeripheral *)aPeripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
//    NSLog(@"[BLEConnecter] peripheral:didWriteValueForCharacteristric:error: %@",error);
    NSUInteger sendC = total / sendMaxByte;
    if((sendC * sendMaxByte) == progress) {
        NSInteger remain = total % sendMaxByte;
        [self updateProgress:remain];
    } else {
        [self updateProgress:sendMaxByte];
    }
}

- (void) peripheral:(CBPeripheral *)aPeripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
//    NSLog(@"[BLEConnecter] peripheral:didDiscoverDesctiptorsForCharacteristic:error: %@",error);
}

- (void) peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error {
//    NSLog(@"[BLEConnecter] peripheral:didUpdateValueForDescriptor:error: %@",error);
}

-(void) peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        return;
    }
//    NSLog(@"peripheral:didUpdateNotificationStateForCharacteristic:error:charateristic -> %@, %@",characteristic, error);
}

- (void)peripheralIsReadyToSendWriteWithoutResponse:(CBPeripheral *)peripheral{
//    NSLog(@"peripheralIsReadyToSendWriteWithoutResponse");
    // 要适当延时，不然外设的流控标志位发不过来
    __weak __typeof(self)weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_MSEC * 3), dispatch_get_main_queue(), ^{
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        @synchronized (self.dataList) {
            if(strongSelf.dataList.count > 0 && !strongSelf.stoped){
                NSData* d = strongSelf.dataList.firstObject;
                [strongSelf writeValue:d forCharacteristic:strongSelf.transparentDataWriteChar type:self.characteristicWriteType];
                [strongSelf.dataList removeObjectAtIndex:0];
//                NSLog(@"dataList size: %@", @(strongSelf.dataList.count));
                if (strongSelf.writeProgress) {
                    strongSelf->progress += 1;
                    strongSelf.writeProgress(strongSelf->total, strongSelf->progress);
                }
            }else if(strongSelf.dataList.count <= 0){
                self.isBusy = NO;
            }
        }
        
    });
    
}

-(void)read:(void (^)(NSData *))data {
    self.readData = data;
    //    PrintLog(@"transparentDataReadChar -> %@",self.transparentDataReadOrNotifyChar);
//    NSLog(@"transparentDataReadChar -> %@",self.transparentDataReadOrNotifyChar);
}

-(void)write:(NSData *)data receCallBack:(void(^)(NSData *data))callBack {
    [self read:callBack];
    [self write:data];
}

-(void)write:(NSData *_Nullable)data progress:(void(^_Nullable)(NSUInteger total,NSUInteger progress))progress {
    self.writeProgress = progress;
    [self write:data];
}

-(void)write:(NSData *_Nullable)data progress:(void(^_Nullable)(NSUInteger total,NSUInteger progress))progress receCallBack:(void (^_Nullable)(NSData *_Nullable))callBack {
    self.writeProgress = progress;
    [self write:data receCallBack:callBack];
}

-(void)write:(NSData *)data {
    NSUInteger length = [data length];
    total = length;
    progress = 0;
    
    //设置最大传输单元
    sendMaxByte = [self.connPeripheral maximumWriteValueLengthForType:self.characteristicWriteType];
    
//    NSLog(@"%@,%@",@(max),@(length));
    NSInteger pCounts = length / sendMaxByte;
    NSInteger lastByte = length % sendMaxByte;
    
    if(self.characteristicWriteType == CBCharacteristicWriteWithResponse){
        if(pCounts > 0){
            for (int i = 0; i < pCounts * sendMaxByte; i += sendMaxByte) {
                [self.connPeripheral writeValue:[data subdataWithRange:NSMakeRange(i, sendMaxByte)] forCharacteristic:self.transparentDataWriteChar type:self.characteristicWriteType];
            }
        }
        if (lastByte > 0) {
            [self.connPeripheral writeValue:[data subdataWithRange:NSMakeRange(length - lastByte, lastByte)] forCharacteristic:self.transparentDataWriteChar type:self.characteristicWriteType];
        }
    }else{
        @synchronized (self.dataList) {
            if(pCounts > 0){
                for (int i = 0; i < pCounts * sendMaxByte; i += sendMaxByte) {
                    [self.dataList addObject:[data subdataWithRange:NSMakeRange(i, sendMaxByte)]];
                }
            }
            if (lastByte > 0) {
                [self.dataList addObject: [data subdataWithRange:NSMakeRange(length - lastByte, lastByte)]];
            }
            
            total = self.dataList.count;
            progress = 0;
            
            if(!self.isBusy && !self.stoped){
                if(self.dataList.count > 0){
                    self.isBusy = YES;
                    NSData* d = self.dataList.firstObject;
                    [self writeValue:d forCharacteristic:self.transparentDataWriteChar type:self.characteristicWriteType];
                    [self.dataList removeObjectAtIndex:0];
                    if (self.writeProgress) {
                        progress += 1;
                        self.writeProgress(total, progress);
                    }
                }
            }
        }
    }
}

-(void)updateProgress:(NSUInteger)length {
    if (self.writeProgress) {
        progress += length;
        self.writeProgress(total, progress);
    }
}

-(void)writeValue:(NSData *)data forCharacteristic:(nonnull CBCharacteristic *)characteristic type:(CBCharacteristicWriteType)type {
    [self.connPeripheral writeValue:data forCharacteristic:characteristic type:type];
}

@end
