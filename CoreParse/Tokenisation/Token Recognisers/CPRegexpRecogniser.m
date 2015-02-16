//
//  CPRegexpRecogniser.m
//  CoreParse
//
//  Created by Francis Chong on 1/22/14.
//  Copyright (c) 2014 Ignition Soft. All rights reserved.
//

#import "CPRegexpRecogniser.h"
#import "CPToken.h"
#import "CPKeywordToken.h"

#import "CPQuotedToken.h"

@interface CPRegexpRecogniser()
@property (nonatomic, copy) CPRegexpKeywordRecogniserMatchHandler matchHandler;
@end

@implementation CPRegexpRecogniser

@synthesize regexp;
@synthesize matchHandler;

- (id)initWithRegexp:(NSRegularExpression *)initRegexp matchHandler:(CPRegexpKeywordRecogniserMatchHandler)initMatchHandler
{
    self = [super init];
    if (self) {
        [self setRegexp:initRegexp];
        [self setMatchHandler:initMatchHandler];
    }
    return self;
}

- (id)initWithRegexp:(NSRegularExpression *)initRegexp quoteType:(NSString *)quoteType tokenName:(NSString *)tokenName
{
    self = [super init];
    if (self) {
        [self setRegexp:initRegexp];
        [self setQuoteType:quoteType];
        [self setTokenName:tokenName];
    }
    return self;
}

+ (id)recogniserForRegexp:(NSRegularExpression *)regexp matchHandler:(CPRegexpKeywordRecogniserMatchHandler)initMatchHandler
{
    return [[[self alloc] initWithRegexp:regexp matchHandler:initMatchHandler] autorelease];
}

+ (id)recogniserForRegexp:(NSRegularExpression *)regexp quoteType:(NSString *)quoteType tokenName:(NSString *)tokenName
{
    return [[[self alloc] initWithRegexp:regexp quoteType:quoteType tokenName:tokenName] autorelease];
}

- (void)dealloc
{
    [matchHandler release];
    [regexp release];
    [super dealloc];
}

#pragma mark - NSCoder

#define CPRegexpRecogniserRegexpKey @"R.r"
#define CPRegexpRecogniserQuoteTypeKey  @"R.qt"
#define CPRegexpRecogniserTokenNameKey  @"R.tn"

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    
    if (nil != self)
    {
        [self setRegexp:[aDecoder decodeObjectForKey:CPRegexpRecogniserRegexpKey]];
        [self setQuoteType:[aDecoder decodeObjectForKey:CPRegexpRecogniserQuoteTypeKey]];
        [self setTokenName:[aDecoder decodeObjectForKey:CPRegexpRecogniserTokenNameKey]];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:[self regexp] forKey:CPRegexpRecogniserRegexpKey];
    [aCoder encodeObject:[self quoteType] forKey:CPRegexpRecogniserQuoteTypeKey];
    [aCoder encodeObject:[self tokenName] forKey:CPRegexpRecogniserTokenNameKey];
}

#pragma mark - CPRecognizer

- (CPToken *)recogniseTokenInString:(NSString *)tokenString currentTokenPosition:(NSUInteger *)tokenPosition
{
    long inputLength = [tokenString length];
    NSRange searchRange = NSMakeRange(*tokenPosition, inputLength - *tokenPosition);
    NSTextCheckingResult* result = [[self regexp] firstMatchInString:tokenString options:NSMatchingAnchored range:searchRange];
    if (nil != result && result.range.location == *tokenPosition && result.range.length > 0)
    {
        CPToken *token;
        
        // NOTE: matchHandler does NOT survive deserialisation
        // if you want to serialize, you need to use quoteType and tokenName properties
        // and benefit from the default token creation
        if (nil != matchHandler) {
            token = matchHandler(tokenString, result);
        }
        else {
            NSString *content = [tokenString substringWithRange:result.range];
            token = [[CPQuotedToken alloc] initWithContent:content quoteType:self.quoteType name:self.tokenName];
        }
        
        if (token)
        {
            *tokenPosition = result.range.location + result.range.length;
            return token;
        }
    }
    return nil;
}

@end
