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
#import "PacoScheduleGenerator+ESM.h"
#import "PacoExperimentSchedule.h"
#import "PacoExperiment.h"
#import "PacoExperimentDefinition.h"
#import "PacoDateUtility.h"
#import "NSDate+Paco.h"

@interface PacoScheduleGenerator ()
+ (NSArray*)datesToScheduleForESMExperiment:(PacoExperiment*)experiment
                                 numOfDates:(NSInteger)numOfDates
                                   fromDate:(NSDate*)fromDate;
+ (NSDate*)esmCycleStartDateForSchedule:(PacoExperimentSchedule*)schedule
                    experimentStartDate:(NSDate*)experimentStartDate
                      experimentEndDate:(NSDate*)experimentEndDate
                               fromDate:(NSDate*)fromDate;
+ (NSDate*)nextCycleStartDateForSchedule:(PacoExperimentSchedule*)schedule
                     experimentStartDate:(NSDate*)experimentStartDate
                       experimentEndDate:(NSDate*)experimentEndDate
                          cycleStartDate:(NSDate*)currentStartDate;
+ (NSArray*)generateESMDatesForExperiment:(PacoExperiment*)experiment
                        minimumNumOfDates:(NSUInteger)minimumNumOfDates
                                 fromDate:(NSDate*)fromDate;
+ (NSArray *)createESMScheduleDates:(PacoExperimentSchedule*)experimentSchedule
                     cycleStartDate:(NSDate*)cycleStartDate
                           fromDate:(NSDate*)fromDate
                  experimentEndDate:(NSDate*)experimentEndDate;

@end


/*
 ESM: startDate:11/5/13 endDate:11/12/13
 3 times per day, doesn't include weekend, 9:30am - 5:30pm
 timeout: 479 minutes, minimumBuffer: 120 minutes
 **/
static NSString* testDefinitionJson = @"{\"title\":\"Notification - ESM Daily\",\"description\":\"te\",\"informedConsentForm\":\"This is beer rating data for your personal use.\\n\\nIf you want to share results and see others' ratings email me, bobevans999@gmail.com, and I will share the results of those who want to share with others who express interest.\\n\\nIf you want to share results and see others' ratings email me, bobevans999@gmail.com, and I will share the results of those who want to share with others who express interest.\",\"creator\":\"ymggtest@gmail.com\",\"fixedDuration\":true,\"startDate\":\"2013/11/05\",\"endDate\":\"2013/11/12\",\"id\":10948007,\"questionsChange\":false,\"modifyDate\":\"2013/09/05\",\"inputs\":[{\"id\":3,\"questionType\":\"question\",\"text\":\"hello\",\"mandatory\":false,\"responseType\":\"likert\",\"likertSteps\":9,\"leftSideLabel\":\"q\",\"rightSideLabel\":\"f\",\"name\":\"hello\",\"conditional\":false,\"listChoices\":[],\"invisibleInput\":false}],\"feedback\":[{\"id\":28001,\"feedbackType\":\"display\",\"text\":\"Thanks for Participating!\"}],\"published\":false,\"deleted\":false,\"webRecommended\":false,\"version\":29,\"signalingMechanisms\":[{\"type\":\"signalSchedule\",\"timeout\":479,\"minimumBuffer\":120,\"id\":1,\"scheduleType\":4,\"esmFrequency\":3,\"esmPeriodInDays\":0,\"esmStartHour\":34200000,\"esmEndHour\":63000000,\"times\":[46800000],\"repeatRate\":1,\"weekDaysScheduled\":0,\"nthOfMonth\":1,\"byDayOfMonth\":true,\"dayOfMonth\":1,\"esmWeekends\":false,\"byDayOfWeek\":false}],\"schedule\":{\"type\":\"signalSchedule\",\"timeout\":479,\"minimumBuffer\":120,\"id\":1,\"scheduleType\":4,\"esmFrequency\":3,\"esmPeriodInDays\":0,\"esmStartHour\":34200000,\"esmEndHour\":63000000,\"times\":[46800000],\"repeatRate\":1,\"weekDaysScheduled\":0,\"nthOfMonth\":1,\"byDayOfMonth\":true,\"dayOfMonth\":1,\"esmWeekends\":false,\"byDayOfWeek\":false}}";

@interface PacoScheduleGeneratorDailyESMTests : SenTestCase
@property(nonatomic, strong) NSDateComponents* comp;
@property(nonatomic, strong) NSCalendar* calendar;
@property(nonatomic, strong) PacoExperiment* testExperiment;
@end

@implementation PacoScheduleGeneratorDailyESMTests

- (void)setUp {
  [super setUp];
  // Put setup code here; it will be run once, before the first test case.
  self.comp = [[NSDateComponents alloc] init];
  NSTimeZone* timeZone = [NSTimeZone timeZoneWithName:@"US/Pacific"];
  STAssertNotNil(timeZone, @"timezone should be valid");
  [self.comp setTimeZone:timeZone];
  
  self.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];

  NSError* error = nil;
  NSData* data = [testDefinitionJson dataUsingEncoding:NSUTF8StringEncoding];
  id definitionDict = [NSJSONSerialization JSONObjectWithData:data
                                                      options:NSJSONReadingAllowFragments
                                                        error:&error];
  STAssertTrue(error == nil && [definitionDict isKindOfClass:[NSDictionary class]],
               @"esmExperimentTemplate should be successfully serialized!");
  PacoExperimentDefinition* definition = [PacoExperimentDefinition pacoExperimentDefinitionFromJSON:definitionDict];
  STAssertTrue(definition != nil, @"definition should not be nil!");
  
  PacoExperiment* experimentInstance = [[PacoExperiment alloc] init];
  experimentInstance.schedule = definition.schedule;
  experimentInstance.definition = definition;
  experimentInstance.instanceId = definition.experimentId;
  self.testExperiment = experimentInstance;

}

- (void)tearDown {
  // Put teardown code here; it will be run once, after the last test case.
  self.comp = nil;
  self.testExperiment = nil;
  [super tearDown];
}


/*
 ESM: startDate:11/5/13 endDate:11/12/13
 3 times per day, doesn't include weekend, 9:30am - 5:30pm
 timeout: 479 minutes, minimumBuffer: 120 minutes
 **/
- (void)testDailyDatesToScheduleFixedLengthNoWeekends {
  [self.comp setYear:2013];
  [self.comp setMonth:11];
  [self.comp setDay:1];
  [self.comp setHour:9];
  [self.comp setMinute:35];
  [self.comp setSecond:50];
  NSDate* fromDate = [self.calendar dateFromComponents:self.comp];
  NSArray* dates = [PacoScheduleGenerator datesToScheduleForESMExperiment:self.testExperiment
                                                               numOfDates:60
                                                                 fromDate:fromDate];
  int numOfDays = 12 - 5 + 1; //11/12 is inclusive
  numOfDays -= 2; //doens't include weekends
  STAssertEquals((int)[dates count], 3*numOfDays, @"should generate 18 dates in total");
  
  int minBufferSeconds = 120 * 60;
  NSDate* experimentStartDate = [self.testExperiment startDate];
  NSDate* experimentEndDate = [self.testExperiment endDate];
  
  [self.comp setYear:2013];
  [self.comp setMonth:11];
  [self.comp setDay:5];
  [self.comp setHour:9];
  [self.comp setMinute:30];
  [self.comp setSecond:0];
  NSDate* startTime = [self.calendar dateFromComponents:self.comp];
  [self.comp setHour:17];
  [self.comp setMinute:30];
  [self.comp setSecond:0];
  NSDate* endTime = [self.calendar dateFromComponents:self.comp];

  for (int dayIndex=0; dayIndex<numOfDays; dayIndex++) {
    NSDate* first = [dates objectAtIndex:(dayIndex*3 + 0)];
    NSDate* second = [dates objectAtIndex:(dayIndex*3 + 1)];
    NSDate* third = [dates objectAtIndex:(dayIndex*3 + 2)];
    STAssertTrue([first pacoEarlierThanDate:second] &&
                 [second pacoEarlierThanDate:third], @"should be sorted");
    STAssertTrue([first pacoOnSameDayWithDate:second], @"should be on same day");
    STAssertTrue([third pacoOnSameDayWithDate:second], @"should be on same day");
    STAssertTrue([first pacoLaterThanDate:experimentStartDate] &&
                 [first pacoEarlierThanDate:experimentEndDate] &&
                 [second pacoLaterThanDate:experimentStartDate] &&
                 [second pacoEarlierThanDate:experimentEndDate] &&
                 [third pacoLaterThanDate:experimentStartDate] &&
                 [third pacoEarlierThanDate:experimentEndDate], @"should be valid");
    STAssertTrue(![first pacoIsWeekend] &&
                 ![second pacoIsWeekend] &&
                 ![third pacoIsWeekend], @"shouldn't be weekend");
    
    NSDateComponents* comp = [[NSDateComponents alloc] init];
    int dayOffset = dayIndex;
    if (dayOffset > 3) {
      dayOffset += 2; //skip weekends
    }
    [comp setDay:dayOffset];
    NSDate* startTimeForCurrentDay = [self.calendar dateByAddingComponents:comp toDate:startTime options:0];
    NSDate* endTimeForCurrentDay = [self.calendar dateByAddingComponents:comp toDate:endTime options:0];
    STAssertTrue([first pacoNoEarlierThanDate:startTimeForCurrentDay] &&
                 [first pacoNoLaterThanDate:endTimeForCurrentDay] &&
                 [second pacoNoEarlierThanDate:startTimeForCurrentDay] &&
                 [second pacoNoLaterThanDate:endTimeForCurrentDay] &&
                 [third pacoNoEarlierThanDate:startTimeForCurrentDay] &&
                 [third pacoNoLaterThanDate:endTimeForCurrentDay], @"should be valid");
    
    NSTimeInterval interval = [second timeIntervalSinceDate:first];
    STAssertTrue(interval > 0, @"should be sorted");
    STAssertTrue(interval >= minBufferSeconds, @"should have min buffer");
    
    interval = [third timeIntervalSinceDate:second];
    STAssertTrue(interval > 0, @"should be sorted");
    STAssertTrue(interval >= minBufferSeconds, @"should have min buffer");
  }
}


/*
 ESM: startDate:11/5/13 endDate:11/12/13
 3 times per day, include weekend, 9:30am - 5:30pm
 timeout: 479 minutes, minimumBuffer: 120 minutes
 **/
- (void)testDailyDatesToScheduleFixedLengthWeekends {
  //change schedule to include weekends
  self.testExperiment.schedule.esmWeekends = YES;
  
  //fromDate: 11/1, 9:35:50, 2013, earlier that experiment start date of 11/5/13
  [self.comp setYear:2013];
  [self.comp setMonth:11];
  [self.comp setDay:1];
  [self.comp setHour:9];
  [self.comp setMinute:35];
  [self.comp setSecond:50];
  NSDate* fromDate = [self.calendar dateFromComponents:self.comp];
  NSArray* dates = [PacoScheduleGenerator datesToScheduleForESMExperiment:self.testExperiment
                                                               numOfDates:60
                                                                 fromDate:fromDate];
  int numOfDays = 12 - 5 + 1; //11/12 is inclusive
  STAssertEquals((int)[dates count], 3*numOfDays, @"should generate 24 dates in total");
  
  int minBufferSeconds = 120 * 60;
  NSDate* experimentStartDate = [self.testExperiment startDate];
  NSDate* experimentEndDate = [self.testExperiment endDate];
  
  [self.comp setYear:2013];
  [self.comp setMonth:11];
  [self.comp setDay:5];
  [self.comp setHour:9];
  [self.comp setMinute:30];
  [self.comp setSecond:0];
  NSDate* startTime = [self.calendar dateFromComponents:self.comp];
  [self.comp setHour:17];
  [self.comp setMinute:30];
  [self.comp setSecond:0];
  NSDate* endTime = [self.calendar dateFromComponents:self.comp];
  
  for (int dayIndex=0; dayIndex<numOfDays; dayIndex++) {
    NSDate* first = [dates objectAtIndex:dayIndex*3 + 0];
    NSDate* second = [dates objectAtIndex:dayIndex*3 + 1];
    NSDate* third = [dates objectAtIndex:dayIndex*3 + 2];
    STAssertTrue([first pacoEarlierThanDate:second] &&
                 [second pacoEarlierThanDate:third], @"should be sorted");
    STAssertTrue([first pacoOnSameDayWithDate:second], @"should be on same day");
    STAssertTrue([third pacoOnSameDayWithDate:second], @"should be on same day");
    STAssertTrue([first pacoLaterThanDate:experimentStartDate] &&
                 [first pacoEarlierThanDate:experimentEndDate] &&
                 [second pacoLaterThanDate:experimentStartDate] &&
                 [second pacoEarlierThanDate:experimentEndDate] &&
                 [third pacoLaterThanDate:experimentStartDate] &&
                 [third pacoEarlierThanDate:experimentEndDate], @"should be valid");
    
    NSDateComponents* comp = [[NSDateComponents alloc] init];
    [comp setDay:dayIndex];
    NSDate* startTimeForCurrentDay = [self.calendar dateByAddingComponents:comp toDate:startTime options:0];
    NSDate* endTimeForCurrentDay = [self.calendar dateByAddingComponents:comp toDate:endTime options:0];
    STAssertTrue([first pacoNoEarlierThanDate:startTimeForCurrentDay] &&
                 [first pacoNoLaterThanDate:endTimeForCurrentDay] &&
                 [second pacoNoEarlierThanDate:startTimeForCurrentDay] &&
                 [second pacoNoLaterThanDate:endTimeForCurrentDay] &&
                 [third pacoNoEarlierThanDate:startTimeForCurrentDay] &&
                 [third pacoNoLaterThanDate:endTimeForCurrentDay], @"should be valid");
    
    NSTimeInterval interval = [second timeIntervalSinceDate:first];
    STAssertTrue(interval > 0, @"should be sorted");
    STAssertTrue(interval >= minBufferSeconds, @"should have min buffer");
    
    interval = [third timeIntervalSinceDate:second];
    STAssertTrue(interval > 0, @"should be sorted");
    STAssertTrue(interval >= minBufferSeconds, @"should have min buffer");
  }
}


/*
 ESM: startDate:11/5/13 endDate:11/12/13
 3 times per day, doesn't include weekend, 9:30am - 5:30pm
 timeout: 479 minutes, minimumBuffer: 120 minutes
 **/
- (void)testDailyDatesToScheduleFixedLengthNoWeekendsStartInMiddle {
  //fromDate: 11/8, 17:35:50, 2013, later than experiment start date of 11/5/13
  [self.comp setYear:2013];
  [self.comp setMonth:11];
  [self.comp setDay:8];
  [self.comp setHour:17];
  [self.comp setMinute:35];
  [self.comp setSecond:50];
  NSDate* fromDate = [self.calendar dateFromComponents:self.comp];
  NSArray* dates = [PacoScheduleGenerator datesToScheduleForESMExperiment:self.testExperiment
                                                               numOfDates:60
                                                                 fromDate:fromDate];
  int numOfDays = 2; //11/11, 11/12
  STAssertEquals((int)[dates count], 3*numOfDays, @"should generate 6 dates in total");
  
  int minBufferSeconds = 120 * 60;
  NSDate* experimentStartDate = [self.testExperiment startDate];
  NSDate* experimentEndDate = [self.testExperiment endDate];
  
  [self.comp setYear:2013];
  [self.comp setMonth:11];
  [self.comp setDay:5];
  [self.comp setHour:9];
  [self.comp setMinute:30];
  [self.comp setSecond:0];
  NSDate* startTime = [self.calendar dateFromComponents:self.comp];
  [self.comp setHour:17];
  [self.comp setMinute:30];
  [self.comp setSecond:0];
  NSDate* endTime = [self.calendar dateFromComponents:self.comp];
  
  for (int dayIndex=0; dayIndex<= 1; dayIndex++) {
    NSDate* first = [dates objectAtIndex:dayIndex*3 + 0];
    NSDate* second = [dates objectAtIndex:dayIndex*3 + 1];
    NSDate* third = [dates objectAtIndex:dayIndex*3 + 2];
    STAssertTrue([first pacoEarlierThanDate:second] &&
                 [second pacoEarlierThanDate:third], @"should be sorted");
    STAssertTrue([first pacoOnSameDayWithDate:second], @"should be on same day");
    STAssertTrue([third pacoOnSameDayWithDate:second], @"should be on same day");
    STAssertTrue([first pacoLaterThanDate:experimentStartDate] &&
                 [first pacoEarlierThanDate:experimentEndDate] &&
                 [second pacoLaterThanDate:experimentStartDate] &&
                 [second pacoEarlierThanDate:experimentEndDate] &&
                 [third pacoLaterThanDate:experimentStartDate] &&
                 [third pacoEarlierThanDate:experimentEndDate], @"should be valid");
    STAssertTrue(![first pacoIsWeekend] &&
                 ![second pacoIsWeekend] &&
                 ![third pacoIsWeekend], @"shouldn't be weekend");
    

    NSDateComponents* comp = [[NSDateComponents alloc] init];
    int dayOffset = dayIndex + 6;
    [comp setDay:dayOffset];
    NSDate* startTimeForCurrentDay = [self.calendar dateByAddingComponents:comp toDate:startTime options:0];
    NSDate* endTimeForCurrentDay = [self.calendar dateByAddingComponents:comp toDate:endTime options:0];
    STAssertTrue([first pacoNoEarlierThanDate:startTimeForCurrentDay] &&
                 [first pacoNoLaterThanDate:endTimeForCurrentDay] &&
                 [second pacoNoEarlierThanDate:startTimeForCurrentDay] &&
                 [second pacoNoLaterThanDate:endTimeForCurrentDay] &&
                 [third pacoNoEarlierThanDate:startTimeForCurrentDay] &&
                 [third pacoNoLaterThanDate:endTimeForCurrentDay], @"should be valid");
    
    NSTimeInterval interval = [second timeIntervalSinceDate:first];
    STAssertTrue(interval > 0, @"should be sorted");
    STAssertTrue(interval >= minBufferSeconds, @"should have min buffer");
    
    interval = [third timeIntervalSinceDate:second];
    STAssertTrue(interval > 0, @"should be sorted");
    STAssertTrue(interval >= minBufferSeconds, @"should have min buffer");
  }
}



/*
 ESM: startDate:11/5/13 endDate:11/12/13
 3 times per day, doesn't include weekend, 9:30am - 5:30pm
 timeout: 479 minutes, minimumBuffer: 120 minutes
 **/
- (void)testDailyDatesToScheduleFixedLengthNoWeekendsStartOnSaturday {
  //fromDate: 11/9, 10:35:50, 2013, later than experiment start date of 11/5/13
  [self.comp setYear:2013];
  [self.comp setMonth:11];
  [self.comp setDay:9];
  [self.comp setHour:10];
  [self.comp setMinute:35];
  [self.comp setSecond:50];
  NSDate* fromDate = [self.calendar dateFromComponents:self.comp];
  NSArray* dates = [PacoScheduleGenerator datesToScheduleForESMExperiment:self.testExperiment
                                                               numOfDates:60
                                                                 fromDate:fromDate];
  int numOfDays = 2; //11/11, 11/12
  STAssertEquals((int)[dates count], 3*numOfDays, @"should generate 6 dates in total");
  
  int minBufferSeconds = 120 * 60;
  NSDate* experimentStartDate = [self.testExperiment startDate];
  NSDate* experimentEndDate = [self.testExperiment endDate];
  
  [self.comp setYear:2013];
  [self.comp setMonth:11];
  [self.comp setDay:5];
  [self.comp setHour:9];
  [self.comp setMinute:30];
  [self.comp setSecond:0];
  NSDate* startTime = [self.calendar dateFromComponents:self.comp];
  [self.comp setHour:17];
  [self.comp setMinute:30];
  [self.comp setSecond:0];
  NSDate* endTime = [self.calendar dateFromComponents:self.comp];
  
  for (int dayIndex=0; dayIndex<= 1; dayIndex++) {
    NSDate* first = [dates objectAtIndex:dayIndex*3 + 0];
    NSDate* second = [dates objectAtIndex:dayIndex*3 + 1];
    NSDate* third = [dates objectAtIndex:dayIndex*3 + 2];
    STAssertTrue([first pacoEarlierThanDate:second] &&
                 [second pacoEarlierThanDate:third], @"should be sorted");
    STAssertTrue([first pacoOnSameDayWithDate:second], @"should be on same day");
    STAssertTrue([third pacoOnSameDayWithDate:second], @"should be on same day");
    STAssertTrue([first pacoLaterThanDate:experimentStartDate] &&
                 [first pacoEarlierThanDate:experimentEndDate] &&
                 [second pacoLaterThanDate:experimentStartDate] &&
                 [second pacoEarlierThanDate:experimentEndDate] &&
                 [third pacoLaterThanDate:experimentStartDate] &&
                 [third pacoEarlierThanDate:experimentEndDate], @"should be valid");
    
    STAssertTrue(![first pacoIsWeekend] &&
                 ![second pacoIsWeekend] &&
                 ![third pacoIsWeekend], @"shouldn't be weekend");
    

    NSDateComponents* comp = [[NSDateComponents alloc] init];
    int dayOffset = dayIndex + 6;
    [comp setDay:dayOffset];
    NSDate* startTimeForCurrentDay = [self.calendar dateByAddingComponents:comp toDate:startTime options:0];
    NSDate* endTimeForCurrentDay = [self.calendar dateByAddingComponents:comp toDate:endTime options:0];
    STAssertTrue([first pacoNoEarlierThanDate:startTimeForCurrentDay] &&
                 [first pacoNoLaterThanDate:endTimeForCurrentDay] &&
                 [second pacoNoEarlierThanDate:startTimeForCurrentDay] &&
                 [second pacoNoLaterThanDate:endTimeForCurrentDay] &&
                 [third pacoNoEarlierThanDate:startTimeForCurrentDay] &&
                 [third pacoNoLaterThanDate:endTimeForCurrentDay], @"should be valid");

    
    NSTimeInterval interval = [second timeIntervalSinceDate:first];
    STAssertTrue(interval > 0, @"should be sorted");
    STAssertTrue(interval >= minBufferSeconds, @"should have min buffer");
    
    interval = [third timeIntervalSinceDate:second];
    STAssertTrue(interval > 0, @"should be sorted");
    STAssertTrue(interval >= minBufferSeconds, @"should have min buffer");
  }
}


/*
 ESM: startDate:11/5/13 endDate:11/12/13
 3 times per day, doesn't include weekend, 9:30am - 5:30pm
 timeout: 479 minutes, minimumBuffer: 120 minutes
 **/
- (void)testDailyDatesToScheduleFixedLengthNoWeekendsStartOnSunday {
  //fromDate: 11/10, 10:35:50, 2013, later than experiment start date of 11/5/13
  [self.comp setYear:2013];
  [self.comp setMonth:11];
  [self.comp setDay:10];
  [self.comp setHour:10];
  [self.comp setMinute:35];
  [self.comp setSecond:50];
  NSDate* fromDate = [self.calendar dateFromComponents:self.comp];
  NSArray* dates = [PacoScheduleGenerator datesToScheduleForESMExperiment:self.testExperiment
                                                               numOfDates:60
                                                                 fromDate:fromDate];
  int numOfDays = 2; //11/11, 11/12
  STAssertEquals((int)[dates count], 3*numOfDays, @"should generate 6 dates in total");
  
  int minBufferSeconds = 120 * 60;
  NSDate* experimentStartDate = [self.testExperiment startDate];
  NSDate* experimentEndDate = [self.testExperiment endDate];
  
  [self.comp setYear:2013];
  [self.comp setMonth:11];
  [self.comp setDay:5];
  [self.comp setHour:9];
  [self.comp setMinute:30];
  [self.comp setSecond:0];
  NSDate* startTime = [self.calendar dateFromComponents:self.comp];
  [self.comp setHour:17];
  [self.comp setMinute:30];
  [self.comp setSecond:0];
  NSDate* endTime = [self.calendar dateFromComponents:self.comp];
  
  for (int dayIndex=0; dayIndex<= 1; dayIndex++) {
    NSDate* first = [dates objectAtIndex:dayIndex*3 + 0];
    NSDate* second = [dates objectAtIndex:dayIndex*3 + 1];
    NSDate* third = [dates objectAtIndex:dayIndex*3 + 2];
    STAssertTrue([first pacoEarlierThanDate:second] &&
                 [second pacoEarlierThanDate:third], @"should be sorted");
    STAssertTrue([first pacoOnSameDayWithDate:second], @"should be on same day");
    STAssertTrue([third pacoOnSameDayWithDate:second], @"should be on same day");
    STAssertTrue([first pacoLaterThanDate:experimentStartDate] &&
                 [first pacoEarlierThanDate:experimentEndDate] &&
                 [second pacoLaterThanDate:experimentStartDate] &&
                 [second pacoEarlierThanDate:experimentEndDate] &&
                 [third pacoLaterThanDate:experimentStartDate] &&
                 [third pacoEarlierThanDate:experimentEndDate], @"should be valid");
    STAssertTrue(![first pacoIsWeekend] &&
                 ![second pacoIsWeekend] &&
                 ![third pacoIsWeekend], @"shouldn't be weekend");
    

    NSDateComponents* comp = [[NSDateComponents alloc] init];
    int dayOffset = dayIndex + 6;
    [comp setDay:dayOffset];
    NSDate* startTimeForCurrentDay = [self.calendar dateByAddingComponents:comp toDate:startTime options:0];
    NSDate* endTimeForCurrentDay = [self.calendar dateByAddingComponents:comp toDate:endTime options:0];
    STAssertTrue([first pacoNoEarlierThanDate:startTimeForCurrentDay] &&
                 [first pacoNoLaterThanDate:endTimeForCurrentDay] &&
                 [second pacoNoEarlierThanDate:startTimeForCurrentDay] &&
                 [second pacoNoLaterThanDate:endTimeForCurrentDay] &&
                 [third pacoNoEarlierThanDate:startTimeForCurrentDay] &&
                 [third pacoNoLaterThanDate:endTimeForCurrentDay], @"should be valid");
    
    NSTimeInterval interval = [second timeIntervalSinceDate:first];
    STAssertTrue(interval > 0, @"should be sorted");
    STAssertTrue(interval >= minBufferSeconds, @"should have min buffer");
    
    interval = [third timeIntervalSinceDate:second];
    STAssertTrue(interval > 0, @"should be sorted");
    STAssertTrue(interval >= minBufferSeconds, @"should have min buffer");
  }
}


/*
 ESM: startDate:11/5/13 endDate:11/12/13
 3 times per day, doesn't include weekend, 9:30am - 5:30pm
 timeout: 479 minutes, minimumBuffer: 120 minutes
 **/
- (void)testDailyDatesToScheduleFixedLengthNoWeekendsStartOnEarlyMonday {
  //fromDate: 11/11, 8:35:50, 2013, later than experiment start date of 11/5/13
  [self.comp setYear:2013];
  [self.comp setMonth:11];
  [self.comp setDay:11];
  [self.comp setHour:8];
  [self.comp setMinute:35];
  [self.comp setSecond:50];
  NSDate* fromDate = [self.calendar dateFromComponents:self.comp];
  NSArray* dates = [PacoScheduleGenerator datesToScheduleForESMExperiment:self.testExperiment
                                                               numOfDates:60
                                                                 fromDate:fromDate];
  int numOfDays = 2; //11/11, 11/12
  STAssertEquals((int)[dates count], 3*numOfDays, @"should generate 6 dates in total");
  
  int minBufferSeconds = 120 * 60;
  NSDate* experimentStartDate = [self.testExperiment startDate];
  NSDate* experimentEndDate = [self.testExperiment endDate];
  
  [self.comp setYear:2013];
  [self.comp setMonth:11];
  [self.comp setDay:5];
  [self.comp setHour:9];
  [self.comp setMinute:30];
  [self.comp setSecond:0];
  NSDate* startTime = [self.calendar dateFromComponents:self.comp];
  [self.comp setHour:17];
  [self.comp setMinute:30];
  [self.comp setSecond:0];
  NSDate* endTime = [self.calendar dateFromComponents:self.comp];
  
  for (int dayIndex=0; dayIndex<= 1; dayIndex++) {
    NSDate* first = [dates objectAtIndex:dayIndex*3 + 0];
    NSDate* second = [dates objectAtIndex:dayIndex*3 + 1];
    NSDate* third = [dates objectAtIndex:dayIndex*3 + 2];
    STAssertTrue([first pacoEarlierThanDate:second] &&
                 [second pacoEarlierThanDate:third], @"should be sorted");
    STAssertTrue([first pacoOnSameDayWithDate:second], @"should be on same day");
    STAssertTrue([third pacoOnSameDayWithDate:second], @"should be on same day");
    STAssertTrue([first pacoLaterThanDate:experimentStartDate] &&
                 [first pacoEarlierThanDate:experimentEndDate] &&
                 [second pacoLaterThanDate:experimentStartDate] &&
                 [second pacoEarlierThanDate:experimentEndDate] &&
                 [third pacoLaterThanDate:experimentStartDate] &&
                 [third pacoEarlierThanDate:experimentEndDate], @"should be valid");
    STAssertTrue(![first pacoIsWeekend] &&
                 ![second pacoIsWeekend] &&
                 ![third pacoIsWeekend], @"shouldn't be weekend");
    

    NSDateComponents* comp = [[NSDateComponents alloc] init];
    int dayOffset = dayIndex + 6;
    [comp setDay:dayOffset];
    NSDate* startTimeForCurrentDay = [self.calendar dateByAddingComponents:comp toDate:startTime options:0];
    NSDate* endTimeForCurrentDay = [self.calendar dateByAddingComponents:comp toDate:endTime options:0];
    STAssertTrue([first pacoNoEarlierThanDate:startTimeForCurrentDay] &&
                 [first pacoNoLaterThanDate:endTimeForCurrentDay] &&
                 [second pacoNoEarlierThanDate:startTimeForCurrentDay] &&
                 [second pacoNoLaterThanDate:endTimeForCurrentDay] &&
                 [third pacoNoEarlierThanDate:startTimeForCurrentDay] &&
                 [third pacoNoLaterThanDate:endTimeForCurrentDay], @"should be valid");
    
    NSTimeInterval interval = [second timeIntervalSinceDate:first];
    STAssertTrue(interval > 0, @"should be sorted");
    STAssertTrue(interval >= minBufferSeconds, @"should have min buffer");
    
    interval = [third timeIntervalSinceDate:second];
    STAssertTrue(interval > 0, @"should be sorted");
    STAssertTrue(interval >= minBufferSeconds, @"should have min buffer");
  }
}


/*
 ESM: startDate:11/5/13 endDate:11/12/13
 3 times per day, include weekend, 9:30am - 5:30pm
 timeout: 479 minutes, minimumBuffer: 120 minutes
 **/
- (void)testDailyDatesToScheduleFixedLengthStartLate {
  //fromDate: 11/12, 17:35:50, 2013
  [self.comp setYear:2013];
  [self.comp setMonth:11];
  [self.comp setDay:12];
  [self.comp setHour:17];
  [self.comp setMinute:35];
  [self.comp setSecond:50];
  NSDate* fromDate = [self.calendar dateFromComponents:self.comp];
  NSArray* dates = [PacoScheduleGenerator datesToScheduleForESMExperiment:self.testExperiment
                                                               numOfDates:60
                                                                 fromDate:fromDate];
  STAssertNil(dates, @"shouldn't generate any dates");
}


/*
 ESM: ongoing
 3 times per day, doesn't include weekend, 9:30am - 5:30pm
 timeout: 479 minutes, minimumBuffer: 120 minutes
 **/
- (void)testDailyDatesToScheduleOngingNoWeekends {
  [self.testExperiment.definition setValue:nil forKey:@"startDate"];
  [self.testExperiment.definition setValue:nil forKey:@"endDate"];
  STAssertNil([self.testExperiment startDate], @"should be nil");
  STAssertNil([self.testExperiment endDate], @"should be nil");
  
  //fromDate: thurs, 10/31, 9:20:50, 2013
  [self.comp setYear:2013];
  [self.comp setMonth:10];
  [self.comp setDay:31];
  [self.comp setHour:9];
  [self.comp setMinute:20];
  [self.comp setSecond:50];
  NSDate* fromDate = [self.calendar dateFromComponents:self.comp];
  int numOfDates = 8;
  NSArray* dates = [PacoScheduleGenerator datesToScheduleForESMExperiment:self.testExperiment
                                                               numOfDates:numOfDates
                                                                 fromDate:fromDate];
  STAssertEquals((int)[dates count], numOfDates, @"should generate 8 dates in total");
  
  [self.comp setYear:2013];
  [self.comp setMonth:10];
  [self.comp setDay:31];
  [self.comp setHour:9];
  [self.comp setMinute:30];
  [self.comp setSecond:0];
  NSDate* startTime = [self.calendar dateFromComponents:self.comp];
  [self.comp setHour:17];
  [self.comp setMinute:30];
  [self.comp setSecond:0];
  NSDate* endTime = [self.calendar dateFromComponents:self.comp];
  
  int minBufferSeconds = 120 * 60;
  for (int dayIndex=0; dayIndex<3; dayIndex++) {
    NSDate* first = [dates objectAtIndex:dayIndex*3 + 0];
    NSDate* second = [dates objectAtIndex:dayIndex*3 + 1];
    NSDate* third = nil;
    if (dayIndex < 2) {
      third = [dates objectAtIndex:dayIndex*3 + 2];
    }
    STAssertTrue([first pacoOnSameDayWithDate:second], @"should be on same day");
    STAssertTrue([first pacoEarlierThanDate:second], @"should be sorted");

    if (third) {
      STAssertTrue([third pacoOnSameDayWithDate:second], @"should be on same day");
      STAssertTrue([second pacoEarlierThanDate:third], @"should be sorted");
    }
    
    NSDateComponents* comp = [[NSDateComponents alloc] init];
    //dayOffset: 0, 1, 4
    int dayOffset = dayIndex;
    if (dayOffset == 2) {
      dayOffset = 4; //skip weekends
    }
    [comp setDay:dayOffset];
    NSDate* startTimeForCurrentDay = [self.calendar dateByAddingComponents:comp toDate:startTime options:0];
    NSDate* endTimeForCurrentDay = [self.calendar dateByAddingComponents:comp toDate:endTime options:0];
    STAssertTrue([first pacoNoEarlierThanDate:startTimeForCurrentDay] &&
                 [first pacoNoLaterThanDate:endTimeForCurrentDay] &&
                 [second pacoNoEarlierThanDate:startTimeForCurrentDay] &&
                 [second pacoNoLaterThanDate:endTimeForCurrentDay], @"should be valid");
    STAssertTrue(![first pacoIsWeekend] &&
                 ![second pacoIsWeekend], @"shouldn't be weekend");
    

    if (third) {
      STAssertTrue([third pacoNoEarlierThanDate:startTimeForCurrentDay] &&
                   [third pacoNoLaterThanDate:endTimeForCurrentDay], @"should be valid");
      STAssertTrue(![third pacoIsWeekend], @"shouldn't be weekend");
    }
    
    NSTimeInterval interval = [second timeIntervalSinceDate:first];
    STAssertTrue(interval > 0, @"should be sorted");
    STAssertTrue(interval >= minBufferSeconds, @"should have min buffer");
    if (third) {
      interval = [third timeIntervalSinceDate:second];
      STAssertTrue(interval > 0, @"should be sorted");
      STAssertTrue(interval >= minBufferSeconds, @"should have min buffer");
    }
  }
}


- (void)testEsmCycleStartDateForSchedule {
  STFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}

- (void)testNextCycleStartDateForSchedule {
  STFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}

- (void)testGenerateESMDatesForExperiment {
  STFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}

- (void)testCreateESMScheduleDates {
  STFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}

- (void)testEsmCycleStartDateFromScheduledDate {
  STFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}

- (void)testLaterCycleThan {
  STFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}
@end
