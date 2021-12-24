//
//  PerfCatIOSDataReader.h
//  PerfCat_MacOS
//
//  Created by lucas on 2021/12/20.
//

#import "PerfCatDataReader.h"

NS_ASSUME_NONNULL_BEGIN


#ifndef PT_FINAL
    #define PT_FINAL __attribute__((objc_subclassing_restricted))
#endif


#ifndef PT_PRECISE_LIFETIME
  #define PT_PRECISE_LIFETIME __attribute__((objc_precise_lifetime))
#endif


#ifndef PT_PRECISE_LIFETIME_UNUSED
    #define PT_PRECISE_LIFETIME_UNUSED __attribute__((objc_precise_lifetime, unused))
#endif


typedef NS_ENUM(NSUInteger, PerfCatIOSDataFormat) {
    PerfCatIOSDataFormatBinary = 0,
    PerfCatIOSDataFormatPlist
};



@interface PerfCatIOSDataReader : PerfCatDataReader


- (void)sendPacket:(NSDictionary*)packet tag:(uint32_t)tag callback:(void(^)(NSError * _Nullable error))callback;

- (void)scheduleReadPacketWithBroadcastHandler:(void(^)(NSDictionary *packet))broadcastHandler;


@end

NS_ASSUME_NONNULL_END

