//  lala test
//  MatchAlgo.h
//  DepenDNS
//
//  Created by Mac on 2010/2/19.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ResolverDB;

@interface MatchAlgo : NSObject {
	
	ResolverDB* mydb;
	
	NSMutableDictionary* resolvers;
	NSCountedSet *answers;
	NSMutableArray* history_ip;
	NSMutableDictionary* history_count;
	NSMutableArray* verifired_ip;
	
	int solved;
	Boolean hasHistory;
	Boolean hasComplete;
}

- (int) RunMatchAlgo: (NSString*) domain;
- (void) MakeDnsQuery: (NSString*) domain;
- (int) GetN;
- (int) GetNMax;
- (int) Calculate: (NSString*)GivenIP;
- (BOOL) BelongSameBClass: (NSString*) GivneIP;
- (NSString*) getBClass: (NSString*) IP;
- (int) checkTrustWorthy: (NSString*) IP;
- (int) ask_php_server_by_post: (NSString*) domain;
- (int) RunMatchAlgo: (NSString*) domain GetUser: (NSString*) user GetPass: (NSString*) paswd;

@end
