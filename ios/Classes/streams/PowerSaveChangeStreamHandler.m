
#import "PowerSaveChangeStreamHandler.h"

static NSString *const EVENT_NAME    = @"powersavechange";

@implementation PowerSaveChangeStreamHandler

- (NSString*) event {
    return EVENT_NAME;
}

- (FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)events {
    
    self.callback = ^void(TSPowerSaveChangeEvent *event) {
        events(@(event.isPowerSaveMode));
    };
    [[TSLocationManager sharedInstance] onPowerSaveChange: self.callback];
    
    return nil;
}

@end


