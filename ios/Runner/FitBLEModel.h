//
//  FitBLEModel.h
//  XFitness
//
//  Created by 郭志奇 on 2019/4/26.
//  Copyright © 2019 郭志奇. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

@interface FitBLEModel : NSObject

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) NSString *ServiceName;
@property (nonatomic, strong) NSString *UUIDString;
@property (nonatomic, copy) NSString *RSSIStr;

@end

NS_ASSUME_NONNULL_END
