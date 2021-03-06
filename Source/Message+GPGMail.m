/* Message+GPGMail.m created by Lukas Pitschl (@lukele) on Thu 18-Aug-2011 */

/*
 * Copyright (c) 2000-2011, GPGTools Project Team <gpgtools-devel@lists.gpgtools.org>
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of GPGTools Project Team nor the names of GPGMail
 *       contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE GPGTools Project Team ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE GPGTools Project Team BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Libmacgpg/Libmacgpg.h>
#import "NSObject+LPDynamicIvars.h"
#import <MimePart.h>
#import <MimeBody.h>
#import <MessageStore.h>
#import <ActivityMonitor.h>
#import "MimePart+GPGMail.h"
#import "Message+GPGMail.h"

@implementation Message (GPGMail)

- (void)fakeMessageFlagsIsEncrypted:(BOOL)isEncrypted isSigned:(BOOL)isSigned {
    if(isEncrypted)
        _messageFlags |= 0x00000008;
    if(isSigned)
        _messageFlags |= 0x00800000;
}

- (id)MAMessageBodyUpdatingFlags:(BOOL)arg1 {
//    NSLog(@"[%@] message body updating flags: %@", [self subject], arg1 ? @"YES" : @"NO");
    id ret = [self MAMessageBodyUpdatingFlags:arg1];
//    NSLog(@"Message Body: %@", ret);
    return ret;
}

- (void)setPGPEncrypted:(BOOL)isPGPEncrypted {
    [self setIvar:@"PGPEncrypted" value:[NSNumber numberWithBool:isPGPEncrypted]];
}

- (BOOL)PGPEncrypted {
    NSNumber *isPGPEncrypted = [self getIvar:@"PGPEncrypted"];
    
    return [isPGPEncrypted boolValue];
}

- (BOOL)PGPSigned {
    NSNumber *isPGPSigned = [self getIvar:@"PGPSigned"];
    
    return [isPGPSigned boolValue];
}

- (void)setPGPSigned:(BOOL)isPGPSigned {
    [self setIvar:@"PGPSigned" value:[NSNumber numberWithBool:isPGPSigned]];
}

- (BOOL)PGPPartlyEncrypted {
    NSNumber *isPGPEncrypted = [self getIvar:@"PGPPartlyEncrypted"];
    return [isPGPEncrypted boolValue];
}


- (void)setPGPPartlyEncrypted:(BOOL)isPGPEncrypted {
    [self setIvar:@"PGPPartlyEncrypted" value:[NSNumber numberWithBool:isPGPEncrypted]];
}

- (BOOL)PGPPartlySigned {
    NSNumber *isPGPSigned = [self getIvar:@"PGPPartlySigned"];
    return [isPGPSigned boolValue];
}

- (void)setPGPPartlySigned:(BOOL)isPGPSigned {
    [self setIvar:@"PGPPartlySigned" value:[NSNumber numberWithBool:isPGPSigned]];
}

- (NSUInteger)numberOfPGPAttachments {
    return [[self getIvar:@"PGPNumberOfPGPAttachments"] integerValue];
}

- (void)setNumberOfPGPAttachments:(NSUInteger)nr {
    [self setIvar:@"PGPNumberOfPGPAttachments" value:[NSNumber numberWithInteger:nr]];
}

- (void)setPGPSignatures:(NSArray *)signatures {
    [self setIvar:@"PGPSignatures" value:signatures];
}

- (NSArray *)PGPSignatures {
    return [self getIvar:@"PGPSignatures"];
}

- (void)setPGPErrors:(NSArray *)errors {
    [self setIvar:@"PGPErrors" value:errors];
}

- (NSArray *)PGPErrors {
    return [self getIvar:@"PGPErrors"];
}

- (void)setPGPAttachments:(NSArray *)attachments {
    [self setIvar:@"PGPAttachments" value:attachments];
}

- (NSArray *)PGPAttachments {
    return [self getIvar:@"PGPAttachments"];
}

- (NSArray *)PGPSignatureLabels {
    // Check if the signature in the message signers is a GPGSignature, if
    // so, copy the email addresses and return them.
    NSMutableArray *signerLabels = [NSMutableArray array];
    NSArray *messageSigners = [self PGPSignatures];
    for(GPGSignature *signature in messageSigners) {
        // For some reason a signature might not have an email set.
        // This happens if the public key is not available (not downloaded or imported
        // from the signature server yet). In that case, display the user id.
        // Also, add an appropriate warning.
        NSString *email = [signature email];
        if(!email)
            email = [NSString stringWithFormat:@"0x%@", [[signature fingerprint] shortKeyID]];
        [signerLabels addObject:email];
    }
    
    return signerLabels;
}

- (BOOL)PGPInfoCollected {
    return [[self getIvar:@"PGPInfoCollected"] boolValue];
}

- (void)setPGPInfoCollected:(BOOL)infoCollected {
    [self setIvar:@"PGPInfoCollected" value:[NSNumber numberWithBool:infoCollected]];
}

- (BOOL)PGPDecrypted {
    return [[self getIvar:@"PGPDecrypted"] boolValue];
}

- (void)setPGPDecrypted:(BOOL)isDecrypted {
    [self setIvar:@"PGPDecrypted" value:[NSNumber numberWithBool:isDecrypted]];
}

- (BOOL)PGPVerified {
    return [[self getIvar:@"PGPVerified"] boolValue];
}

- (void)setPGPVerified:(BOOL)isVerified {
    [self setIvar:@"PGPVerified" value:[NSNumber numberWithBool:isVerified]];
}

- (void)collectPGPInformationStartingWithMimePart:(MimePart *)topPart decryptedBody:(MimeBody *)decryptedBody {
    __block NSInteger numberOfEncryptedAttachments = 0;
    __block BOOL isEncrypted = NO;
    __block BOOL isSigned = NO;
    __block BOOL isPartlyEncrypted = NO;
    __block BOOL isPartlySigned = NO;
    __block NSMutableArray *errors = [NSMutableArray array];
    __block NSMutableArray *signatures = [NSMutableArray array];
    __block NSMutableArray *pgpAttachments = [NSMutableArray array];
    __block BOOL isDecrypted = NO;
    __block BOOL isVerified = NO;
    __block NSUInteger numberOfAttachments = 0;
    // If there's a decrypted message body, its top level part possibly holds information
    // about signatures and errors.
    // Theoretically it could contain encrypted inline data, signed inline data
    // and attachments, but for the time, that's out of scope.
    // This information is added to the message.
    //
    // If there's no decrypted message body, either the message contained
    // PGP inline data or failed to decrypt. In either case, the top part
    // passed in contains all the information.
    //MimePart *informationPart = decryptedBody == nil ? topPart : [decryptedBody topLevelPart];
    [topPart enumerateSubpartsWithBlock:^(MimePart *currentPart) {
        // Only set the flags for non attachment parts to support
        // plain messages with encrypted/signed attachments.
        // Otherwise those would display as signed/encrypted as well.
        if([currentPart isAttachment]) {
            numberOfAttachments++;
            if(currentPart.PGPAttachment)
                [pgpAttachments addObject:currentPart];
        }
        else {
            isEncrypted |= currentPart.PGPEncrypted;
            isSigned |= currentPart.PGPSigned;
            isPartlySigned |= currentPart.PGPPartlySigned;
            isPartlyEncrypted |= currentPart.PGPPartlyEncrypted;
            if(currentPart.PGPError)
                [errors addObject:currentPart.PGPError];
            if([currentPart.PGPSignatures count])
                [signatures addObjectsFromArray:currentPart.PGPSignatures];
            isDecrypted |= currentPart.PGPDecrypted;
            // encrypted & signed & no error = verified.
            // not encrypted & signed & no error = verified.
            isVerified |= currentPart.PGPSigned;
        }
    }];
    
    // This is a normal message, out of here, otherwise
    // this might break a lot of stuff.
    if(!isSigned && !isEncrypted && ![pgpAttachments count])
        return;
    
    if([pgpAttachments count]) {
        self.numberOfPGPAttachments = [pgpAttachments count];
        self.PGPAttachments = pgpAttachments;
    }
    // Set the flags based on the parsed message.
    // Happened before in decrypt bla bla bla, now happens before decodig is finished.
    // Should work better.
    Message *decryptedMessage = nil;
    if(decryptedBody)
        decryptedMessage = [decryptedBody message];
    self.PGPEncrypted = isEncrypted || [decryptedMessage PGPEncrypted];
    self.PGPSigned = isSigned || [decryptedMessage PGPSigned];
    self.PGPPartlyEncrypted = isPartlyEncrypted || [decryptedMessage PGPPartlyEncrypted];
    self.PGPPartlySigned = isPartlySigned || [decryptedMessage PGPPartlySigned];
    [signatures addObjectsFromArray:[decryptedMessage PGPSignatures]];
    self.PGPSignatures = signatures;
    [errors addObjectsFromArray:[decryptedMessage PGPErrors]];
    self.PGPErrors = errors;
    [pgpAttachments addObjectsFromArray:[decryptedMessage PGPAttachments]];
    self.PGPDecrypted = isDecrypted;
    self.PGPVerified = isVerified;
    
    /* Mark a special message. */
    [self setIvar:@"PGPEarlyAlphaFuckedUpEncrypted" value:[decryptedMessage getIvar:@"PGPEarlyAlphaFuckedUpEncrypted"]];
    
    [self fakeMessageFlagsIsEncrypted:self.PGPEncrypted isSigned:self.PGPSigned];
    if(decryptedMessage)
        [decryptedMessage fakeMessageFlagsIsEncrypted:self.PGPEncrypted isSigned:self.PGPSigned];
    
    // Only for test purpose, after the correct error to be displayed should be constructed.
    if([errors count]) {
//        NSLog(@"Current Monitor: %@", [ActivityMonitor currentMonitor]);
//        NSLog(@"Current error: %@", errors);
        [[ActivityMonitor currentMonitor] setError:[errors objectAtIndex:0]];
//        [topPart setDecryptedMessageBody:nil isEncrypted:isEncrypted isSigned:isSigned error:[errors objectAtIndex:0]];
    }
    
    
//    NSLog(@"%@ Decrypted Message [%@]:\n\tisEncrypted: %@, isSigned: %@,\n\tisPartlyEncrypted: %@, isPartlySigned: %@\n\tsignatures: %@\n\terrors: %@",
//          decryptedMessage, [decryptedMessage subject], decryptedMessage.PGPEncrypted ? @"YES" : @"NO", decryptedMessage.PGPSigned ? @"YES" : @"NO",
//          decryptedMessage.PGPPartlyEncrypted ? @"YES" : @"NO", decryptedMessage.PGPPartlySigned ? @"YES" : @"NO", decryptedMessage.PGPSignatures, decryptedMessage.PGPErrors);
//    
//    NSLog(@"%@ Message [%@]:\n\tisEncrypted: %@, isSigned: %@,\n\tisPartlyEncrypted: %@, isPartlySigned: %@\n\tsignatures: %@\n\terrors: %@\n\tattachments: %@",
//          self, [self subject], isEncrypted ? @"YES" : @"NO", isSigned ? @"YES" : @"NO",
//          isPartlyEncrypted ? @"YES" : @"NO", isPartlySigned ? @"YES" : @"NO", signatures, errors, pgpAttachments);
    
#warning Uncomment once number of attachments is implemented.
    // Fix the number of attachments, this time for real!
    // Uncomment once completely implemented.
    [[self messageStore] setNumberOfAttachments:0 isSigned:isSigned isEncrypted:isEncrypted forMessage:self];
    if(decryptedMessage)
        [[decryptedMessage messageStore] setNumberOfAttachments:0 isSigned:isSigned isEncrypted:isEncrypted forMessage:decryptedMessage];
    // Set PGP Info collected so this information is not overwritten.
    self.PGPInfoCollected = YES;
}

- (void)clearPGPInformation {
    [self removeIvars];
}

@end
