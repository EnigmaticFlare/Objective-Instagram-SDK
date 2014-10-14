//
//  EFLInstagramAuthenticationViewController.m
//  Camerarrific
//
//  Created by Adam Roberts on 30/01/2014.
//  Copyright (c) 2014 Enigmatic Flare Ltd. All rights reserved.
//

#import "InstagramAuthenticationViewController.h"
#import "InstagramManager.h"

@interface InstagramAuthenticationViewController ()
@property (nonatomic, weak) IBOutlet UIWebView *webView;
@property (nonatomic, strong) InstagramManager *instagramManager;
@property (nonatomic, strong) NSURL *instagramAuthURL;
@property (nonatomic, strong) NSURLRequest *authRequest;
@property (nonatomic, strong) id <UIApplicationDelegate> appDelegate;
@end

@implementation InstagramAuthenticationViewController


-(instancetype)initWithCoder:(NSCoder *)aDecoder{

    self = [super initWithCoder:aDecoder];
    if (self) {
        self.instagramManager = [InstagramManager sharedManager];
        self.instagramAuthURL = [self.instagramManager requestAuthenticateURLForUsingClientId:nil requestCommentsEndpointPermission:TRUE requestRelationshipsEndpointPermission:TRUE RequestLikesEndpointPermission:TRUE];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.authRequest = [NSURLRequest requestWithURL:self.instagramAuthURL];
    
    [self.webView loadRequest:self.authRequest];
    [self.webView setScalesPageToFit:TRUE];
    self.webView.scrollView.bounces = FALSE;
    
    self.appDelegate = [[UIApplication sharedApplication] delegate];
    
 
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
//    
//    
//    
//    NSString *oauthURL = [error.userInfo valueForKey:@"NSErrorFailingURLStringKey"];
//
//    NSLog(@"NSErrorFailingURLStringKey:%@",oauthURL);
//   
//}


-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    
    if ([request.URL.scheme isEqualToString:@"ig"]){
        [self.instagramManager processReturnedAuthenticationURL:request.URL completion:^(BOOL didAuthenticate, NSString *dialogMessage, NSString *token) {
            
            if (didAuthenticate){
                
                if ([self.appDelegate.window.rootViewController isKindOfClass:[UINavigationController class]]){
                    [self.navigationController popViewControllerAnimated:TRUE];
                } else {
                    [self dismissViewControllerAnimated:TRUE completion:^{
                        
                    }];
                }
                
                
            NSLog(@"IG auth message:%@",dialogMessage);
            }
        }];
        
        return FALSE;
    } else if ([request.URL.description isEqualToString:@"http://instagram.com/"]){
        [self.webView loadRequest:self.authRequest];
        return FALSE;
    }
    
    NSLog(@"Should load URL:%@",request.URL.description);
    NSLog(@"Base URL:%@",request.URL.baseURL);
    NSLog(@"Scheme URL:%@",request.URL.scheme);
    NSLog(@"Lastpath URL:%@",request.URL.lastPathComponent);
    NSLog(@"Fragment URL:%@",request.URL.fragment);
    
    
    
    return TRUE;
}

-(void)webViewDidFinishLoad:(UIWebView *)webView{
    NSLog(@"Waiting for Authentication from user:");
   
}

-(void)webViewDidStartLoad:(UIWebView *)webView{
    NSLog(@"Request Authentication:");
}

-(BOOL)prefersStatusBarHidden{
    return TRUE;
}


@end

