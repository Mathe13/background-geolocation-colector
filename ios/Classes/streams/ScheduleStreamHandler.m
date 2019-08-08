
#import "ScheduleStreamHandler.h"

static NSString *const EVENT_NAME    = @"schedule";

@implementation ScheduleStreamHandler

- (NSString*) event {
    return EVENT_NAME;
}

- (FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)events {
    
    self.callback = ^void(TSScheduleEvent *event) {
        events(event.state);
    };
    [[TSLocationManager sharedInstance] onSchedule:self.callback];
    
    return nil;
}

@end


