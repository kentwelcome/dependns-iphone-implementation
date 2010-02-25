//
//  ResolverDB.h
//  DepenDNS
//
//  Created by Mac on 2010/2/18.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface ResolverDB : NSObject {

	sqlite3 *resolver_db;
	sqlite3_stmt *statement;
}

- (id)init;
- (void)dealloc;

- (void) InstallNewDatabase;
- (void) createDatabaseIfNeeded;
- (void) UpgradeDatabase: (NSString*) dbfile;
- (void) getResolversFromDb: (NSMutableDictionary*) resolver_array;
- (int) queryHistory: (NSString*) domain: (NSMutableArray*)iparray: (NSMutableDictionary*)countarray;
- (Boolean) insertToHistory: (NSString*) domain: (NSString*) ipaddr: (int) Count;

@end
