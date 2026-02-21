//
//  FitBLEBridge.h
//  Runner
//
//  Thin ObjC wrapper around FitBLECentralManager to expose
//  all SDK methods with Swift-compatible names.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "FitBLECentralManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface FitBLEBridge : NSObject

/// Initialises the BLE central manager (wraps +BLEinitMivsn)
+ (void)setup;

/// Sets the device-name filter before scanning (wraps -BLEScanNameStr:)
+ (void)setScanNameFilter:(NSString *)name;

/// Stops the current BLE scan (wraps -BLESaomiaoStop)
+ (void)stopScan;

/// Connects to the given peripheral (wraps -BLEConnect:)
+ (void)pairDevice:(CBPeripheral *)peripheral;

/// Sends a data command to the device (wraps -BLEReadData:)
+ (void)sendCommand:(NSString *)command;

@end

NS_ASSUME_NONNULL_END
