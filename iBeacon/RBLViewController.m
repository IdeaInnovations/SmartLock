//
//  RBLViewController.m
//  iBeacon
//
//  Copyright (c) 2013 RedBearLab. All rights reserved.
//

#import "RBLViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

#import "RBLService.h"

@interface RBLViewController () <CBCentralManagerDelegate, CBPeripheralDelegate>
{
    NSString *rblUUID;
    NSString *deviceService;
    UInt16 deviceMajor;
    UInt16 deviceMinor;
    UInt8 devicePower;
    
    int characteristicCount;

    CBCharacteristic *serviceCharacteristic;
    CBCharacteristic *majorCharacteristic;
    CBCharacteristic *minorCharacteristic;
    CBCharacteristic *powerCharacteristic;
}

@property (strong, nonatomic) CBCentralManager      *centralManager;
@property (strong, nonatomic) CBPeripheral          *discoveredPeripheral;

@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
- (IBAction)scanClick:(id)sender;
@property (weak, nonatomic) IBOutlet UIView *infoView;
@property (weak, nonatomic) IBOutlet UILabel *deviceLabel;
@property (weak, nonatomic) IBOutlet UILabel *serviceLabel;
@property (weak, nonatomic) IBOutlet UILabel *majorLabel;
@property (weak, nonatomic) IBOutlet UILabel *minorLabel;
@property (weak, nonatomic) IBOutlet UILabel *powerLabel;

- (IBAction)defaultClick:(id)sender;
- (IBAction)updateClick:(id)sender;

@property (weak, nonatomic) IBOutlet UITextField *serviceText;
@property (weak, nonatomic) IBOutlet UITextField *majorText;
@property (weak, nonatomic) IBOutlet UITextField *minorText;
@property (weak, nonatomic) IBOutlet UITextField *powerText;

@end

@implementation RBLViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // Don't keep it going while we're not showing.
    [self.centralManager stopScan];
    NSLog(@"Scanning stopped");
    
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Central Methods

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state != CBCentralManagerStatePoweredOn) {
        return;
    }
    
    // The state must be CBCentralManagerStatePoweredOn...
    
    // ... so start scanning
    [self scan];
    
}

- (void)scan
{

    self.infoView.hidden = true;
    
    CBUUID *BLELockout = [CBUUID UUIDWithString:RBL_SERVICE_UUID];
    
    // Create a dictionary for passing down to the scan with service method
    NSDictionary *scanOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
    
    [self.centralManager scanForPeripheralsWithServices:[NSArray arrayWithObject:BLELockout] options:scanOptions];
    
    NSLog(@"Scanning started");
}


- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    
    NSLog(@"Discovered %@ at %@", peripheral.name, RSSI);

    if (self.discoveredPeripheral != peripheral) {
        
        // Save a local copy of the peripheral, so CoreBluetooth doesn't get rid of it
        self.discoveredPeripheral = peripheral;
        
        // And connect
        NSLog(@"Connecting to peripheral %@", peripheral);
        [self.centralManager connectPeripheral:peripheral options:nil];
    }

    
}


- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Failed to connect to %@. (%@)", peripheral, [error localizedDescription]);
    [self cleanup];
}


- (void)cleanup
{
    // Don't do anything if we're not connected
    if (!self.discoveredPeripheral.isConnected) {
        return;
    }
    
    // If we've got this far, we're connected, but we're not subscribed, so we just disconnect
    [self.centralManager cancelPeripheralConnection:self.discoveredPeripheral];
}


- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Peripheral Connected");
    
    // Stop scanning
    [self.centralManager stopScan];
    NSLog(@"Scanning stopped");
    
    // Make sure we get the discovery callbacks
    peripheral.delegate = self;
    
    [peripheral discoverServices:nil];
}


- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Peripheral Disconnected");
    self.discoveredPeripheral = nil;
    
    // We're disconnected, so start scanning again
    [self scan];
}



- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSLog(@"I Entered didDiscoverServices");
    if (error) {
        NSLog(@"Error discovering services: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }

    NSArray *variable = peripheral.services;
    
    for (CBService *service in peripheral.services) {
        
        
        if ([service.UUID isEqual:[CBUUID UUIDWithString:RBL_SERVICE_UUID]]) {
            characteristicCount = 0;
            [peripheral discoverCharacteristics:nil forService:service];
            
            
            NSLog(@"I have determined that the SERVICE UUID is: %@", service.UUID);
                
            
            //serviceCharacteristic = service.UUID;
            
            
            //NSString *temp = [self getUUIDString:(__bridge CFUUIDRef)(service.UUID)];
            //[self getHexString:serviceCharacteristic.value];
            
            
            NSString *temp = [self convertCBUUIDToString:service.UUID];
            
            /*
            NSRange r1 = NSMakeRange(8, 4);
            NSRange r2 = NSMakeRange(12, 4);
            NSRange r3 = NSMakeRange(16, 4);
            
            deviceService = [temp substringToIndex:8];
            deviceService = [deviceService stringByAppendingString:@"-"];
            deviceService = [deviceService stringByAppendingString:[temp substringWithRange:r1]];
            deviceService = [deviceService stringByAppendingString:@"-"];
            deviceService = [deviceService stringByAppendingString:[temp substringWithRange:r2]];
            deviceService = [deviceService stringByAppendingString:@"-"];
            deviceService = [deviceService stringByAppendingString:[temp substringWithRange:r3]];
            deviceService = [deviceService stringByAppendingString:@"-"];
            deviceService = [deviceService stringByAppendingString:[temp substringFromIndex:20]];
            deviceService = [deviceService uppercaseString];
            */
            deviceService = temp;
            
            [self.serviceLabel setText:[NSString stringWithFormat:@"%@", deviceService]];
            [self.serviceText setText:deviceService];
            
            //characteristicCount++;
            
            
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    // Deal with errors (if any)
    NSLog(@"I Entered didDiscoverCharacteristics");
    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }
    
    rblUUID = [ self getUUIDString:peripheral.UUID];
    
    [self.deviceLabel setText:rblUUID];

    for (CBCharacteristic *characteristic in service.characteristics) {
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:RBL_CHARACTERISTIC_MAJOR_UUID]] ||
            [characteristic.UUID isEqual:[CBUUID UUIDWithString:RBL_CHARACTERISTIC_MINOR_UUID]]
            )
        {
            //not need anymore as the set notify should fire to the callback didUpdateNotificationStateForCharacteristic which has the readvalue
            [peripheral readValueForCharacteristic:characteristic];
            
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            
        }
        

        
        
    }
    
}

//added

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"Error changing notification state: %@", error.localizedDescription);
    }
    
    // Exits if it's not the transfer characteristic
    if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:RBL_CHARACTERISTIC_MAJOR_UUID]] ||
             [characteristic.UUID isEqual:[CBUUID UUIDWithString:RBL_CHARACTERISTIC_MINOR_UUID]]
             ) {
        return;
    }
    
    // Notification has started
    if (characteristic.isNotifying) {
        NSLog(@"Notification began on %@", characteristic);
        [peripheral readValueForCharacteristic:characteristic];
    } else { // Notification has stopped
        // so disconnect from the peripheral
        NSLog(@"Notification stopped on %@.  Disconnecting", characteristic);
           }
}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"I Entered didUpdateForCharacteristics");
    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        return;
    }
    //not needed in our case since we do not need the iBeacon characteristic
    
    /*if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:RBL_SERVICE_UUID]]) {
        
        serviceCharacteristic = characteristic;
   
        
        NSString *temp = [self getHexString:characteristic.value];
        
        NSLog(@"I have determined that the SERVICE UUID is: %@", temp);
        
    
        NSRange r1 = NSMakeRange(8, 4);
        NSRange r2 = NSMakeRange(12, 4);
        NSRange r3 = NSMakeRange(16, 4);
        
        deviceService = [temp substringToIndex:8];
        deviceService = [deviceService stringByAppendingString:@"-"];
        deviceService = [deviceService stringByAppendingString:[temp substringWithRange:r1]];
        deviceService = [deviceService stringByAppendingString:@"-"];
        deviceService = [deviceService stringByAppendingString:[temp substringWithRange:r2]];
        deviceService = [deviceService stringByAppendingString:@"-"];
        deviceService = [deviceService stringByAppendingString:[temp substringWithRange:r3]];
        deviceService = [deviceService stringByAppendingString:@"-"];
        deviceService = [deviceService stringByAppendingString:[temp substringFromIndex:20]];
        deviceService = [deviceService uppercaseString];
        
        [self.serviceLabel setText:[NSString stringWithFormat:@"%@", deviceService]];
        [self.serviceText setText:deviceService];
        
        characteristicCount++;
    }

     */
    else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:RBL_CHARACTERISTIC_MAJOR_UUID]]) {
        
        NSLog(@"I Entered MAJOR");

        majorCharacteristic = characteristic;
               
        uint8_t bytes = [characteristic.value bytes];
       
        uint32_t majorBytes = CFSwapInt16LittleToHost(*(const uint32_t *)[characteristic.value bytes]);
        
        [self.majorLabel setText:[NSString stringWithFormat:@"Major: %d", majorBytes]];
        [self.majorText setText:[NSString stringWithFormat:@"%d", majorBytes]];
        
        NSLog([NSString stringWithFormat:@"%d", majorBytes]);
        
        characteristicCount++;
    }
    else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:RBL_CHARACTERISTIC_MINOR_UUID]]) {
        NSLog(@"I Entered MINOR");
        
        minorCharacteristic = characteristic;

        
        uint8_t bytes = [characteristic.value bytes];
        
        uint32_t minorBytes = CFSwapInt16LittleToHost(*(const uint32_t *)[characteristic.value bytes]);
        
        [self.minorLabel setText:[NSString stringWithFormat:@"Major: %d", minorBytes]];
        [self.minorText setText:[NSString stringWithFormat:@"%d", minorBytes]];
        
        NSLog([NSString stringWithFormat:@"%d", minorBytes]);

        
        [self.minorLabel setText:[NSString stringWithFormat:@"Minor: %d", minorBytes]];
        [self.minorText setText:[NSString stringWithFormat:@"%d", minorBytes]];
        
        NSLog([NSString stringWithFormat:@"Minor: %d", deviceMinor]);
        
        characteristicCount++;
    }
    /* do not need the power characterist until we do the proximity component
    else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:RBL_CHARACTERISTIC_POWER_UUID]]) {

        powerCharacteristic = characteristic;
        
        unsigned char data[1];
        [characteristic.value getBytes:data length:1];
        
        devicePower = data[0];
        
        [self.powerLabel setText:[NSString stringWithFormat:@"Power: %d", devicePower - 256]];
        [self.powerText setText:[NSString stringWithFormat:@"%d", devicePower - 256]];
        
        characteristicCount++;
    }
     */
     
    if (characteristicCount == 2)
    {
        self.infoView.hidden = false;
    }
    
    
}


-(NSString*)getUUIDString:(CFUUIDRef)ref {
    NSString *str = [NSString stringWithFormat:@"%@",ref];
    return [[NSString stringWithFormat:@"%@",str] substringWithRange:NSMakeRange(str.length - 36, 36)];
}


-(NSString*)convertCBUUIDToString:(CBUUID*)uuid {
    NSData *data = uuid.data;
    NSUInteger bytesToConvert = [data length];
    const unsigned char *uuidBytes = [data bytes];
    NSMutableString *outputString = [NSMutableString stringWithCapacity:16];
    
    for (NSUInteger currentByteIndex = 0; currentByteIndex < bytesToConvert; currentByteIndex++)
    {
        switch (currentByteIndex)
        {
            case 3:
            case 5:
            case 7:
            case 9:[outputString appendFormat:@"%02x-", uuidBytes[currentByteIndex]]; break;
            default:[outputString appendFormat:@"%02x", uuidBytes[currentByteIndex]];
        }
        
    }
    
    NSString *result = [outputString uppercaseString];
    
    return result;
}

-(NSString*)getHexString:(NSData*)data {
    NSUInteger dataLength = [data length];
    NSMutableString *string = [NSMutableString stringWithCapacity:dataLength*2];
    const unsigned char *dataBytes = [data bytes];
    for (NSInteger idx = 0; idx < dataLength; ++idx) {
        [string appendFormat:@"%02x", dataBytes[idx]];
    }
    return string;
}

- (IBAction)scanClick:(id)sender {
    [self cleanup];
    [self scan];
}

- (IBAction)defaultClick:(id)sender {
    [self.view endEditing:YES];
    [self.serviceText setText:SAMPLE_UUID];
    [self.majorText setText:[NSString stringWithFormat:@"%d", 0]];
    [self.minorText setText:[NSString stringWithFormat:@"%d", 0]];
    [self.powerText setText:[NSString stringWithFormat:@"%d", -59]];
        
}

- (IBAction)updateClick:(id)sender {
    
    [self.view endEditing:YES];
    
    CBUUID *uuid;
    
    @try {
        uuid = [CBUUID UUIDWithString:[self.serviceText text]];
        [self.serviceText setText:[self convertCBUUIDToString:uuid]];
        
    }
    @catch (NSException *exception) {
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:nil message:[NSString stringWithFormat:@"UUID string not valid!"] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        return;
    }
    
    int major = [[self.majorText text] intValue];
    if ((major < 0) || (major > 65535))
    {
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:nil message:[NSString stringWithFormat:@"Major number not valid!"] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        return;
    }
    [self.majorText setText:[NSString stringWithFormat:@"%d", major]];

    
    int minor = [[self.minorText text] intValue];
    if ((minor < 0) || (minor > 65535))
    {
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:nil message:[NSString stringWithFormat:@"Minor number not valid!"] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        return;
    }
    [self.minorText setText:[NSString stringWithFormat:@"%d", minor]];
    
    /*
    int power = [[self.powerText text] intValue];
    if ((power > -1) || (power < -256))
    {
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:nil message:[NSString stringWithFormat:@"Power not valid!"] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        return;
    }
    [self.powerText setText:[NSString stringWithFormat:@"%d", power]];
    */
    NSData *data = uuid.data;
    [self.discoveredPeripheral writeValue:data forCharacteristic:serviceCharacteristic type:CBCharacteristicWriteWithResponse];
    
    uint8_t buf[] = {0x00 , 0x00};
    buf[1] =  (unsigned int) (major & 0xff);
    buf[0] =  (unsigned int) (major>>8 & 0xff);
    data = [[NSData alloc] initWithBytes:buf length:2];
    [self.discoveredPeripheral writeValue:data forCharacteristic:majorCharacteristic type:CBCharacteristicWriteWithResponse];
    
    
    buf[1] =  (unsigned int) (minor & 0xff);
    buf[0] =  (unsigned int) (minor>>8 & 0xff);
    data = [[NSData alloc] initWithBytes:buf length:2];
    [self.discoveredPeripheral writeValue:data forCharacteristic:minorCharacteristic type:CBCharacteristicWriteWithResponse];
    
    //power = power + 256;
    //buf[0] = power;
    data = [[NSData alloc] initWithBytes:buf length:1];
    [self.discoveredPeripheral writeValue:data forCharacteristic:powerCharacteristic type:CBCharacteristicWriteWithResponse];
    
    
    UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:nil message:[NSString stringWithFormat:@"Update successful, please restart BLE Mini!"] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];

    
}
@end
