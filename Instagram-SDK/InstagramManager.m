//
//  InstagramManager.m
//  Instagram-SDK
//
//  Created by Adam Roberts on 05/01/2014.
//  Copyright (c) 2014 Enigmatic Flare Ltd. All rights reserved.
//

#import "InstagramManager.h"

static NSString * kInstagramBaseURI = @"https://api.instagram.com/v1";

static NSString * kInstagramEndpointUsers = @"users";
static NSString * kInstagramEndpointRelationships = @"relationships";
static NSString * kInstagramEndpointMedia = @"media";
static NSString * kInstagramEndpointComments = @"comments";
static NSString * kInstagramEndpointLikes = @"likes";
static NSString * kInstagramEndpointTags = @"tags";
static NSString * kInstagramEndpointLocations = @"locations";
static NSString * kInstagramEndpointGeographies = @"geographies";

static NSString * kInstagramMethodFollows = @"follows";
static NSString * kInstagramMethodFollowers = @"followed-by";

static NSString * kInstagramMethodPopular = @"popular";
static NSString * kInstagramMethodSearch = @"search";
static NSString * kInstagramMethodComments = @"comments";
static NSString * kInstagramMethodRecent = @"recent";
static NSString * kInstagramMethodSelfFeed = @"self/feed";
static NSString * kInstagramMethodSelfMediaLikes = @"self/media/liked";

NSString *const SLServiceTypeInstagram = @"Instagram";

static NSString *kHTTPMethodGet = @"GET";
static NSString *kHTTPMethodPost = @"POST";
static NSString *kHTTPMethodDelete = @"DEL";

@interface InstagramManager()

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) NSURL *instagramAuthURL;
@property (nonatomic, strong) NSURLRequest *authRequest;
@property (nonatomic, strong) id <UIApplicationDelegate> appDelegate;

@end

@implementation InstagramManager

+(instancetype)sharedManager{
    static dispatch_once_t pred;
    static InstagramManager *sharedManager = nil;
    
    dispatch_once(&pred, ^{
        sharedManager = [[InstagramManager alloc] init];
    });
    return sharedManager;
}

static NSString* kDialogBaseURL         = @"https://instagram.com/";

static NSString* kLogin                 = @"oauth/authorize";


#pragma mark authentication

-(void)authenticateUsingClientId:(NSString*)clientId requestCommentsEndpointPermission:(BOOL)requestCommentsPermission
requestRelationshipsEndpointPermission:(BOOL)requestRelationshipsPermission
  RequestLikesEndpointPermission:(BOOL)requestLikesPermission{
    
    if (self.oauthToken.length == 0){
        self.appDelegate = [[UIApplication sharedApplication] delegate];
        
        self.instagramAuthURL = [self requestAuthenticateURLForUsingClientId:clientId requestCommentsEndpointPermission:requestCommentsPermission requestRelationshipsEndpointPermission:requestRelationshipsPermission RequestLikesEndpointPermission:requestLikesPermission];
        
        self.authRequest = [NSURLRequest requestWithURL:self.instagramAuthURL];
        
        self.webView = [[UIWebView alloc] initWithFrame:[[self.appDelegate window] frame]];
        self.webView.delegate = self;
        
        [self.webView loadRequest:self.authRequest];
        [self.webView setScalesPageToFit:TRUE];
        self.webView.scrollView.bounces = FALSE;
    }
}

-(NSURL*)requestAuthenticateURLForUsingClientId:(NSString*)clientId requestCommentsEndpointPermission:(BOOL)requestCommentsPermission
requestRelationshipsEndpointPermission:(BOOL)requestRelationshipsPermission
  RequestLikesEndpointPermission:(BOOL)requestLikesPermission{
    
        NSMutableArray *permissions = @[@"basic"].mutableCopy;
        
        if (requestCommentsPermission)
            [permissions addObject:kInstagramEndpointComments];
        if (requestLikesPermission)
            [permissions addObject:kInstagramEndpointLikes];
        if (requestRelationshipsPermission)
            [permissions addObject:kInstagramEndpointRelationships];
        
        NSString *requestPermissions = [permissions componentsJoinedByString:@"+"];
        
        NSString *authURL = [NSString stringWithFormat:@"https://instagram.com/oauth/authorize?response_type=token&redirect_uri=ig://authorize&client_id=%@&scope=%@",clientId,requestPermissions];
        
    return [NSURL URLWithString:authURL];
}

- (void)processReturnedAuthenticationURL:(NSURL *)url completion:(InstagramAuthenticationCompletionBlock)authenticationHandler{
    
    // (BOOL didAuthenticate, NSString *dialogMessage, NSString *token);
    
 //match the structure used for Instagram authorization, abort.
    if (![[url absoluteString] hasPrefix:@"ig://authorize"]) {
        return authenticationHandler(FALSE,@"Invalid Response",nil);
    }
    
    NSString *query = [url fragment];
    if (!query) {
        query = [url query];
    }
    
    NSDictionary *params = [self parseURLParams:query];
    
    NSString *accessToken = [params valueForKey:@"access_token"];
    
    [self setOauthToken:accessToken];
    
    // If the URL doesn't contain the access token, an error has occurred.
    if (!accessToken) {
        NSString *errorReason = [params valueForKey:@"error_reason"];
        
        if ([errorReason isEqualToString:@"user_denied"]){
            [self informDelegateAuthenticationFailed];
            authenticationHandler(FALSE,@"Access Denied",nil);
        }
    } else {
        NSLog(@"IG Access Token:%@",accessToken);
        [self informDelegateAuthenticated];
        
        for (UIView *view in [self.appDelegate window].subviews) {
            if (view == self.webView){
                [view removeFromSuperview];
                self.webView = nil;
            }
        }
        
        [self setUserID:[[accessToken componentsSeparatedByString:@"."] objectAtIndex:0]];
       
        [self userInfo:[self userID] completion:^(AFHTTPRequestOperation *operation, NSURLRequest *request, id JSON, BOOL tokenStillValid) {
            
            [self setOauthToken:accessToken];
            [self setUserName:[JSON valueForKeyPath:@"data.username"]];
            [self setFollowersCount:[JSON valueForKeyPath:@"data.counts.followed_by"]];
            [self setFollowingCount:[JSON valueForKeyPath:@"data.counts.follows"]];
            [self setFullName:[JSON valueForKeyPath:@"data.full_name"]];
            [self setMediaCount:[JSON valueForKeyPath:@"data.counts.media"]];
            [self setProfilePicture:[JSON valueForKeyPath:@"data.profile_picture"]];
            [self setWebsite:[JSON valueForKeyPath:@"data.website"]];
            [self setBio:[JSON valueForKeyPath:@"data.bio"]];
            
        } failure:^(AFHTTPRequestOperation *operation, id JSON, BOOL tokenStillValid) {
            
        }];
    };
}

-(void)setOauthToken:(NSString *)oauthToken{

    [[PDKeychainBindingsController sharedKeychainBindingsController] setValue:oauthToken forKeyPath:@"values.token"];
}

-(void)setUserID:(NSString *)userID{
    [[PDKeychainBindingsController sharedKeychainBindingsController] setValue:userID forKeyPath:@"values.ig.user.id"];
}
         
-(void)setUserName:(NSString *)userName{
    [[PDKeychainBindingsController sharedKeychainBindingsController] setValue:userName forKeyPath:@"values.ig.user.username"];
}

-(void)setFollowersCount:(NSNumber *)followerCount{
    [[PDKeychainBindingsController sharedKeychainBindingsController] setValue:followerCount.stringValue forKeyPath:@"values.ig.counts.followers"];
}

-(void)setFollowingCount:(NSNumber *)followingCount{
    
    [[PDKeychainBindingsController sharedKeychainBindingsController] setValue:followingCount.stringValue forKeyPath:@"values.ig.counts.following"];
}
         
-(void)setMediaCount:(NSNumber *)mediaCount{
    [[PDKeychainBindingsController sharedKeychainBindingsController] setValue:mediaCount.stringValue forKeyPath:@"values.ig.counts.media"];
}

-(void)setFullName:(NSString *)fullName{
    [[PDKeychainBindingsController sharedKeychainBindingsController] setValue:fullName forKeyPath:@"values.ig.user.fullname"];
}

-(void)setWebsite:(NSString *)website{
    [[PDKeychainBindingsController sharedKeychainBindingsController] setValue:website forKeyPath:@"values.ig.user.website"];
}

-(void)setBio:(NSString *)website{
       [[PDKeychainBindingsController sharedKeychainBindingsController] setValue:website forKeyPath:@"values.ig.user.bio"];
}

-(NSString*)oauthToken{
    return [[PDKeychainBindingsController sharedKeychainBindingsController] valueForKeyPath:@"values.token"];
}

-(NSString*)userID{
    return [[PDKeychainBindingsController sharedKeychainBindingsController] valueForKeyPath:@"values.ig.user.id"];
}

-(NSString*)userName{
    return [[PDKeychainBindingsController sharedKeychainBindingsController] valueForKeyPath:@"values.ig.user.username"];
}

-(NSString*)fullName{
        return [[PDKeychainBindingsController sharedKeychainBindingsController] valueForKeyPath:@"values.ig.user.fullname"];
}

-(NSString*)followersCount{
    return [[PDKeychainBindingsController sharedKeychainBindingsController] valueForKeyPath:@"values.ig.counts.followers"];
}

-(NSString*)followingCount{
    return [[PDKeychainBindingsController sharedKeychainBindingsController] valueForKeyPath:@"values.ig.counts.following"];
}
         
-(NSString*)mediaCount{
    return [[PDKeychainBindingsController sharedKeychainBindingsController] valueForKeyPath:@"values.ig.counts.media"];
}

-(NSString*)website{
   return [[PDKeychainBindingsController sharedKeychainBindingsController] valueForKeyPath:@"values.ig.user.website"];
}

-(NSString*)bio{
    return [[PDKeychainBindingsController sharedKeychainBindingsController] valueForKeyPath:@"values.ig.user.bio"];
}

- (NSDictionary*)parseURLParams:(NSString *)query {
	NSArray *pairs = [query componentsSeparatedByString:@"&"];
	NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
	for (NSString *pair in pairs) {
		NSArray *kv = [pair componentsSeparatedByString:@"="];
		NSString *val = [[kv objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
		[params setObject:val forKey:[kv objectAtIndex:0]];
	}
    return params;
}

#pragma mark /media

-(void)popularMedia:(InstagramRequestCompletionBlock)requestCompletedHandler failure:(InstagramRequestFailureBlock)requestFailureHander{
    
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/%@?access_token=%@",kInstagramBaseURI,kInstagramEndpointMedia,kInstagramMethodPopular,self.oauthToken]];
    
    [self instagramRequestWithURL:URL HTTPMethod:kHTTPMethodGet  completion:(InstagramRequestCompletionBlock)requestCompletedHandler failure:(InstagramRequestFailureBlock)requestFailureHander];
    
}

-(void)mediaInfo:(NSString*)mediaID  completion:(InstagramRequestCompletionBlock)requestCompletedHandler failure:(InstagramRequestFailureBlock)requestFailureHander{
    
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/%@?access_token=%@",kInstagramBaseURI,kInstagramEndpointMedia,mediaID,self.oauthToken]];
    
    [self instagramRequestWithURL:URL HTTPMethod:kHTTPMethodGet completion:(InstagramRequestCompletionBlock)requestCompletedHandler failure:(InstagramRequestFailureBlock)requestFailureHander];
}

-(void)mediaComments:(NSString*)mediaID  completion:(InstagramRequestCompletionBlock)requestCompletedHandler failure:(InstagramRequestFailureBlock)requestFailureHander{
    
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/%@/%@?access_token=%@",kInstagramBaseURI,kInstagramEndpointMedia,mediaID,kInstagramMethodComments,self.oauthToken]];
    
    [self instagramRequestWithURL:URL HTTPMethod:kHTTPMethodGet  completion:(InstagramRequestCompletionBlock)requestCompletedHandler failure:(InstagramRequestFailureBlock)requestFailureHander];
}

-(void)mediaSearchByLocation:(CLLocationCoordinate2D)location  completion:(InstagramRequestCompletionBlock)requestCompletedHandler failure:(InstagramRequestFailureBlock)requestFailureHander{
    
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/%@?lat=%f&lng=%f&access_token=%@",kInstagramBaseURI,kInstagramEndpointMedia,kInstagramMethodSearch,location.latitude,location.longitude, self.oauthToken]];
    
    [self instagramRequestWithURL:URL HTTPMethod:kHTTPMethodGet  completion:(InstagramRequestCompletionBlock)requestCompletedHandler failure:(InstagramRequestFailureBlock)requestFailureHander];
}

#pragma mark /tags

-(void)tagInfo:(NSString*)tag  completion:(InstagramRequestCompletionBlock)requestCompletedHandler failure:(InstagramRequestFailureBlock)requestFailureHander{
    
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/%@?access_token=%@",kInstagramBaseURI,kInstagramEndpointTags,tag,self.oauthToken]];
    
    [self instagramRequestWithURL:URL HTTPMethod:kHTTPMethodGet  completion:(InstagramRequestCompletionBlock)requestCompletedHandler failure:(InstagramRequestFailureBlock)requestFailureHander];
}

-(void)tagMediaRecent:(NSString*)tag  completion:(InstagramRequestCompletionBlock)requestCompletedHandler failure:(InstagramRequestFailureBlock)requestFailureHander{
    
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/%@/%@/%@?access_token=%@",kInstagramBaseURI,kInstagramEndpointTags,tag,kInstagramEndpointMedia,kInstagramMethodRecent,self.oauthToken]];

    
    [self instagramRequestWithURL:URL HTTPMethod:kHTTPMethodGet  completion:(InstagramRequestCompletionBlock)requestCompletedHandler failure:(InstagramRequestFailureBlock)requestFailureHander];
}

-(void)tagsSearch:(NSString*)tag  completion:(InstagramRequestCompletionBlock)requestCompletedHandler failure:(InstagramRequestFailureBlock)requestFailureHander{
    
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/%@?q=%@&access_token=%@",kInstagramBaseURI,kInstagramEndpointTags,kInstagramMethodSearch,tag,self.oauthToken]];
    
    [self instagramRequestWithURL:URL HTTPMethod:kHTTPMethodGet  completion:(InstagramRequestCompletionBlock)requestCompletedHandler failure:(InstagramRequestFailureBlock)requestFailureHander];
}

#pragma mark /users

-(void)userInfo:(NSString *)userName  completion:(InstagramRequestCompletionBlock)requestCompletedHandler failure:(InstagramRequestFailureBlock)requestFailureHander{
    
    if ([userName.lowercaseString isEqualToString:@"me"]){
        userName = [self userID];
    }
    
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/%@?access_token=%@",kInstagramBaseURI,kInstagramEndpointUsers,userName,self.oauthToken]];
    
    [self instagramRequestWithURL:URL HTTPMethod:kHTTPMethodGet  completion:(InstagramRequestCompletionBlock)requestCompletedHandler failure:(InstagramRequestFailureBlock)requestFailureHander];
    
}

-(void)userFollowing:(NSString*)userID completion:(InstagramRequestCompletionBlock)requestCompletedHandler failure:(InstagramRequestFailureBlock)requestFailureHander{
    
    if ([userID.lowercaseString isEqualToString:@"me"]){
        userID = [self userID];
    }
    
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/%@/%@?access_token=%@",kInstagramBaseURI,kInstagramEndpointUsers,userID,kInstagramMethodFollows,self.oauthToken]];
    
    [self instagramRequestWithURL:URL HTTPMethod:kHTTPMethodGet completion:(InstagramRequestCompletionBlock)requestCompletedHandler failure:(InstagramRequestFailureBlock)requestFailureHander];
}

-(void)userFollowers:(NSString*)userID completion:(InstagramRequestCompletionBlock)requestCompletedHandler failure:(InstagramRequestFailureBlock)requestFailureHander{
    
    if ([userID.lowercaseString isEqualToString:@"me"]){
        userID = [self userID];
    }
    
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/%@/%@?access_token=%@",kInstagramBaseURI,kInstagramEndpointUsers,userID,kInstagramMethodFollowers,self.oauthToken]];
    
    [self instagramRequestWithURL:URL HTTPMethod:kHTTPMethodGet completion:(InstagramRequestCompletionBlock)requestCompletedHandler failure:(InstagramRequestFailureBlock)requestFailureHander];
}

-(void)userFeed:(InstagramRequestCompletionBlock)requestCompletedHandler failure:(InstagramRequestFailureBlock)requestFailureHander{
    
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/%@?access_token=%@",kInstagramBaseURI,kInstagramEndpointUsers,kInstagramMethodSelfFeed,self.oauthToken]];
    
    [self instagramRequestWithURL:URL HTTPMethod:kHTTPMethodGet completion:(InstagramRequestCompletionBlock)requestCompletedHandler failure:(InstagramRequestFailureBlock)requestFailureHander];
}

-(void)userLikes:(InstagramRequestCompletionBlock)requestCompletedHandler failure:(InstagramRequestFailureBlock)requestFailureHander{
    
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/%@?access_token=%@",kInstagramBaseURI,kInstagramEndpointUsers,kInstagramMethodSelfMediaLikes,self.oauthToken]];
    
    [self instagramRequestWithURL:URL HTTPMethod:kHTTPMethodGet completion:(InstagramRequestCompletionBlock)requestCompletedHandler failure:(InstagramRequestFailureBlock)requestFailureHander];
}

-(void)nextPagination:(NSURL*)paginationURL completion:(InstagramRequestCompletionBlock)requestCompletedHandler failure:(InstagramRequestFailureBlock)requestFailureHander{
    
    [self instagramRequestWithURL:paginationURL HTTPMethod:kHTTPMethodGet  completion:(InstagramRequestCompletionBlock)requestCompletedHandler failure:(InstagramRequestFailureBlock)requestFailureHander];
    
}

#pragma mark Networking

-(void)instagramRequestWithURL:(NSURL*)url HTTPMethod:(NSString*)httpMethod completion:(InstagramRequestCompletionBlock)requestCompletedHandler failure:(InstagramRequestFailureBlock)requestFailureHander{
    
    NSMutableURLRequest *mutableRequest = [NSMutableURLRequest requestWithURL:url];
    
    [mutableRequest setHTTPMethod:httpMethod];
  
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]
                                         initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@", responseObject);

        requestCompletedHandler(operation,request,responseObject,TRUE);

    } failure:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@", responseObject);
       
        @try {
            if ([responseObject errorStatusCode] == 1011){
                NSLog(@"Instagram Unavailable");
            } else if ([responseObject errorStatusCode] == 500){
                NSLog(@"Instagram Unavailable");
            } else if ([[responseObject valueForKeyPath:@"meta.error_type"] isEqualToString:@"OAuthAccessTokenException"]){
                
                [self setOauthToken:@""];
                [self authenticate];
            }

        }
        @catch (NSException *exception) {
            NSLog(@"IG Auth exception:%@",exception);
        }
        @finally {
            
        }
        
        
        requestFailureHander(operation,responseObject,TRUE);

    }];
    
    
    [operation start];
    
//    requestCompletedHandler(operation,request,JSON,TRUE);
    
    
//        
//        NSLog(@"IG Failed Request JSON:%@",JSON);
//        NSLog(@"IG Request Error JSON:%@",JSON);
//        
//        NSLog(@"IG:%@",[JSON valueForKeyPath:@"meta.error_type"]);
//        
//        NSLog(@"error localizedRecoverySuggestion:%@",error.localizedRecoverySuggestion);
//        NSLog(@"error code:%i",error.code);
//        NSLog(@"error localizedRecoveryOptions:%@",error.localizedRecoveryOptions);
//        NSLog(@"error localizedFailureReason:%@",error.localizedFailureReason);
//        NSLog(@"error localizedDescription:%@",error.localizedDescription);
//        NSLog(@"error dataDictionary:%@",error.dataDictionary);
        
    
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    
    if ([request.URL.scheme isEqualToString:@"ig"]){
        [self processReturnedAuthenticationURL:request.URL completion:^(BOOL didAuthenticate, NSString *dialogMessage, NSString *token) {
            
            if (didAuthenticate){
                
//                if ([self.appDelegate.window.rootViewController isKindOfClass:[UINavigationController class]]){
//                    [self.appDelegate.window.rootViewController.navigationController popViewControllerAnimated:TRUE];
//                } else {
//                    [self.appDelegate.window.rootViewController dismissViewControllerAnimated:TRUE completion:^{
//                        
//                    }];
//                }
                NSLog(@"IG auth message:%@",dialogMessage);
            } else {
                
            }
        }];
        
        return FALSE;
    } else if ([request.URL.description isEqualToString:@"http://instagram.com/"]){
        [self.webView loadRequest:self.authRequest];
        return FALSE;
    }
//    } else if ([request.URL.lastPathComponent isEqualToString:@"authorize"]){
////        UIViewController *vc = [[UIViewController alloc] init];
////        [vc.view addSubview:self.webView];
//  
//       
//        
//        
////        if ([self.appDelegate.window.rootViewController isKindOfClass:[UINavigationController class]]){
////            [self.appDelegate.window.rootViewController.navigationController pushViewController:vc animated:TRUE];
////        } else {
////            [self.appDelegate.window.rootViewController presentViewController:vc animated:TRUE completion:^{
////                
////            }];
////        }
//    }
    
    NSLog(@"Should load URL:%@",request.URL.description);
    NSLog(@"Base URL:%@",request.URL.baseURL);
    NSLog(@"Scheme URL:%@",request.URL.scheme);
    NSLog(@"Lastpath URL:%@",request.URL.lastPathComponent);
    NSLog(@"Fragment URL:%@",request.URL.fragment);
    
    return TRUE;
}

-(void)webViewDidFinishLoad:(UIWebView *)webView{
    NSLog(@"Waiting for Authentication from user:");
     [[self.appDelegate window] addSubview:self.webView];
    
}

-(void)webViewDidStartLoad:(UIWebView *)webView{
    NSLog(@"Request Authentication:");
}

-(void)informDelegateAuthenticationFailed{
    if ([self.delegate respondsToSelector:@selector(instagramAuthenticationFailed)]){
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate performSelector:@selector(instagramAuthenticationFailed)];
        });
        
    }
}

-(void)informDelegateAuthenticated{
    if ([self.delegate respondsToSelector:@selector(instagramAuthenticated)]){
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate performSelector:@selector(instagramAuthenticated)];
        });
    }
}


@end
