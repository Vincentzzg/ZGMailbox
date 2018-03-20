//
//  ZGMailMessage.m
//  ZGMailbox
//
//  Created by zzg on 2017/5/11.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import "ZGMailMessage.h"

@implementation ZGMailMessage

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.messageStatus = [decoder decodeIntegerForKey:@"messageStatus"];
    self.failureString = [decoder decodeObjectForKey:@"failureString"];

    self.header = [decoder decodeObjectForKey:@"header"];
    self.bodyText = [decoder decodeObjectForKey:@"bodyText"];
    
    self.attachmentsFilenameArray = [decoder decodeObjectForKey:@"attachmentsFilenameArray"];
    
    self.originImapMessage = [decoder decodeObjectForKey:@"originImapMessage"];
    self.originMessageFolder = [decoder decodeObjectForKey:@"originMessageFolder"];
    self.originMessageParts = [decoder decodeObjectForKey:@"originMessageParts"];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeInteger:self.messageStatus forKey:@"messageStatus"];
    [encoder encodeObject:self.failureString forKey:@"failureString"];

    [encoder encodeObject:self.header forKey:@"header"];
    [encoder encodeObject:self.bodyText forKey:@"bodyText"];
    
    [encoder encodeObject:self.attachmentsFilenameArray forKey:@"attachmentsFilenameArray"];
    
    [encoder encodeObject:self.originImapMessage forKey:@"originImapMessage"];
    [encoder encodeObject:self.originMessageParts forKey:@"originMessageParts"];
    [encoder encodeObject:self.originMessageFolder forKey:@"originMessageFolder"];
}
@end
