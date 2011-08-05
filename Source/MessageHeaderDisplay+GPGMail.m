//
//  MessageHeaderDisplay+GPGMail.m
//  GPGMail
//
//  Created by Lukas Pitschl on 31.07.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <MimePart.h>
#import <MimeBody.h>
#import <NSAttributedString-FontAdditions.h>
#import <MessageHeaderDisplay.h>
#import <MessageViewingState.h>
#import "CCLog.h"
#import "NSObject+LPDynamicIvars.h"
#import "GPGSignatureView.h"
#import "GPGMailBundle.h"
#import "NSAttributedString+GPGMail.h"
#import "MessageHeaderDisplay+GPGMail.h"
#import "MessageContentController+GPGMail.h"

@implementation MessageHeaderDisplay_GPGMail

- (BOOL)MATextView:(id)textView clickedOnLink:(id)link atIndex:(unsigned long long)index {
    if(![link isEqualToString:@"gpgmail://show-signature"] && ![link isEqualToString:@"gpgmail://decrypt"])
        return [self MATextView:textView clickedOnLink:link atIndex:index];
    if([link isEqualToString:@"gpgmail://decrypt"]) {
        [self _decryptMessage];
        return YES;
    }
    if([link isEqualToString:@"gpgmail://show-signature"]) {
        [self _showSignaturePanel];
    }
    return YES;
}

- (void)_showSignaturePanel {
    NSArray *messageSigners = [self getIvar:@"messageSigners"];
    if(![messageSigners count])
        return;
    GPGSignatureView *signatureView = [GPGSignatureView signatureView];
    signatureView.keyList = [[GPGMailBundle sharedInstance] allGPGKeys];
    signatureView.signatures = messageSigners; 
    [signatureView beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSInteger result) {
        DebugLog(@"Signature panel was closed: %d", result);
    }];
}

- (void)_decryptMessage {
    [[[((MessageHeaderDisplay *)self) parentController] parentController] decryptPGPMessage];
}

- (id)MA_attributedStringForSecurityHeader {
    // This is also called if the message is neither signed nor encrypted.
    // In that case the empty string is returned.
    // Internally this method checks the message's messageFlags
    // to determine if the message is signed or encrypted and
    // based on that information creates the encrypted symbol
    // and calls copySingerLabels on the topLevelPart.
    MessageViewingState *viewingState = [((MessageHeaderDisplay *)self) viewingState];
    MimePart *topPart = [[viewingState mimeBody] topLevelPart];
    NSMutableAttributedString *securityHeader = [[self MA_attributedStringForSecurityHeader] mutableCopy];
    // SOOOOO, new stuff has been learned.
    // After checking the message flags the top level part is checked for being signed.
    // After that checking if the message is encrypted. If it is, request the decrypted message
    // body and check again if that body is signed.
    BOOL isSigned = [topPart isSigned];
    BOOL isEncrypted = [topPart isEncrypted];
    char is_encrypted, is_signed;
    NSError *error;
    NSArray *signerLabels = nil; 
    if(isEncrypted) {
        MimeBody *decryptedMessageBody = [topPart decryptedMessageBodyIsEncrypted:&is_encrypted isSigned:&is_signed error:&error];
        MimePart *decryptedTopPart = [decryptedMessageBody topLevelPart];
        // If it's encrypted, only the decrypted part is of interest.
        topPart = decryptedTopPart;
        isSigned = [decryptedTopPart isSigned];
    }
    
    // Only add the encrypted attachment if the message is PGP/MIME encrypted.
    if(!isEncrypted && !isSigned && [securityHeader length] == 0)
        return [securityHeader autorelease];
    if([securityHeader length] != 0 && (isEncrypted || isSigned))
        return [securityHeader autorelease];
    
    [securityHeader release];
    securityHeader = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"\t%@", NSLocalizedStringFromTableInBundle(@"SECURITY_HEADER", @"Encryption", [NSBundle mainBundle], @"")]];
    [securityHeader addAttributes:[NSAttributedString boldGrayHeaderAttributes] range:NSMakeRange(0, [securityHeader length])];
    
    // Add the encrypted part to the security header.
    if(isEncrypted) {
        NSAttributedString *encryptAttachmentString = [NSAttributedString attributedStringWithAttachment:[[[NSTextAttachment alloc] init] autorelease] 
                                                                                                   image:[NSImage imageNamed:@"Encrypted_Glyph"] 
                                                                                                    link:@"gpgmail://decrypt"];
        [securityHeader appendAttributedString:[NSAttributedString attributedStringWithString:@"\t"]];
        [securityHeader appendAttributedString:encryptAttachmentString];
        [securityHeader appendAttributedString:[NSAttributedString attributedStringWithString:NSLocalizedStringFromTableInBundle(@"ENCRYPTED", @"Encryption", [NSBundle mainBundle], @"")]];
    }
    if(isSigned) {
        signerLabels = [topPart copySignerLabels];
        if(![signerLabels count]) {
            DebugLog(@"[DEBUG] %s - this message is supposed to be signed, but no message signers found... HOW IS THIS POSSIBLE?!",
                     __PRETTY_FUNCTION__);
        }
        // Set the message signers on the message header display, so they are available
        // for the signature view.
        NSArray *messageSigners = [topPart copyMessageSigners];
        [self setIvar:@"messageSigners" value:messageSigners];
        [messageSigners release];
        NSAttributedString *signedAttachmentString = [NSAttributedString attributedStringWithAttachment:[[[NSTextAttachment alloc] init] autorelease] 
                                                                                                  image:[NSImage imageNamed:@"Signed_Glyph"] 
                                                                                                   link:@"gpgmail://show-signature"];
        // Only add, if message was encrypted.
        if(isEncrypted)
            [securityHeader appendAttributedString:[NSAttributedString attributedStringWithString:@", "]];
        [securityHeader appendAttributedString:signedAttachmentString];
        NSString *signerLabelsString = [NSString stringWithFormat:@"%@ (%@)", NSLocalizedStringFromTableInBundle(@"SIGNED", 
                                                                                                                 @"Alerts", 
                                                                                                                 [NSBundle mainBundle], @""), 
                                        [signerLabels componentsJoinedByString:@", "]];
        [securityHeader appendAttributedString:[NSAttributedString attributedStringWithString:signerLabelsString]];
        [signerLabels release];
    }
    // And last but not least, add a new line.
    [securityHeader appendAttributedString:[NSAttributedString attributedStringWithString:@"\n"]];
    [viewingState setHeaderSecurityString:securityHeader];
    
    return [securityHeader autorelease];
}

@end
