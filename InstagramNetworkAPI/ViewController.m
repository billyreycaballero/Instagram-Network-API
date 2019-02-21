//
//  ViewController.m
//  InstagramNetworkAPI
//
//  Created by Billy Rey Caballero on 26/3/17.
//  Copyright © 2017 alcoderithm. All rights reserved.
//

#import "ViewController.h"
#import "NXOAuth2.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIButton *logInButton;
@property (weak, nonatomic) IBOutlet UIButton *logOutButton;
@property (weak, nonatomic) IBOutlet UIButton *fetchButton;
@property (weak, nonatomic) IBOutlet UIImageView *imageLaunch;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.logOutButton.enabled = false;
    self.fetchButton.enabled = false;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)logInToInstagram:(id)sender {
    [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:@"Instagram"];
    self.logInButton.enabled = false;
    self.logOutButton.enabled = true;
    self.fetchButton.enabled = true;
}

- (IBAction)logOutFromInstagram:(id)sender {
    NXOAuth2AccountStore *store = [NXOAuth2AccountStore sharedStore];
    NSArray *instagramAccounts = [store accountsWithAccountType:@"Instagram"];
    for(id account in instagramAccounts)
        [store removeAccount:account];
    self.logInButton.enabled = true;
    self.logOutButton.enabled = false;
    self.fetchButton.enabled = false;
}


- (IBAction)fetchFromInstagram:(id)sender {
    NSArray *instagramAccounts = [[NXOAuth2AccountStore sharedStore] accountsWithAccountType:@"Instagram"];
    if([instagramAccounts count] == 0) {
        NSLog(@"Warning: %ld Instagram accounts logged in", (long)(instagramAccounts));
        return;
    }
    NXOAuth2Account *account = instagramAccounts[0];
    NSString *token = account.accessToken.accessToken;
    NSString *urlStr = [@"https://api.instagram.com/v1/users/self/media/recent/?access_token=" stringByAppendingString:token];
    NSLog(@"%@", urlStr);
    NSURL *url = [NSURL URLWithString:urlStr];
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error){
        if(error){
            NSLog(@"Error: Coudn't finish request: %@", error);
            return;
        }
        NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
        if(httpResp.statusCode < 200 || httpResp.statusCode >= 300){
            NSLog(@"Error: Got status code %ld", (long)httpResp.statusCode);
            return;
        }
        
        NSError *parseErr;
        id pkg = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseErr];
        if(!pkg){
            NSLog(@"Error: Coudn't parse response: %@", parseErr);
            return;
        }
        
        NSString *imageURLStr = pkg[@"data"][0][@"images"][@"standard_resolution"][@"url"];
        NSURL *imageURL = [NSURL URLWithString:imageURLStr];
        [[session dataTaskWithURL:imageURL completionHandler:^(NSData * _Nullable data, NSURLResponse
* _Nullable response, NSError * _Nullable error){
            if(error){
                NSLog(@"Error: Coudn't finish request: %@", error);
                return;
            }
            NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
            if(httpResp.statusCode < 200 || httpResp.statusCode >= 300) {
                NSLog(@"Error: Got status code %ld", (long)httpResp.statusCode);
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                self.imageLaunch.image = [UIImage imageWithData:data];
            });
        }]resume];
        
    }]resume];
}


@end
