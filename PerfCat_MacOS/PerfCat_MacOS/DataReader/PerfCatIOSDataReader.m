//
//  PerfCatIOSDataReader.m
//  PerfCat_MacOS
//
//  Created by lucas on 2021/12/20.
//

#import "PerfCatIOSDataReader.h"

#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <sys/un.h>

typedef uint32_t USBMuxPacketType;
enum {
  USBMuxPacketTypeResult = 1,
    USBMuxPacketTypeConnect = 2,
    USBMuxPacketTypeListen = 3,
  USBMuxPacketTypeDeviceAdd = 4,
  USBMuxPacketTypeDeviceRemove = 5,
  // ? = 6,
  // ? = 7,
  USBMuxPacketTypePlistPayload = 8,
};

typedef uint32_t USBMuxPacketProtocol;
enum {
  USBMuxPacketProtocolBinary = 0,
  USBMuxPacketProtocolPlist = 1,
};

typedef uint32_t USBMuxReplyCode;
enum {
  USBMuxReplyCodeOK = 0,
  USBMuxReplyCodeBadCommand = 1,
  USBMuxReplyCodeBadDevice = 2,
  USBMuxReplyCodeConnectionRefused = 3,
  // ? = 4,
  // ? = 5,
  USBMuxReplyCodeBadVersion = 6,
};


typedef struct usbmux_packet {
  uint32_t size;
  USBMuxPacketProtocol protocol;
  USBMuxPacketType type;
  uint32_t tag;
  char data[0];
} __attribute__((__packed__)) usbmux_packet_t;

static const uint32_t kUsbmuxPacketMaxPayloadSize = UINT32_MAX - (uint32_t)sizeof(usbmux_packet_t);


static uint32_t usbmux_packet_payload_size(usbmux_packet_t *upacket) {
  return upacket->size - sizeof(usbmux_packet_t);
}


static void *usbmux_packet_payload(usbmux_packet_t *upacket) {
  return (void*)upacket->data;
}


static void usbmux_packet_set_payload(usbmux_packet_t *upacket,
                                      const void *payload,
                                      uint32_t payloadLength)
{
  memcpy(usbmux_packet_payload(upacket), payload, payloadLength);
}


static usbmux_packet_t *usbmux_packet_alloc(uint32_t payloadSize) {
  assert(payloadSize <= kUsbmuxPacketMaxPayloadSize);
  uint32_t upacketSize = sizeof(usbmux_packet_t) + payloadSize;
  usbmux_packet_t *upacket = CFAllocatorAllocate(kCFAllocatorDefault, upacketSize, 0);
  memset(upacket, 0, sizeof(usbmux_packet_t));
  upacket->size = upacketSize;
  return upacket;
}


static usbmux_packet_t *usbmux_packet_create(USBMuxPacketProtocol protocol,
                                             USBMuxPacketType type,
                                             uint32_t tag,
                                             const void *payload,
                                             uint32_t payloadSize)
{
  usbmux_packet_t *upacket = usbmux_packet_alloc(payloadSize);
  if (!upacket) {
    return NULL;
  }
  
  upacket->protocol = protocol;
  upacket->type = type;
  upacket->tag = tag;
  
  if (payload && payloadSize) {
    usbmux_packet_set_payload(upacket, payload, (uint32_t)payloadSize);
  }
  
  return upacket;
}


static void usbmux_packet_free(usbmux_packet_t *upacket) {
  CFAllocatorDeallocate(kCFAllocatorDefault, upacket);
}



NSString * const PTUSBHubErrorDomain = @"PTUSBHubError";


@interface PerfCatIOSDataReader ()


@end

@implementation PerfCatIOSDataReader {
    dispatch_io_t channel_;
    dispatch_queue_t queue_;
    BOOL isReadingPackets_;
}


- (instancetype)init {
    if (self = [super init]) {
        
//        channel_ = [PerfCatIOSDataReader __createChannelToConnectUsbmuxd];
        queue_ = dispatch_queue_create("queue_identifier", 0);
        
    }
    return self;
}

+ (dispatch_fd_t)__connectUsbmuxd {
    // Create Unix domain socket
    int fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (fd < 0) {
        NSLog(@"create socket fail");
        return fd;
    }
    // prevent SIGPIPE
    int on = 1;
    setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &on, sizeof(on));

    // Connect socket
    struct sockaddr_un addr;
    addr.sun_family = AF_UNIX;
    strcpy(addr.sun_path, "/var/run/usbmuxd");
    socklen_t socklen = sizeof(addr);
    
    int connect_result = connect(fd, (struct sockaddr *)&addr, socklen);
    if (connect_result < 0) {
        NSLog(@"connect fail");
        return -1;
    }
    
    return fd;
}

+ (dispatch_io_t)__createChannelToConnectUsbmuxd {
    dispatch_fd_t fd = [self __connectUsbmuxd];
    dispatch_queue_t usbmuxd_io_queue = dispatch_queue_create("usbmuxd_io_queue", NULL);
    dispatch_io_t channel = dispatch_io_create(DISPATCH_IO_STREAM, fd, usbmuxd_io_queue, ^(int error) {
        close(fd);
        NSLog(@"create channel fail");
    });
    return channel;
}

//+ (void)sendPacket:(NSDictionary *)packetDict tag:(int)tag byChannel:(dispatch_io_t)channel {
//    NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:packetDict format:NSPropertyListXMLFormat_v1_0 options:0 error:NULL];
//
//    int protocol = PerfCatIOSDataFormatPlist;
////    int type = USBMuxPacketTypePlistPayload;
////
////    usbmux_packet_t *upacket = usbmux_packet_create(
////                                                    protocol,
////                                                    type,
////                                                    tag,
////                                                    plistData ? plistData.bytes : nil,
////                                                    (uint32_t)(plistData.length)
////                                                    );
////
//    dispatch_data_t data = dispatch_data_create((const void*)upacket, upacket->size, usbmuxd_io_queue, ^{
//        usbmux_packet_free(upacket);
//    });
//
//    dispatch_data_t data;
//
//    dispatch_queue_t usbmuxd_io_queue = dispatch_queue_create("usbmuxd_io_queue", NULL);
//    dispatch_io_write(channel, 0, data, usbmuxd_io_queue, ^(bool done, dispatch_data_t _Nullable data, int error) {
//        NSLog(@"dispatch_io_write: done=%d data=%p error=%d", done, data, error);
//    });
//}


#pragma mark - read

- (void)scheduleReadPacketWithBroadcastHandler:(void(^)(NSDictionary *packet))broadcastHandler {
  assert(isReadingPackets_ == NO);
  
  [self scheduleReadPacketWithCallback:^(NSError *error, NSDictionary *packet, uint32_t packetTag) {
      
      NSLog(@"======接收到数据了");
      NSLog(@"%@", packet);
      
    // Interpret the package we just received
    if (packetTag == 0) {
      // Broadcast message
      if (broadcastHandler) broadcastHandler(packet);
        
    } else {
    }
      
      [self scheduleReadPacketWithBroadcastHandler:broadcastHandler];
      
      
      
  }];
}


- (void)scheduleReadPacketWithCallback:(void(^)(NSError*, NSDictionary*, uint32_t))callback {
  static usbmux_packet_t ref_upacket;
  isReadingPackets_ = YES;
    


  // Read the first `sizeof(ref_upacket.size)` bytes off the channel_
  dispatch_io_read(channel_, 0, sizeof(ref_upacket.size), queue_, ^(bool done, dispatch_data_t data, int error) {
    if (!done)
      return;
    
    if (error) {
            self->isReadingPackets_ = NO;
      callback([[NSError alloc] initWithDomain:NSPOSIXErrorDomain code:error userInfo:nil], nil, 0);
      return;
    }
    
    // Read size of incoming usbmux_packet_t
    uint32_t upacket_len = 0;
    char *buffer = NULL;
    size_t buffer_size = 0;
    PT_PRECISE_LIFETIME_UNUSED dispatch_data_t map_data = dispatch_data_create_map(data, (const void **)&buffer, &buffer_size); // objc_precise_lifetime guarantees 'map_data' isn't released before memcpy has a chance to do its thing
    assert(buffer_size == sizeof(ref_upacket.size));
    assert(sizeof(upacket_len) == sizeof(ref_upacket.size));
    memcpy((void *)&(upacket_len), (const void *)buffer, buffer_size);

    // Allocate a new usbmux_packet_t for the expected size
    uint32_t payloadLength = upacket_len - (uint32_t)sizeof(usbmux_packet_t);
    usbmux_packet_t *upacket = usbmux_packet_alloc(payloadLength);
    
    // Read rest of the incoming usbmux_packet_t
    off_t offset = sizeof(ref_upacket.size);
        dispatch_io_read(self->channel_, offset, upacket->size - offset, self->queue_, ^(bool done, dispatch_data_t data, int error) {
      //NSLog(@"dispatch_io_read X,Y: done=%d data=%p error=%d", done, data, error);
      
      if (!done) {
        return;
      }
      
            self->isReadingPackets_ = NO;
      
      if (error) {
        callback([[NSError alloc] initWithDomain:NSPOSIXErrorDomain code:error userInfo:nil], nil, 0);
        usbmux_packet_free(upacket);
        return;
      }

      if (upacket_len > kUsbmuxPacketMaxPayloadSize) {
        callback(
          [[NSError alloc] initWithDomain:PTUSBHubErrorDomain code:1 userInfo:@{
            NSLocalizedDescriptionKey:@"Received a packet that is too large"}],
          nil,
          0
        );
        usbmux_packet_free(upacket);
        return;
      }
      
      // Copy read bytes onto our usbmux_packet_t
      char *buffer = NULL;
      size_t buffer_size = 0;
      PT_PRECISE_LIFETIME_UNUSED dispatch_data_t map_data = dispatch_data_create_map(data, (const void **)&buffer, &buffer_size);
      assert(buffer_size == upacket->size - offset);
      memcpy(((void *)(upacket))+offset, (const void *)buffer, buffer_size);

      // We only support plist protocol
      if (upacket->protocol != USBMuxPacketProtocolPlist) {
        callback([[NSError alloc] initWithDomain:PTUSBHubErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObject:@"Unexpected package protocol" forKey:NSLocalizedDescriptionKey]], nil, upacket->tag);
        usbmux_packet_free(upacket);
        return;
      }
      
      // Only one type of packet in the plist protocol
      if (upacket->type != USBMuxPacketTypePlistPayload) {
        callback([[NSError alloc] initWithDomain:PTUSBHubErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObject:@"Unexpected package type" forKey:NSLocalizedDescriptionKey]], nil, upacket->tag);
        usbmux_packet_free(upacket);
        return;
      }
      
      // Try to decode any payload as plist
      NSError *err = nil;
      NSDictionary *dict = nil;
      if (usbmux_packet_payload_size(upacket)) {
          NSData *data = [NSData dataWithBytesNoCopy:usbmux_packet_payload(upacket) length:usbmux_packet_payload_size(upacket) freeWhenDone:NO];
        dict = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:NULL error:&err];
          
//          NSString* aStr = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
          
      }
//            NSString* aStr = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
      // Invoke callback
      callback(err, dict, upacket->tag);
      usbmux_packet_free(upacket);
    });
  });
}



#pragma mark - send


- (void)sendPacket:(NSDictionary*)packet tag:(uint32_t)tag callback:(void(^)(NSError * _Nullable error))callback; {
    NSError *error = nil;
    // NSPropertyListBinaryFormat_v1_0
    NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:packet format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
    if (!plistData) {
        callback(error);
    } else {
        [self sendPacketOfType:USBMuxPacketTypePlistPayload overProtocol:USBMuxPacketProtocolPlist tag:tag payload:plistData callback:callback];
    }
}


- (void)sendPacketOfType:(USBMuxPacketType)type
            overProtocol:(USBMuxPacketProtocol)protocol
                     tag:(uint32_t)tag
                 payload:(NSData*)payload
                callback:(void(^)(NSError*))callback
{
  assert(payload.length <= kUsbmuxPacketMaxPayloadSize);
  usbmux_packet_t *upacket = usbmux_packet_create(
    protocol,
    type,
    tag,
    payload ? payload.bytes : nil,
    (uint32_t)(payload ? payload.length : 0)
  );
  dispatch_data_t data = dispatch_data_create((const void*)upacket, upacket->size, queue_, ^{
    // Free packet when data is freed
    usbmux_packet_free(upacket);
  });
  [self sendDispatchData:data callback:callback];
}

- (void)sendDispatchData:(dispatch_data_t)data callback:(void(^)(NSError*))callback {
  off_t offset = 0;
    
    channel_ = [PerfCatIOSDataReader __createChannelToConnectUsbmuxd];
    
  dispatch_io_write(channel_, offset, data, queue_, ^(bool done, dispatch_data_t data, int _errno) {
    //NSLog(@"dispatch_io_write: done=%d data=%p error=%d", done, data, error);
    if (!done)
      return;
    if (callback) {
      NSError *err = nil;
      if (_errno) err = [[NSError alloc] initWithDomain:NSPOSIXErrorDomain code:_errno userInfo:nil];
      callback(err);
    }
  });
}


#pragma mark - read

@end
