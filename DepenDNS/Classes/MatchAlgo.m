//
//  MatchAlgo.m
//  DepenDNS
//
//  Created by Mac on 2010/2/19.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MatchAlgo.h"
#import "Dns_Util.h"
#import "ResolverDB.h"
#include <arpa/inet.h>
#include <stdlib.h>
#include "ASIAuthenticationDialog.h"
#import "ASIFormDataRequest.h"


NSLock *lock;
int		IP_gread;
NSString *UID , *PAS;


@implementation MatchAlgo

- (id)init
{
	self = [super init];
	// Init Database
	mydb = [[ResolverDB alloc]init];
	// Get resolvers
	if(resolvers==nil) {
		resolvers = [NSMutableDictionary new];
		[mydb getResolversFromDb:resolvers];
	}
	// Init Answer Set
	answers = [NSCountedSet new];
	history_ip = [NSMutableArray new];
	history_count = [NSMutableDictionary new];
	verifired_ip = [NSMutableArray new];
	return self;
}

- (int) RunMatchAlgo: (NSString*) domain GetUser: (NSString*) user GetPass: (NSString*) paswd
{
	// Clear Necessary Objects
	/*[answers removeAllObjects];
	[history_ip removeAllObjects];
	[history_count removeAllObjects];*/
	[verifired_ip removeAllObjects];
	
	//hasHistory = NO;
	hasComplete = NO;
	// Start Query by DNS
	//[self MakeDnsQuery: domain];
	//[self ask_php_server: domain];
	UID = user;
	PAS = paswd;
	
	NSLog(@"User:%@\nPass:%@\n",user,paswd);
	[self ask_php_server_by_post: domain ];
	return 0;
}


- (int) ask_php_server_by_post: (NSString*) domain
{
	NSString *tmp = [NSString stringWithFormat:@"http://is10.cs.nthu.edu.tw/~kent/post.php" ];
	NSURL *url = [NSURL URLWithString: tmp];
	NSString *CanUseIP;
	NSString *IP;
	int index;
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setPostValue: domain forKey: @"ASK_URL" ];
	[request setPostValue: UID forKey:@"User"];
	[request setPostValue: PAS forKey:@"Passwd"];
	
	
	[request startSynchronous];
	NSError *error = [request error];
	if (!error) {
		NSString *response = [request responseString];
		hasComplete = YES;
		NSLog(@"%@\n",response);
		
		response = [response substringFromIndex: [response rangeOfString: @"|"].location+2 ] ;
		while ( index = [response rangeOfString: @"<br>"].location ) {
			CanUseIP = [NSString stringWithFormat:@"%@",[ response substringToIndex: index ] ];
			
			if ( [CanUseIP rangeOfString: @"error"].location != NSNotFound ){
				hasComplete = NO;
				return -1;
			}
			
			
			//NSLog(@"%@.\n",CanUseIP);
			if ( [CanUseIP rangeOfString: @"Greade:"].location != NSNotFound ){ // get dependns greade
				index = [CanUseIP rangeOfString: @"Greade:"].location;
				IP = [NSString stringWithFormat:@"%@",[CanUseIP substringFromIndex:index+8]];
				//NSLog(@"G:%@\n",IP);
				IP_gread = [ IP intValue ];
				NSLog(@"Gread: %d\n",IP_gread);
				break;
			} else {	// get can use IP
				NSLog(@"ver: %@\n",CanUseIP);
				[verifired_ip addObject: CanUseIP];
			}
			
			response = [response substringFromIndex:index+5];
		}
	}
	return 0;
}


- (int) ask_php_server: (NSString*) domain
{
	NSString *tmp = [NSString stringWithFormat:@"http://is10.cs.nthu.edu.tw/~kent/test.php?question=%@",domain];
	NSString *CanUseIP;
	NSString *IP;
	int index;
	NSLog(@"%@\n",tmp);
	NSURL *ask_url = [NSURL URLWithString: tmp];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:ask_url];
	[request startSynchronous];
	NSError *error = [request error];
	if (!error) {
		NSString *response = [request responseString];
		//NSLog(@"PHP Server: %@",response);
		hasComplete = YES;
		
		while ( index = [response rangeOfString: @"<br>"].location ) {
			CanUseIP = [NSString stringWithFormat:@"%@",[ response substringToIndex: index ] ];
			//NSLog(@"%@.\n",CanUseIP);
			if ( [CanUseIP rangeOfString: @"Greade:"].location != NSNotFound ){ // get dependns greade
				index = [CanUseIP rangeOfString: @"Greade:"].location;
				IP = [NSString stringWithFormat:@"%@",[CanUseIP substringFromIndex:index+8]];
				//NSLog(@"G:%@\n",IP);
				IP_gread = [ IP intValue ];
				NSLog(@"Gread: %d\n",IP_gread);
				break;
			} else {	// get can use IP
				[verifired_ip addObject: CanUseIP];
			}

			response = [response substringFromIndex:index+5];
		}
		
	}
	return 0;
}

- (void)MakeDnsQuery: (NSString*) domain
{
	// Check History Records
	[mydb queryHistory: domain: history_ip: history_count];
	if([history_ip count]>0) {
		hasHistory = YES;
		NSLog(@"History Record: %d", [history_ip count]);
	}else
		NSLog(@"No History Record.");
	
	
	NSEnumerator *enumerator = [resolvers keyEnumerator];
	solved = 0;
	lock = [[NSLock alloc] init];
	
	for(NSString *aKey in enumerator){		
		NSString* ip = [resolvers valueForKey:aKey];
		NSLog(@"Ready To Query DNS Server: %@.", aKey);
		NSString* QueryStr = @"";
		QueryStr = [QueryStr stringByAppendingString: domain];
		QueryStr = [QueryStr stringByAppendingString: @":"];
		QueryStr = [QueryStr stringByAppendingString: ip];
		[NSThread detachNewThreadSelector:@selector(QueryDomainByThread:) toTarget:self withObject:QueryStr];
    }
}

/*This is the thread selector. Images will be opened here*/
-(void)QueryDomainByThread: (NSString*)QueryStr
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	// String Parsing
	NSArray *list = [QueryStr componentsSeparatedByString:@":"];
	NSString* domain = [list objectAtIndex:0];
	NSString* dnsserver = [list objectAtIndex:1];
	NSLog(@"Query %@ at %@.", domain, dnsserver);
	const char* hostname = [domain cStringUsingEncoding: NSASCIIStringEncoding];
	const char* cString = [dnsserver cStringUsingEncoding:NSASCIIStringEncoding];
	[lock lock];
	NSLog(@"Enter Crtitical Section.");
	ngethostbyname((unsigned char*)hostname, (unsigned char*)cString, answers);
	[lock unlock];
    //Tell our callback what we've done
    [self performSelectorOnMainThread:@selector(queryComplete:) withObject:QueryStr waitUntilDone:YES];
	
    //remove our pool and free the memory collected by it
    [pool release];
}

- (int) checkTrustWorthy: (NSString*) IP
{
	NSLog(@"Compared IP: %@ with %@\n", IP , verifired_ip);
	
	if(hasComplete){
		if([verifired_ip containsObject:IP])
			return 0;
		else
			return 1;
	}else
		return -1;
}

- (void)queryComplete:(NSString*)QueryStr {
	solved++;
	NSArray *list = [QueryStr componentsSeparatedByString:@":"];
	NSString* domain = [list objectAtIndex:0];
	NSString* dnsserver = [list objectAtIndex:1];
	NSLog(@"Query %@ at %@.", domain, dnsserver);
	NSLog(@"received %d resolvers.", solved);
	
	if(solved==[resolvers count]) {
		hasComplete = YES;
		NSLog(@"queryComplete.");
		
		NSEnumerator *enumerator = [answers objectEnumerator];
		NSString* eachIP;
		// Go through it to get n_max and N
		while (eachIP = (NSString*)[enumerator nextObject]) {
			
			int grade = [self Calculate: eachIP];
			int cnt = [answers countForObject:eachIP];
			NSLog(@"Grade: %d for IP: %@, count = %d", grade, eachIP, cnt);
			
			if(grade>=60) {
				NSLog(@"Add %@ to Verified List", eachIP);
				[verifired_ip addObject: eachIP];
				if(!hasHistory){
					if([mydb insertToHistory: domain: eachIP: cnt])
						NSLog(@"Write To Database Done.");
				}
			}
		}
	}
}


- (int) Calculate: (NSString*)GivenIP
{
	int alpha = 0, beta = 0, gammar = 0, grade = 0;
	int N = [self GetN];
	int N_MAX = [self GetNMax];
	int cnt = 0;
	
	if([answers count]>0) {
		
		cnt = [answers countForObject:GivenIP];
		// Calculate alpha
		if(cnt>=N_MAX*0.8)
			alpha = 1;
		// Check history existing
		if(hasHistory) {
			// Calculate beta
			Boolean in_record = [history_ip containsObject: GivenIP];
			if(in_record) {
				NSLog(@"has beta");
				beta = 1;
			}
			// Calculate gammar
			if([self BelongSameBClass: GivenIP]) {
				NSLog(@"has gammar");
				gammar = 1;
			}
			grade = alpha*(60-(N-1)*10)+0.5*(beta+gammar)*(40+(N-1)*10);
		} else {
			// Initial Record
			grade = alpha*(100-(N-1)*10);
		}
		return grade;
	}else
		return -1;
}

- (int) GetN
{
	return [answers count];
}

- (int) GetNMax
{
	int n_max = 0, count = 0;
	NSEnumerator *enumerator = [answers objectEnumerator];
	id object;
	// Go through it to get n_max and N
	while (object = [enumerator nextObject]) {
		count = [answers countForObject:object];
		if(count>n_max)
			n_max = count;
	}
	return n_max;
}

- (BOOL) BelongSameBClass: (NSString*) GivneIP
{
	BOOL hasGammar = NO;
	NSEnumerator *enumerator = [answers objectEnumerator];
	NSString* EachIP;
	// Go through it to get n_max and N
	while (EachIP = [enumerator nextObject]) {
		if([[self getBClass: GivneIP] compare:[self getBClass: EachIP]]==NSOrderedSame)
		{
			NSLog(@"The Same B-Class.");
			// History
			int cnt1 = [[history_count objectForKey: EachIP] intValue];
			// Current Count
			int cnt2 = [answers countForObject: GivneIP];
			NSLog(@"cnt1 = %d, cnt2 = %d", cnt1, cnt2);
			int diff = abs(cnt1=cnt2);
			float x = (float)diff/cnt1;
			if(x<=0.1) // <= 10%
				hasGammar = YES;
		}
	}
	return hasGammar;
}

- (NSString*) getBClass: (NSString*) IP
{
	int pos = [IP rangeOfString: @"."].location;
	NSString* tmp = [IP substringFromIndex: (pos+1)];
	pos = pos +1 +[tmp rangeOfString: @"."].location;
	return [IP substringToIndex:pos];
}


-(void)dealloc
{
	[verifired_ip release];
	[history_ip release];
	[history_count release];
	[answers release];
	[resolvers release];
	[mydb release];
	[super dealloc];
}

@end
