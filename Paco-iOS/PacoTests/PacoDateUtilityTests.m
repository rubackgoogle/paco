/* Copyright 2013 Google Inc. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


#import <SenTestingKit/SenTestingKit.h>
#import "PacoDateUtility.h"



@interface PacoDateUtilityTests : SenTestCase

@end



@implementation PacoDateUtilityTests

- (void)setUp
{
  [super setUp];
  // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
  // Put teardown code here; it will be run once, after the last test case.
  [super tearDown];
}

- (void)testDateFromStringWithYearAndDay {
  NSString* testStr = @"2013/10/16";
  NSDate* result = [PacoDateUtility dateFromStringWithYearAndDay:testStr];
  
  NSDateComponents* comp = [[NSDateComponents alloc] init];
  [comp setYear:2013];
  [comp setMonth:10];
  [comp setDay:16];
  NSCalendar* gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
  NSDate* expect = [gregorian dateFromComponents:comp];
  
  STAssertEqualObjects(result, expect, @"should work correctly");
}

- (void)testDateFromStringWithYearAndDay2 {
  NSString* testStr = @"2013/07/25 12:33:22";
  NSDate* result = [PacoDateUtility dateFromStringWithYearAndDay:testStr];
  STAssertEqualObjects(result, nil,
                       @"should result in nil if string doesn't have the expected format");
}

- (void)testDateFromStringWithYearAndDay3 {
  NSString* testStr = @"";
  NSDate* result = [PacoDateUtility dateFromStringWithYearAndDay:testStr];
  STAssertEqualObjects(result, nil, @"should result in nil");
}

- (void)testDateFromStringWithYearAndDay4 {
  NSString* testStr = nil;
  NSDate* result = [PacoDateUtility dateFromStringWithYearAndDay:testStr];
  STAssertEqualObjects(result, nil, @"should result in nil");
}

- (void)testStringWithYearAndDayFromDate {
  NSDateComponents* comp = [[NSDateComponents alloc] init];
  [comp setYear:2013];
  [comp setMonth:10];
  [comp setDay:16];
  NSCalendar* gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
  NSDate* date = [gregorian dateFromComponents:comp];
  
  NSString* result = [PacoDateUtility stringWithYearAndDayFromDate:date];
  STAssertEqualObjects(result, @"2013/10/16",
                       @"should work correctly when the date is a mid night date");
}

- (void)testStringWithYearAndDayFromDate2 {
  NSDateComponents* comp = [[NSDateComponents alloc] init];
  [comp setYear:2013];
  [comp setMonth:10];
  [comp setDay:16];
  [comp setHour:8];
  NSCalendar* gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
  NSDate* date = [gregorian dateFromComponents:comp];
  
  NSString* result = [PacoDateUtility stringWithYearAndDayFromDate:date];
  STAssertEqualObjects(result, @"2013/10/16",
                       @"should get a valid string even if the date is not mid-night date");
}

- (void)testStringWithYearAndDayFromDate3 {
  NSString* result = [PacoDateUtility stringWithYearAndDayFromDate:nil];
  STAssertEqualObjects(result, nil, @"should get a nil string give a nil input");
}






@end
