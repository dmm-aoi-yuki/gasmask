/***************************************************************************
 *   Copyright (C) 2009-2013 by Clockwise   *
 *   copyright@clockwise.ee   *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             *
 ***************************************************************************/

#import "PrivilegedActions.h"
#import <Security/Authorization.h>
#import <Security/AuthorizationTags.h>
#include <sys/wait.h>

static AuthorizationRef authorizationRef = NULL;

@implementation PrivilegedActions

#pragma mark - Authorization (one-time per app session)

+ (BOOL)ensureAuthorized
{
	if (authorizationRef != NULL) {
		return YES;
	}

	OSStatus status = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment,
		kAuthorizationFlagDefaults, &authorizationRef);
	if (status != errAuthorizationSuccess) {
		logDebug(@"AuthorizationCreate failed: %d", (int)status);
		return NO;
	}

	AuthorizationItem items = {kAuthorizationRightExecute, 0, NULL, 0};
	AuthorizationRights rights = {1, &items};

	AuthorizationFlags flags = kAuthorizationFlagDefaults |
		kAuthorizationFlagInteractionAllowed |
		kAuthorizationFlagPreAuthorize |
		kAuthorizationFlagExtendRights;

	status = AuthorizationCopyRights(authorizationRef, &rights,
		kAuthorizationEmptyEnvironment, flags, NULL);

	if (status != errAuthorizationSuccess) {
		logDebug(@"AuthorizationCopyRights failed: %d", (int)status);
		AuthorizationFree(authorizationRef, kAuthorizationFlagDefaults);
		authorizationRef = NULL;
		return NO;
	}

	return YES;
}

#pragma mark - Privileged execution

+ (BOOL)executeCommand:(const char *)command withArguments:(const char **)arguments
{
	if (![self ensureAuthorized]) {
		return NO;
	}

	#pragma clang diagnostic push
	#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	OSStatus status = AuthorizationExecuteWithPrivileges(
		authorizationRef, command, kAuthorizationFlagDefaults,
		(char *const *)arguments, NULL);
	#pragma clang diagnostic pop

	if (status != errAuthorizationSuccess) {
		logDebug(@"AuthorizationExecuteWithPrivileges failed: %d", (int)status);
		return NO;
	}

	int child;
	wait(&child);

	return YES;
}

#pragma mark - Public API

+ (BOOL)removeFile:(NSString*)path
{
	const char *arguments[] = {"-fr", [path fileSystemRepresentation], NULL};
	return [self executeCommand:"/bin/rm" withArguments:arguments];
}

+ (BOOL)copyFile:(NSString*)source to:(NSString*)destination
{
	const char *arguments[] = {
		[source fileSystemRepresentation],
		[destination fileSystemRepresentation],
		NULL
	};
	return [self executeCommand:"/bin/cp" withArguments:arguments];
}

+ (BOOL)makeWritableForCurrentUser:(NSString*)path prompt:(NSString*)prompt
{
	logDebug(@"Making %@ writable for user %@", path, NSUserName());

	NSString *aclArg = [NSString stringWithFormat:@"user:%@:allow write", NSUserName()];
	const char *arguments[] = {
		"+a",
		[aclArg UTF8String],
		[path fileSystemRepresentation],
		NULL
	};
	return [self executeCommand:"/bin/chmod" withArguments:arguments];
}

+ (BOOL)writeContents:(NSString*)contents toFile:(NSString*)path
{
	NSString *tmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:
		[[NSUUID UUID] UUIDString]];

	NSError *error = nil;
	[contents writeToFile:tmpPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
	if (error) {
		logDebug(@"Failed to write temp file: %@", error);
		return NO;
	}

	const char *cpArgs[] = {
		[tmpPath fileSystemRepresentation],
		[path fileSystemRepresentation],
		NULL
	};
	BOOL success = [self executeCommand:"/bin/cp" withArguments:cpArgs];

	if (success) {
		NSString *aclArg = [NSString stringWithFormat:@"user:%@:allow write", NSUserName()];
		const char *chmodArgs[] = {
			"+a",
			[aclArg UTF8String],
			[path fileSystemRepresentation],
			NULL
		};
		[self executeCommand:"/bin/chmod" withArguments:chmodArgs];
	}

	[[NSFileManager defaultManager] removeItemAtPath:tmpPath error:nil];
	return success;
}

+ (BOOL)authorized
{
	return authorizationRef != NULL;
}

+ (BOOL)authorize
{
	return [self ensureAuthorized];
}

+ (BOOL)authorizeWithPrompt:(NSString*)prompt
{
	return [self ensureAuthorized];
}

@end
