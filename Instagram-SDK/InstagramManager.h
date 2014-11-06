//
//  InstagramManager.h
//  Instagram-SDK
//
//  Created by Adam Roberts on 05/01/2014.
//  Copyright (c) 2014 Enigmatic Flare Ltd. All rights reserved.
//
#import "InstagramAuthenticationViewController.h"
#import "AFNetworking.h"
@import Foundation;
@import UIKit;
@import CoreLocation;

@protocol InstagramManagerDelegate
-(void)instagramAuthenticated;
-(void)instagramAuthenticationFailed;
@end

@interface InstagramManager : NSObject <UIWebViewDelegate>

extern NSString *const SLServiceTypeInstagram;

@property (nonatomic, strong) NSString *oauthToken;
@property (nonatomic, strong) NSString *userID;
@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *fullName;
@property (nonatomic, strong) NSString *profilePicture;
@property (nonatomic, strong) NSString *followersCount;
@property (nonatomic, strong) NSString *followingCount;
@property (nonatomic, strong) NSString *mediaCount;

@property (nonatomic, strong) NSString *bio;
@property (nonatomic, strong) NSString *website;

@property (nonatomic, assign) id delegate;

typedef void (^InstagramRequestCompletionBlock)(AFHTTPRequestOperation *operation, NSURLRequest *request, id JSON, BOOL tokenStillValid);

typedef void (^InstagramRequestFailureBlock)(AFHTTPRequestOperation *operation, id JSON ,BOOL tokenStillValid);

typedef void (^InstagramAuthenticationCompletionBlock)(BOOL didAuthenticate, NSString *dialogMessage, NSString *token);

+(instancetype)sharedManager;

#pragma mark authentication

-(NSURL*)requestAuthenticateURLForUsingClientId:(NSString*)clientId requestCommentsEndpointPermission:(BOOL)requestCommentsPermission
         requestRelationshipsEndpointPermission:(BOOL)requestRelationshipsPermission
                 RequestLikesEndpointPermission:(BOOL)requestLikesPermission;

- (void)processReturnedAuthenticationURL:(NSURL *)url completion:(InstagramAuthenticationCompletionBlock)authenticationHandler;

-(void)authenticateUsingClientId:(NSString*)clientId requestCommentsEndpointPermission:(BOOL)requestCommentsPermission
requestRelationshipsEndpointPermission:(BOOL)requestRelationshipsPermission
  RequestLikesEndpointPermission:(BOOL)requestLikesPermission;

#pragma mark /media

-(void)popularMedia:(InstagramRequestCompletionBlock)requestCompletedHandler failure:(InstagramRequestFailureBlock)requestFailureHander;

-(void)mediaInfo:(NSString*)mediaID  completion:(InstagramRequestCompletionBlock)requestCompletedHandler failure:(InstagramRequestFailureBlock)requestFailureHander;

-(void)mediaComments:(NSString*)mediaID  completion:(InstagramRequestCompletionBlock)requestCompletedHandler failure:(InstagramRequestFailureBlock)requestFailureHander;

-(void)mediaSearchByLocation:(CLLocationCoordinate2D)location  completion:(InstagramRequestCompletionBlock)requestCompletedHandler failure:(InstagramRequestFailureBlock)requestFailureHander;

#pragma mark /tags

-(void)tagInfo:(NSString*)tag completion:(InstagramRequestCompletionBlock)requestCompletedHandler failure:(InstagramRequestFailureBlock)requestFailureHander;

-(void)tagMediaRecent:(NSString*)tag completion:(InstagramRequestCompletionBlock)requestCompletedHandler failure:(InstagramRequestFailureBlock)requestFailureHander;

-(void)tagsSearch:(NSString*)tag completion:(InstagramRequestCompletionBlock)requestCompletedHandler failure:(InstagramRequestFailureBlock)requestFailureHander;

#pragma mark /users

-(void)userInfo:(NSString *)userName completion:(InstagramRequestCompletionBlock)requestCompletedHandler failure:(InstagramRequestFailureBlock)requestFailureHander;

-(void)userFollowers:(NSString*)userID completion:(InstagramRequestCompletionBlock)requestCompletedHandler failure:(InstagramRequestFailureBlock)requestFailureHander;

-(void)userFollowing:(NSString*)userID completion:(InstagramRequestCompletionBlock)requestCompletedHandler failure:(InstagramRequestFailureBlock)requestFailureHander;

-(void)userFeed:(InstagramRequestCompletionBlock)requestCompletedHandler failure:(InstagramRequestFailureBlock)requestFailureHander;

-(void)userLikes:(InstagramRequestCompletionBlock)requestCompletedHandler failure:(InstagramRequestFailureBlock)requestFailureHander;

#pragma mark /pagination

-(void)nextPagination:(NSURL*)paginationURL  completion:(InstagramRequestCompletionBlock)requestCompletedHandler failure:(InstagramRequestFailureBlock)requestFailureHander;

@end

