//
//  FitBLECentralManager.h
//  XFitness
//
//  Created by 郭志奇 on 2019/4/25.
//  Copyright © 2019 郭志奇. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "FitBLEModel.h"
#import "STTextHudTool.h"

@class FitBLECentralManager;
@protocol BLECentralDelegate <NSObject>

@optional

//可添加数据传输协议
- (void)FitScanDeviceArray:(NSMutableArray *_Nullable)DeviceArr;

- (void)FitConnectState:(BOOL)isConnect;

- (void)FitRunSParamter:(int)RunPara andFitKM:(float)FitKM andFitCalor:(float)FitCalor;

- (void)FitHeartParamter:(NSString *_Nonnull)HeartStr;

- (void)DianciStr:(NSString *_Nullable)DianStr;


@end

NS_ASSUME_NONNULL_BEGIN

@interface FitBLECentralManager : NSObject<CBPeripheralDelegate,CBCentralManagerDelegate>
{
    NSString *ScanNameStr;
}


#pragma mark - 蓝牙开发中心申明
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) CBCharacteristic *characteristic;

@property (nonatomic, strong)NSMutableArray *BLEDeviceArray;//保存设备信息的数组
@property (nonatomic, strong)NSMutableArray *NameSerArr;//保存设备信息的数组
@property (nonatomic, copy)NSString *FitChenSunStr;

@property (assign) id<BLECentralDelegate> _BLECentralDelegate;


//单利支持
+ (FitBLECentralManager *)shareInstance;

//初始化设备
+(void)BLEinitMivsn;

//可添加单利操作函数
//连接上
- (void)BLEConnect:(CBPeripheral *)peripheral;

//停止扫描
- (void)BLESaomiaoStop;

//断开设备连接
- (void)DissConnect;

//重新开始扫描
- (void)centralStartSaomiao;

//数据写入
- (void)BLEReadData:(NSString *)dataStr;

- (void)BLEScanNameStr:(NSString *)NameStr;

@end

NS_ASSUME_NONNULL_END
