#import "MotionChangeStreamHandler.h"

static NSString *const EVENT_NAME       = @"motionchange";

@implementation MotionChangeStreamHandler

- (NSString*) event {
    return EVENT_NAME;
}

- (FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)events {
    
    self.callback = ^void(TSLocation *tsLocation) {
        events([tsLocation toDictionary]);
    };
    [[TSLocationManager sharedInstance] onMotionChange: self.callback];
    return nil;
}

@end

