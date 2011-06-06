// 
// Copyright (c) 2010 Eric Czarny <eczarny@gmail.com>
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of  this  software  and  associated documentation files (the "Software"), to
// deal  in  the Software without restriction, including without limitation the
// rights  to  use,  copy,  modify,  merge,  publish,  distribute,  sublicense,
// and/or sell copies  of  the  Software,  and  to  permit  persons to whom the
// Software is furnished to do so, subject to the following conditions:
// 
// The  above  copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE  SOFTWARE  IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED,  INCLUDING  BUT  NOT  LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS  OR  COPYRIGHT  HOLDERS  BE  LIABLE  FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY,  WHETHER  IN  AN  ACTION  OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.
// 

#import "XMLRPCEventBasedParserDelegate.h"
#import "NSDataAdditions.h"

@interface XMLRPCEventBasedParserDelegate (XMLRPCEventBasedParserDelegatePrivate)

- (BOOL)isDictionaryElementType: (XMLRPCElementType)elementType;

#pragma mark -

- (void)addElementValueToParent;

#pragma mark -

- (NSDate *)parseDateString: (NSString *)dateString withFormat: (NSString *)format;

#pragma mark -

- (NSNumber *)parseInteger: (NSString *)value;

- (NSNumber *)parseLong: (NSString *)value;

- (NSNumber *)parseDouble: (NSString *)value;

- (NSNumber *)parseBoolean: (NSString *)value;

- (NSString *)parseString: (NSString *)value;

- (NSDate *)parseDate: (NSString *)value;

- (NSData *)parseData: (NSString *)value;

@end

#pragma mark -

@implementation XMLRPCEventBasedParserDelegate

- (id)initWithParent: (XMLRPCEventBasedParserDelegate *)parent {
    self = [super init];
    if (self) {
        myParent = parent;
        myChildren = [[NSMutableArray alloc] initWithCapacity: 1];
        myElementType = XMLRPCElementTypeString;
        myElementKey = nil;
        myElementValue = [[NSMutableString alloc] init];
    }
    
    return self;
}

#pragma mark -

- (void)setParent: (XMLRPCEventBasedParserDelegate *)parent {
    [parent retain];
    
    [myParent release];
    
    myParent = parent;
}

- (XMLRPCEventBasedParserDelegate *)parent {
    return myParent;
}

#pragma mark -

- (void)setElementType: (XMLRPCElementType)elementType {
    myElementType = elementType;
}

- (XMLRPCElementType)elementType {
    return myElementType;
}

#pragma mark -

- (void)setElementKey: (NSString *)elementKey {
    [elementKey retain];
    
    [myElementKey release];
    
    myElementKey = elementKey;
}

- (NSString *)elementKey {
    return myElementKey;
}

#pragma mark -

- (void)setElementValue: (id)elementValue {
    [elementValue retain];
    
    [myElementValue release];
    
    myElementValue = elementValue;
}

- (id)elementValue {
    return myElementValue;
}

#pragma mark -

- (void)dealloc {
    [myChildren release];
    [myElementKey release];
    [myElementValue release];
    
    [super dealloc];
}

@end

#pragma mark -

@implementation XMLRPCEventBasedParserDelegate (NSXMLParserDelegate)

- (void)parser: (NSXMLParser *)parser didStartElement: (NSString *)element namespaceURI: (NSString *)namespaceURI qualifiedName: (NSString *)qualifiedName attributes: (NSDictionary *)attributes {
    if ([element isEqualToString: @"value"] || [element isEqualToString: @"member"] || [element isEqualToString: @"name"]) {
        XMLRPCEventBasedParserDelegate *parserDelegate = [[XMLRPCEventBasedParserDelegate alloc] initWithParent: self];
        
        if ([element isEqualToString: @"member"]) {
            [parserDelegate setElementType: XMLRPCElementTypeMember];
        } else if ([element isEqualToString: @"name"]) {
            [parserDelegate setElementType: XMLRPCElementTypeName];
        }
        
        [myChildren addObject: parserDelegate];
        
        [parser setDelegate: parserDelegate];
        
        [parserDelegate release];
        
        return;
    }
    
    if ([element isEqualToString: @"array"]) {
        NSMutableArray *array = [[NSMutableArray alloc] init];
        
        [self setElementValue: array];
        
        [array release];
        
        [self setElementType: XMLRPCElementTypeArray];
    } else if ([element isEqualToString: @"struct"]) {
        NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
        
        [self setElementValue: dictionary];
        
        [dictionary release];
        
        [self setElementType: XMLRPCElementTypeDictionary];
    } else if ([element isEqualToString: @"int"] || [element isEqualToString: @"i4"]) {
        [self setElementType: XMLRPCElementTypeInteger];
    } else if ([element isEqualToString: @"i8"]) {
        [self setElementType: XMLRPCElementTypeLong];
    } else if ([element isEqualToString: @"double"]) {
        [self setElementType: XMLRPCElementTypeDouble];
    } else if ([element isEqualToString: @"boolean"]) {
        [self setElementType: XMLRPCElementTypeBoolean];
    } else if ([element isEqualToString: @"string"]) {
        [self setElementType: XMLRPCElementTypeString];
    } else if ([element isEqualToString: @"dateTime.iso8601"]) {
        [self setElementType: XMLRPCElementTypeDate];
    } else if ([element isEqualToString: @"base64"]) {
        [self setElementType: XMLRPCElementTypeData];
    }
}

- (void)parser: (NSXMLParser *)parser didEndElement: (NSString *)element namespaceURI: (NSString *)namespaceURI qualifiedName: (NSString *)qualifiedName {
    if ([element isEqualToString: @"value"] || [element isEqualToString: @"member"] || [element isEqualToString: @"name"]) {
        NSString *elementValue = nil;
        
        if ((myElementType != XMLRPCElementTypeArray) && ![self isDictionaryElementType: myElementType]) {
            elementValue = [self parseString: myElementValue];
            
            [myElementValue release];
            
            myElementValue = nil;
        }
        
        switch (myElementType) {
            case XMLRPCElementTypeInteger:
                myElementValue = [self parseInteger: elementValue];
                
                [myElementValue retain];
                
                break;
            case XMLRPCElementTypeLong:
                myElementValue = [self parseLong: elementValue];
                
                [myElementValue retain];
                
                break;
            case XMLRPCElementTypeDouble:
                myElementValue = [self parseDouble: elementValue];
                
                [myElementValue retain];
                
                break;
            case XMLRPCElementTypeBoolean:
                myElementValue = [self parseBoolean: elementValue];
                
                [myElementValue retain];
                
                break;
            case XMLRPCElementTypeString:
            case XMLRPCElementTypeName:
                myElementValue = elementValue;
                
                [myElementValue retain];
                
                break;
            case XMLRPCElementTypeDate:
                myElementValue = [self parseDate: elementValue];
                
                [myElementValue retain];
                
                break;
            case XMLRPCElementTypeData:
                myElementValue = [self parseData: elementValue];
                
                [myElementValue retain];
                
                break;
            default:
                break;
        }
        
        if (myParent) {
            [self addElementValueToParent];
        }
        
        [parser setDelegate: myParent];
    }
}

- (void)parser: (NSXMLParser *)parser foundCharacters: (NSString *)string {
    if ((myElementType == XMLRPCElementTypeArray) || [self isDictionaryElementType: myElementType]) {
        return;
    }
    
    if (!myElementValue) {
        myElementValue = [[NSMutableString alloc] initWithString: string];
    } else {
        [myElementValue appendString: string];
    }
}

- (void)parser: (NSXMLParser *)parser parseErrorOccurred: (NSError *)parseError {
    [parser abortParsing];
}

@end

#pragma mark -

@implementation XMLRPCEventBasedParserDelegate (XMLRPCEventBasedParserDelegatePrivate)

- (BOOL)isDictionaryElementType: (XMLRPCElementType)elementType {
    if ((myElementType == XMLRPCElementTypeDictionary) || (myElementType == XMLRPCElementTypeMember)) {
        return YES;
    }
    
    return NO;
}

#pragma mark -

- (void)addElementValueToParent {
    id parentElementValue = [myParent elementValue];
    
    switch ([myParent elementType]) {
        case XMLRPCElementTypeArray:
            [parentElementValue addObject: myElementValue];
            
            break;
        case XMLRPCElementTypeDictionary:
            [parentElementValue setObject: myElementValue forKey: myElementKey];
            
            break;
        case XMLRPCElementTypeMember:
            if (myElementType == XMLRPCElementTypeName) {
                [myParent setElementKey: myElementValue];
            } else {
                [myParent setElementValue: myElementValue];
            }
            
            break;
        default:
            break;
    }
}

#pragma mark -

- (NSDate *)parseDateString: (NSString *)dateString withFormat: (NSString *)format {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSDate *result = nil;
    
    [dateFormatter setDateFormat: format];
    
    result = [dateFormatter dateFromString: dateString];
    
    [dateFormatter release];
    
    return result;
}

#pragma mark -

- (NSNumber *)parseInteger: (NSString *)value {
    return [NSNumber numberWithInteger: [value integerValue]];
}

- (NSNumber *)parseLong: (NSString *)value {
    return [NSNumber numberWithLongLong: [value longLongValue]];
}

- (NSNumber *)parseDouble: (NSString *)value {
    return [NSNumber numberWithDouble: [value doubleValue]];
}

- (NSNumber *)parseBoolean: (NSString *)value {
    if ([value isEqualToString: @"1"]) {
        return [NSNumber numberWithBool: YES];
    }
    
    return [NSNumber numberWithBool: NO];
}

- (NSString *)parseString: (NSString *)value {
    return [value stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSDate *)parseDate: (NSString *)value {
    NSDate *result = nil;
    
    result = [self parseDateString: value withFormat: @"yyyyMMdd'T'HH:mm:ss"];
    
    if (!result) {
        result = [self parseDateString: value withFormat: @"yyyy'-'MM'-'dd'T'HH:mm:ss"];
    }
    
    return result;
}

- (NSData *)parseData: (NSString *)value {
    return [NSData base64DataFromString: value];
}

@end
