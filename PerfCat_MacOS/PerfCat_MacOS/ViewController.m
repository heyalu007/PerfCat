//
//  ViewController.m
//  PerfCat_MacOS
//
//  Created by lucas on 2021/12/20.
//

#import "ViewController.h"

#import "PerfCatIOSDataReader.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    
    PerfCatIOSDataReader *iOSDataReader = [[PerfCatIOSDataReader alloc] init];
    
//    NSDictionary *packet = @{
//                             @"ClientVersionString": @"1",
//                             @"MessageType": @"Listen",
//                             @"ProgName": @"Peertalk Example"
//                             };
//    NSLog(@"send listen packet: %@", packet);
//    [iOSDataReader sendPacket:packet tag:0 callback:^(NSError * _Nonnull error) {
//        if (error) {
//            NSLog(@"%@", error);
//        }
//    }];
//
//    [iOSDataReader scheduleReadPacketWithBroadcastHandler:^(NSDictionary * _Nonnull packet) {
//        NSLog(@"%@", packet);
//    }];
    
    
    NSDictionary *packet = @{
                @"MessageType": @"ListDevices",
                @"ClientVersionString": @"libusbmuxd 1.1.0",
                @"ProgName": @"Peertalk Example",
                @"kLibUSBMuxVersion": @3,
    };
    
//    NSDictionary *packet = @{
//                @"MessageType": @"ReadPairRecord",
//                @"ClientVersionString": @"libusbmuxd 1.1.0",
//                @"PairRecordID": @"13d0bb579022d49cfbc8f708d57060f6de4523ba",
//                @"ProgName": @"Peertalk Example",
//                @"kLibUSBMuxVersion": @3,
////                "ProcessID": 0, # Xcode send it processID
//    };
    
    NSLog(@"send listen packet: %@", packet);
    [iOSDataReader sendPacket:packet tag:0 callback:^(NSError * _Nonnull error) {
        if (error) {
            NSLog(@"%@", error);
        }
    }];
    
    [iOSDataReader scheduleReadPacketWithBroadcastHandler:^(NSDictionary * _Nonnull packet) {
        NSLog(@"%@", packet);
    }];
    
}

//DeviceList =     (
//            {
//        DeviceID = 25;
//        MessageType = Attached;
//        Properties =             {
//            ConnectionSpeed = 480000000;
//            ConnectionType = USB;
//            DeviceID = 25;
//            LocationID = 1114112;
//            ProductID = 4776;
//            SerialNumber = 13d0bb579022d49cfbc8f708d57060f6de4523ba;
//            UDID = 13d0bb579022d49cfbc8f708d57060f6de4523ba;
//            USBSerialNumber = 13d0bb579022d49cfbc8f708d57060f6de4523ba;
//        };
//    }
//);


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
