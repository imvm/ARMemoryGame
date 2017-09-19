#import "SerialOperationQueue.h"

@implementation SerialOperationQueue

- (instancetype)init {
    self = [super init];

    if (self) {
        self.maxConcurrentOperationCount = 1;
    }

    return self;
}

- (void)addOperation:(NSOperation *)op {
    NSOperation *lastOperation = self.operations.lastObject;

    if (lastOperation) {
        [op addDependency:lastOperation];
    }

    [super addOperation:op];
}

@end