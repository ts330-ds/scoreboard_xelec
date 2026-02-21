//
//  FitBLEBridge.m
//  Runner
//

#import "FitBLEBridge.h"

@implementation FitBLEBridge

+ (void)setup {
    [FitBLECentralManager BLEinitMivsn];
}

+ (void)setScanNameFilter:(NSString *)name {
    [[FitBLECentralManager shareInstance] BLEScanNameStr:name];
}

+ (void)stopScan {
    [[FitBLECentralManager shareInstance] BLESaomiaoStop];
}

+ (void)pairDevice:(CBPeripheral *)peripheral {
    [[FitBLECentralManager shareInstance] BLEConnect:peripheral];
}

+ (void)sendCommand:(NSString *)command {
    [[FitBLECentralManager shareInstance] BLEReadData:command];
}

@end
