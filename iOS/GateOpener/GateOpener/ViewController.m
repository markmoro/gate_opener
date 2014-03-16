//
//  ViewController.m
//  GateOpener
//
//

#import "ViewController.h"
#include <CommonCrypto/CommonHMAC.h>


#define ENDPOINT_MP @"http://localhost:8080/"
#define TOKEN_MP @"token"
#define OPEN_MP @"open"

#define SECRET_KEY @"test_key"

@interface ViewController ()

@end

@implementation ViewController


-(NSString*)endpoint {
  return ENDPOINT_MP;
}

-(NSURL*)tokenRequest {
    return [NSURL URLWithString:[[self endpoint] stringByAppendingString:TOKEN_MP]];
}

-(NSURL*)openRequest {
    return [NSURL URLWithString:[[self endpoint] stringByAppendingString:OPEN_MP]];

}

-(NSString*)code {
    return SECRET_KEY;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(IBAction)open:(id)sender {
    NSMutableURLRequest * urlRequest = [NSMutableURLRequest requestWithURL:[self tokenRequest]];
    
    [urlRequest setHTTPMethod:@"GET"];

    NSURLResponse * response = nil;
    NSError * error = nil;
    NSData * data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
    NSString * token = [[NSString alloc]initWithData:data encoding:NSASCIIStringEncoding];

    NSLog(@"Token=%@",token);

    
    NSString * digestSrc = [NSString stringWithFormat:@"%@open",token];
    const char *cKey  = [[self code] cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [digestSrc cStringUsingEncoding:NSASCIIStringEncoding];
    
    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
    
    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    
    
    NSMutableString* ho = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
        [ho appendFormat:@"%02x", cHMAC[i]];
    
    
    NSLog(@"Hash=%@",ho);

    
    urlRequest = [NSMutableURLRequest requestWithURL:[self openRequest]];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setHTTPBody:[[NSString stringWithFormat:@"d=%@",ho] dataUsingEncoding:NSASCIIStringEncoding]];
    data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
    token = [[NSString alloc]initWithData:data encoding:NSASCIIStringEncoding];

    
}

-(IBAction)openWhenNear:(id)sender {
    
    
}



@end
