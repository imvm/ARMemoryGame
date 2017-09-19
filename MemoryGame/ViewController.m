#import "ViewController.h"
#import "SerialOperationQueue.h"

@interface ViewController () <ARSessionDelegate, ARSCNViewDelegate>

@property (nonatomic, strong) IBOutlet ARSCNView *sceneView;
@property (nonatomic, assign) BOOL processing;
@property (nonatomic, strong) SerialOperationQueue *backgroundQueue;
@property (nonatomic, strong) NSMutableArray<NSString *> *recognizedBarcodes;
@property (nonatomic, strong) VNDetectedObjectObservation *lastObservation;

@end

@implementation ViewController

- (BOOL)prefersStatusBarHidden {
    return TRUE;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    UIApplication.sharedApplication.idleTimerDisabled = TRUE;

    self.backgroundQueue = [SerialOperationQueue new];
    self.backgroundQueue.qualityOfService = NSQualityOfServiceUserInteractive;

    self.recognizedBarcodes = [NSMutableArray arrayWithCapacity:8];

    self.sceneView.delegate = self;
    self.sceneView.showsStatistics = TRUE;
    self.sceneView.automaticallyUpdatesLighting = TRUE;
    self.sceneView.scene = [SCNScene new];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.sceneView.session.delegate = self;
    [self.sceneView.session runWithConfiguration:[ARWorldTrackingConfiguration new]];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self.sceneView.session pause];
}

- (void)session:(ARSession *)session didUpdateFrame:(ARFrame *)frame {
    if (!self.processing) {
        self.processing = TRUE;

        VNDetectBarcodesRequest *barcodesRequest = [[VNDetectBarcodesRequest alloc] initWithCompletionHandler:^(VNRequest *request, NSError *error) {
            NSOperationQueue *mainQueue = NSOperationQueue.mainQueue;
            [mainQueue addOperation:[NSBlockOperation blockOperationWithBlock:^() {
                VNBarcodeObservation *barcodeObservation = request.results.firstObject;

                if (barcodeObservation) {
                    NSString *barcode = barcodeObservation.payloadStringValue;

                    if (![self.recognizedBarcodes containsObject:barcode]) {
                        [self.recognizedBarcodes addObject:barcode];

                        CGRect barcodeBox = barcodeObservation.boundingBox;
                        CGPoint barcodeCenter = CGPointMake(CGRectGetMidX(barcodeBox), CGRectGetMidY(barcodeBox));

                        NSArray<ARHitTestResult *> *hitTestResults = [frame hitTest:barcodeCenter types:ARHitTestResultTypeFeaturePoint];
                        ARHitTestResult *firstHitTestResult = hitTestResults.firstObject;

                        if (firstHitTestResult) {
                            ARAnchor *barcodeArchor = [[ARAnchor alloc] initWithTransform:firstHitTestResult.worldTransform];

                            [session addAnchor:barcodeArchor];
                        }
                    }
                }

                self.processing = FALSE;
            }]];
        }];
        barcodesRequest.symbologies = @[VNBarcodeSymbologyQR];

        [self.backgroundQueue addOperation:[NSBlockOperation blockOperationWithBlock:^() {
            VNImageRequestHandler *requestHandler = [[VNImageRequestHandler alloc] initWithCVPixelBuffer:frame.capturedImage options:@{}];
            [requestHandler performRequests:@[barcodesRequest] error:nil];
        }]];
    }
}

- (void)trackBarcadoWithObservation:(VNBarcodeObservation *)barcodeObservation {
    //VNTrackObjectRequest *trackRequest = [[VNTrackObjectRequest alloc] initWithDetectedObjectObservation:];

    //let newObservation = VNDetectedObjectObservation(boundingBox: convertedRect)
    //self.lastObservation = newObservation
}


- (nullable SCNNode *)renderer:(id <SCNSceneRenderer>)renderer nodeForAnchor:(ARAnchor *)anchor {
    NSLog(@"(nullable SCNNode *)renderer:(id <SCNSceneRenderer>)renderer nodeForAnchor:(ARAnchor *)anchor");

    SCNNode *node = [SCNNode nodeWithGeometry:[SCNSphere sphereWithRadius:0.005F]];
    node.transform = SCNMatrix4FromMat4(anchor.transform);

    return node;
}

- (void)renderer:(id <SCNSceneRenderer>)renderer didAddNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor {
    NSLog(@"(void)renderer:(id <SCNSceneRenderer>)renderer didAddNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor");
}

- (void)renderer:(id <SCNSceneRenderer>)renderer willUpdateNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor {
    NSLog(@"(void)renderer:(id <SCNSceneRenderer>)renderer willUpdateNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor");
}

- (void)renderer:(id <SCNSceneRenderer>)renderer didUpdateNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor {
    NSLog(@"(void)renderer:(id <SCNSceneRenderer>)renderer didUpdateNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor");
}

- (void)renderer:(id <SCNSceneRenderer>)renderer didRemoveNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor {
    NSLog(@"(void)renderer:(id <SCNSceneRenderer>)renderer didRemoveNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor");
}

- (void)session:(ARSession *)session didAddAnchors:(NSArray<ARAnchor *> *)anchors {
    NSLog(@"(void)session:(ARSession *)session didAddAnchors:(NSArray<ARAnchor *> *)anchors");
}

- (void)session:(ARSession *)session didUpdateAnchors:(NSArray<ARAnchor *> *)anchors {
    NSLog(@"(void)session:(ARSession *)session didUpdateAnchors:(NSArray<ARAnchor *> *)anchors");
}

- (void)session:(ARSession *)session didRemoveAnchors:(NSArray<ARAnchor *> *)anchors {
    NSLog(@"(void)session:(ARSession *)session didRemoveAnchors:(NSArray<ARAnchor *> *)anchors");
}

@end
