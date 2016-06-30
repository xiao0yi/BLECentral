//
//  ViewController.h
//  centralDemo
//
//  Created by Mac chen on 16/5/2.
//  Copyright © 2016年 Mac chen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

#define TRANSFER_SERVICE_UUID @"43264C4E-CE41-4BBD-999F-1EA8015D81D0"
#define TRANSFER_CHARACTERISTIC_UUID @"97238A93-084A-472D-89C9-862289E4407E"

@interface ViewController : UIViewController<CBCentralManagerDelegate,CBPeripheralDelegate>

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityInddicatorView;
@property (weak, nonatomic) IBOutlet UITextField *scanLabel;
@property (weak, nonatomic) IBOutlet UITextView *textView;

@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) CBPeripheral *discoveredPheral;
@property (strong, nonatomic) NSMutableData *data;

@end

