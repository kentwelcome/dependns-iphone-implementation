//
//  ResolverDB.m
//  DepenDNS
//
//  Created by Mac on 2010/2/18.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ResolverDB.h"

@implementation ResolverDB

- (id)init
{
	self = [super init];
	[self createDatabaseIfNeeded];
	return self;
}

- (void)dealloc
{
	[super dealloc];
}

// Creates a writable copy of the bundled default database in the application Documents directory.
- (void) InstallNewDatabase {
	NSLog(@"InstallNewDatabase");
    // First, test for existence.
    BOOL success;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *writableDBPath = [documentsDirectory stringByAppendingPathComponent:@"dns_init.sqlite"];
    success = [fileManager fileExistsAtPath:writableDBPath];
	
    if (success) {
		NSLog(@"database exist!");
		BOOL delok;
		delok = [fileManager removeItemAtPath:writableDBPath error:&error];
		if(!delok)
			NSLog(@"Failed to delete database file with message '%@'.", [error localizedDescription]);
	}
    // The writable database does not exist, so copy the default to the appropriate location.
    NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"dns_init.sqlite"];
    success = [fileManager copyItemAtPath:defaultDBPath toPath:writableDBPath error:&error];
    if (!success) {
        NSAssert1(0, @"Failed to create writable database file with message '%@'.", [error localizedDescription]);
    }
}


// Creates a writable copy of the bundled default database in the application Documents directory.
- (void) createDatabaseIfNeeded {
	
	NSLog(@"Create Database IfNeeded.");
    // First, test for existence.
    BOOL success;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *DBPath = [documentsDirectory stringByAppendingPathComponent:@"dns_init.sqlite"];
    success = [fileManager fileExistsAtPath:DBPath];
    if (success) return;
    // The writable database does not exist, so copy the default to the appropriate location.
    NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"dns_init.sqlite"];
    success = [fileManager copyItemAtPath:defaultDBPath toPath:DBPath error:&error];
    if (!success) {
        NSAssert1(0, @"Failed to create writable database file with message '%@'.", [error localizedDescription]);
    }
}




- (void) UpgradeDatabase: (NSString*) dbfile
{
	NSLog(@"Update Database.");
    // First, test for existence.
    BOOL success;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *DBPath = [documentsDirectory stringByAppendingPathComponent: dbfile];
    success = [fileManager fileExistsAtPath:DBPath];
	
    if (success) {
		NSLog(@"database already exist! Does not need to upgrade");
		return;
	}
    // The writable database does not exist, so copy the default to the appropriate location.
    NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: dbfile];
    success = [fileManager copyItemAtPath:defaultDBPath toPath:DBPath error:&error];
    if (!success) {
        NSAssert1(0, @"Failed to create writable database file with message '%@'.", [error localizedDescription]);
    }
}


- (void) getResolversFromDb: (NSMutableDictionary*) resolver_array
{
	NSLog(@"Get Reolvers from Database.");
    // The database is stored in the application bundle. 
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"dns_init.sqlite"];
	
    // Open the database. The database was prepared outside the application.
    if (sqlite3_open([path UTF8String], &resolver_db) == SQLITE_OK) {
		NSLog(@"SQLITE_OK");
        // Get the primary key for all books.
        const char *sql = "SELECT * FROM resolvers";
		NSLog(@"query str = %s", sql);
		
        if (sqlite3_prepare_v2(resolver_db, sql, -1, &statement, NULL) == SQLITE_OK) {
            // We "step" through the results - once for each row.
			while (sqlite3_step(statement) == SQLITE_ROW) {
				// Get resolver's name
				NSString* name = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
				NSLog(@"Name: %@", name);
				// Get resolver's ip address
				NSString* ipaddr = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 1)];
				NSLog(@"IP: %@", ipaddr);
				
				[resolver_array setObject:ipaddr forKey:name];
			}
        }
        // Reset the statement for future reuse.
        sqlite3_reset(statement);
		NSLog(@"Finish Query");
    } else {
        // Even though the open failed, call close to properly clean up resources.
        sqlite3_close(resolver_db);
        NSAssert1(0, @"Failed to open database with message '%s'.", sqlite3_errmsg(resolver_db));
        // Additional error handling, as appropriate...
    }
}

- (int) queryHistory: (NSString*) domain: (NSMutableArray*)iparray: (NSMutableDictionary*)countarray
{
	int hit = 0;
	NSLog(@"Get History Records from Database.");
    // The database is stored in the application bundle. 
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"dns_init.sqlite"];
	
    // Open the database. The database was prepared outside the application.
    if (sqlite3_open([path UTF8String], &resolver_db) == SQLITE_OK) {
		NSLog(@"SQLITE_OK");
        // Get the primary key for all books.
        const char *sql = "SELECT ip_addr, count FROM dnshistory WHERE domain = ?";
		NSLog(@"query str = %s", sql);
		
        // Preparing a statement compiles the SQL query into a byte-code program in the SQLite library.
        // The third parameter is either the length of the SQL string or -1 to
		// read up to the first null terminator.        
        if (sqlite3_prepare_v2(resolver_db, sql, -1, &statement, NULL) == SQLITE_OK) {
			
			sqlite3_bind_text(statement, 1, [domain UTF8String], -1, SQLITE_TRANSIENT);
			
            // We "step" through the results - once for each row.
			while (sqlite3_step(statement) == SQLITE_ROW) {
				// Get history ip address
				hit++;
				NSString* ipaddr = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
				NSString* count = [NSString stringWithFormat: @"%d", sqlite3_column_int(statement, 1)];
				NSLog(@"IP: %@", ipaddr);
				NSLog(@"Count: %@", count);
				[iparray addObject:ipaddr];
				[countarray setObject:count forKey:ipaddr];
			}
        }
        // Reset the statement for future reuse.
        sqlite3_reset(statement);
		NSLog(@"Finish Query");
		return hit;
    } else {
        // Even though the open failed, call close to properly clean up resources.
        sqlite3_close(resolver_db);
        NSAssert1(0, @"Failed to open database with message '%s'.", sqlite3_errmsg(resolver_db));
		return -1;
        // Additional error handling, as appropriate...
    }
}

- (Boolean) insertToHistory: (NSString*) domain: (NSString*) ipaddr: (int) Count
{
	Boolean success = NO;
	
	NSLog(@"Insert History Record to the Database.");
	
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"dns_init.sqlite"];
	
    // Open the database. The database was prepared outside the application.
    if (sqlite3_open([path UTF8String], &resolver_db) == SQLITE_OK) {
		NSLog(@"SQLITE_OK");
        // Get the primary key for all books.
        const char *sql = "insert into dnshistory (qid, domain, ip_addr, count) values (?,?,?,?);";
		NSLog(@"query str = %s", sql);
		
        // Preparing a statement compiles the SQL query into a byte-code program in the SQLite library.
        // The third parameter is either the length of the SQL string or -1 to read up to the first null terminator.        
        if (sqlite3_prepare_v2(resolver_db, sql, -1, &statement, NULL) == SQLITE_OK) {
			
			srand(time(0));
			int r = arc4random();
			NSLog(@"Random Number = %d", r);
			NSString* uid = [NSString stringWithFormat:@"%d", r];
			sqlite3_bind_text(statement, 1, [uid UTF8String], -1, SQLITE_TRANSIENT);
			sqlite3_bind_text(statement, 2, [domain UTF8String], -1, SQLITE_TRANSIENT);
			sqlite3_bind_text(statement, 3, [ipaddr UTF8String], -1, SQLITE_TRANSIENT);
			sqlite3_bind_int(statement, 4, Count);
			
            if(SQLITE_DONE != sqlite3_step(statement)) {
				NSAssert1(0, @"Error while inserting data. '%s'", sqlite3_errmsg(resolver_db));
				return success;
			}
        }
        // Reset the statement for future reuse.
        sqlite3_reset(statement);
		NSLog(@"Finish Insertion");
		
		return success;
    } else {
        // Even though the open failed, call close to properly clean up resources.
        sqlite3_close(resolver_db);
        NSAssert1(0, @"Failed to open database with message '%s'.", sqlite3_errmsg(resolver_db));
		return success;
        // Additional error handling, as appropriate...
    }
	
}



@end
