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
#import <LocalAuthentication/LocalAuthentication.h>

static BOOL authorized;
static AuthorizationRef authorizationRef;

@interface PrivilegedActions (Private)
+(BOOL)execute:(const char *)command withArguments:(char *const *)arguments;
+(BOOL)authenticateWithBiometrics:(NSString*)reason;
+(BOOL)acquireAuthorizationSilently;
+(BOOL)authorizeWithPasswordDialog:(NSString*)prompt;
@end

@implementation PrivilegedActions

+(BOOL)removeFile:(NSString*)path
{
	if (![self authorized] && ![self authorize]) {
		return NO;
	}
	
	const char * arguments[] = {"-fr", [path UTF8String], NULL};
	return [self execute:"/bin/rm" withArguments: (char **)arguments];
}

+ (BOOL)copyFile:(NSString*)source to:(NSString*)destination
{
	if (![self authorized] && ![self authorize]) {
		return NO;
	}
	
	const char * arguments[] = {[source UTF8String], [destination UTF8String], NULL};
	return [self execute:"/bin/cp" withArguments: (char **)arguments];
}

+ (BOOL)makeWritableForCurrentUser:(NSString*)path prompt:(NSString*)prompt
{
	if (![self authorized] && ![self authorizeWithPrompt:prompt]) {
		return NO;
	}
	
	logDebug(@"Making %@ writable for user %@", path, NSUserName());
	
	NSMutableString *arg = [NSMutableString new];
    [arg appendString:@"user:"];
	[arg appendString:NSUserName()];
	[arg appendString:@":allow write"];
	
	const char * arguments[] = {"+a", [arg UTF8String], [path UTF8String], NULL};
	return [self execute:"/bin/chmod" withArguments: (char **)arguments];
}

+(BOOL)authorized
{
	return authorized;
}

+(BOOL)authorize
{
	return [self authorizeWithPrompt:nil];
}

+ (BOOL)authorizeWithPrompt:(NSString*)prompt
{
	NSString *reason = prompt ?: @"Gas Mask needs administrator privileges to modify the hosts file.";

	// Try Touch ID / biometric authentication first
	if ([self authenticateWithBiometrics:reason]) {
		// Biometric auth succeeded — try to acquire authorization silently
		if ([self acquireAuthorizationSilently]) {
			authorized = YES;
			return authorized;
		}
	}

	// Fall back to the standard password dialog
	// (On macOS 14+ this dialog also offers Touch ID)
	return [self authorizeWithPasswordDialog:prompt];
}

@end

@implementation PrivilegedActions(Private)

+(BOOL)authenticateWithBiometrics:(NSString*)reason
{
	LAContext *context = [[LAContext alloc] init];
	NSError *error = nil;

	if (![context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
		logDebug(@"Biometric authentication not available: %@", error);
		return NO;
	}

	__block BOOL success = NO;
	dispatch_semaphore_t sema = dispatch_semaphore_create(0);

	[context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
			localizedReason:reason
					  reply:^(BOOL result, NSError *authError) {
		if (!result) {
			logDebug(@"Biometric authentication failed: %@", authError);
		}
		success = result;
		dispatch_semaphore_signal(sema);
	}];

	dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
	return success;
}

+(BOOL)acquireAuthorizationSilently
{
	OSStatus status;
	AuthorizationFlags flags = kAuthorizationFlagDefaults;

	status = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, flags, &authorizationRef);
	if (status != errAuthorizationSuccess) {
		logDebug(@"Failed to create AuthorizationRef");
		return NO;
	}

	AuthorizationItem items = {kAuthorizationRightExecute, 0, NULL, 0};
	AuthorizationRights rights = {1, &items};

	flags = kAuthorizationFlagDefaults |
	kAuthorizationFlagExtendRights |
	kAuthorizationFlagPreAuthorize;

	status = AuthorizationCopyRights(authorizationRef, &rights, kAuthorizationEmptyEnvironment, flags, NULL);
	return status == errAuthorizationSuccess;
}

+(BOOL)authorizeWithPasswordDialog:(NSString*)prompt
{
	OSStatus status;
	AuthorizationFlags flags = kAuthorizationFlagDefaults;

	status = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, flags, &authorizationRef);
	if (status != errAuthorizationSuccess) {
		logDebug(@"Failed to Authorize");
		authorized = NO;
		return authorized;
	}

	AuthorizationItem items = {kAuthorizationRightExecute, 0, NULL, 0};
	AuthorizationRights rights = {1, &items};

	AuthorizationItem authPrompt = {kAuthorizationEnvironmentPrompt, [prompt length], (void *)[prompt UTF8String], 0};
	AuthorizationEnvironment environment = { 1, &authPrompt };

	flags = kAuthorizationFlagDefaults |
	kAuthorizationFlagInteractionAllowed |
	kAuthorizationFlagPreAuthorize |
	kAuthorizationFlagExtendRights;

	status = AuthorizationCopyRights(authorizationRef, &rights, &environment, flags, NULL);

	if (status != errAuthorizationSuccess) {
		logDebug(@"Failed to Authorize");
		authorized = NO;
		return authorized;
	}

	authorized = YES;
	return authorized;
}

+(BOOL)execute:(const char *)command withArguments:(char *const *)arguments
{
	AuthorizationFlags flags = kAuthorizationFlagDefaults;
	
	#pragma clang diagnostic push
	#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	OSStatus status = AuthorizationExecuteWithPrivileges(authorizationRef, command, flags, (char **)arguments, NULL);
	#pragma clang diagnostic pop
	
	[NSThread sleepForTimeInterval:1];
	
	return status == errAuthorizationSuccess;
}

@end
