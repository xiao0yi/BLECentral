//
//  ViewController.m
//  centralDemo
//
//  Created by Mac chen on 16/5/2.
//  Copyright © 2016年 Mac chen. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _centralManager = [[CBCentralManager alloc]initWithDelegate:self queue:nil];
    
    _data = [[NSMutableData alloc]init];
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central{

    
    if(central.state != CBCentralManagerStatePoweredOn){
    
        return;
    }
    
    [self scan];
}

- (void)scan{

    
    [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]] options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES}];
    
    [self.activityInddicatorView startAnimating];
    
    self.scanLabel.hidden = NO;
    
    NSLog(@"Scanning started");
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI{

    if(RSSI.integerValue > -15){
    
        return;
    }
    if(RSSI.integerValue < -35){
    
        return;
    }
    
    NSLog(@"发现外设 %@ at %@",peripheral.name,RSSI);
    
    if(self.discoveredPheral != peripheral){
    
        self.discoveredPheral = peripheral;
        
        [self.centralManager stopScan];
        
        NSLog(@"连接外设 %@ :",peripheral);
        
        [self.centralManager connectPeripheral:peripheral options:nil];
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{

    NSLog(@"外设已连接");
    
    //    [self.centralManager stopScan];
    //
    //    NSLog(@"扫描停止");
    
    [self.data setLength:0];
    
    peripheral.delegate = self;
    [peripheral discoverServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]];
}

//- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
//
//    NSLog(@"外设已连接");
//    
////    [self.centralManager stopScan];
////    
////    NSLog(@"扫描停止");
//    
//    [self.data setLength:0];
//    
//    peripheral.delegate = self;
//    [peripheral discoverServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]];
//}

- (void)stop{

}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{

    NSLog(@"连接失败");
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{

    if(error){
    
        NSLog(@"Error discovering services");
        
        [self cleanup];
        return;
    }
    
    for (CBService *service in peripheral.services) {
        
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]] forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{

    if(error){
    
        NSLog(@"发现特征错误");
        
        [self cleanup];
        return;
    }
    
    for (CBCharacteristic *characteristic in service.characteristics) {
        
        if([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]]){
        
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
}

//读数据

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error{

    if(error){
    
        NSLog(@"发现特征错误");
        return;
    }
    
    NSString *stringFromData = [[NSString alloc]initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    
    if([stringFromData isEqualToString:@"EOM"]){
    
        //显示数据
        
        [self.textView setText:[[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding]];
        
        //取消特征预定
        [peripheral setNotifyValue:NO forCharacteristic:characteristic];
        
        //断开外设
        [self.centralManager cancelPeripheralConnection:peripheral];
    }
    
    //接受数据追加
    
    [self.data appendData:characteristic.value];
    NSLog(@"receive : %@",stringFromData);
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{

    if(error){
    
        NSLog(@"特征通知状态发生变化错误");
    }
    
    //如果没有特征传输过来则退出
    
    if(![characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]]){
    
        return;
    }
    
    //特征通知已经停止
    
    if(characteristic.isNotifying){
    
        NSLog(@"特征通知已经开始");
    }
    //特征通知已经停止
    else{
    
        NSLog(@"特征通知已经停止");
        [self.centralManager cancelPeripheralConnection:peripheral];
    }
    
}

- (void)viewWillDisappear:(BOOL)animated{

    [self.centralManager stopScan];
    
    [self.activityInddicatorView stopAnimating];
    
    NSLog(@"扫描停止");
    
    [super viewWillDisappear:animated];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{

    NSLog(@"外设已经断开");
    
    self.discoveredPheral = nil;
    
    //外设已经断开的情况下，重新扫描
    [self scan];

}

//- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
//
//    NSLog(@"外设已经断开");
//    
//    self.discoveredPheral = nil;
//    
//    //外设已经断开的情况下，重新扫描
//    [self scan];
//}

//清除方法

- (void)cleanup{

    //判断是否已经订阅了特征
    if(self.discoveredPheral.services != nil){
    
        for (CBService *service in self.discoveredPheral.services) {
            
            if(service.characteristics != nil){
            
                for (CBCharacteristic * characteristic in service.characteristics) {
                    
                    if([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]]){
                    
                        if(characteristic.isNotifying){
                        
                            //停止接收特征通知
                            [self.discoveredPheral setNotifyValue:NO forCharacteristic:characteristic];
                            
                            //断开与外设连接
                            [self.centralManager cancelPeripheralConnection:self.discoveredPheral];
                            return;
                        }
                    }
                }
            }
        }
    }
    
    [self.centralManager cancelPeripheralConnection:self.discoveredPheral];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
