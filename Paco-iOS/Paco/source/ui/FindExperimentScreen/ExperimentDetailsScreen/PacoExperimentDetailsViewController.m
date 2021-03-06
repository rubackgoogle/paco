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

#import "PacoExperimentDetailsViewController.h"

#import "PacoColor.h"
#import "PacoFont.h"
#import "PacoConsentViewController.h"
#import "PacoModel.h"
#import "PacoExperimentDefinition.h"
#import "PacoClient.h"
#import "PacoDateUtility.h"

@interface PacoExperimentDetailsViewController ()
@property (nonatomic, retain) PacoExperimentDefinition *experiment;
@end

@implementation PacoExperimentDetailsViewController
@synthesize experiment = _experiment;


+ (NSString *)stringFromData:(NSData *)data {
  const char *bytes = [data bytes];
  char *dst = malloc([data length] + 1);
  memset(dst, 0, [data length] + 1);
  memcpy(dst, bytes, [data length]);
  NSString *converted = [NSString stringWithUTF8String:dst];
  free(dst);
  return converted;
}

+(PacoExperimentDetailsViewController*)controllerWithExperiment:(PacoExperimentDefinition *)experiment {
  PacoExperimentDetailsViewController* controller =
      [[PacoExperimentDetailsViewController alloc] initWithNibName:nil bundle:nil];
  controller.experiment = experiment;
  controller.navigationItem.title = experiment.title;
  return controller;
}

- (NSString *)jsonStringFromObj:(id)jsonObject {
  NSError *jsonError = nil;
  NSData *jsonData =
      [NSJSONSerialization dataWithJSONObject:jsonObject
                                      options:NSJSONWritingPrettyPrinted
                                        error:&jsonError];
  if (jsonError) {
    return nil;
  }
  return [[self class] stringFromData:jsonData];
}

- (void)viewDidLoad {
  [super viewDidLoad];

  if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
    self.edgesForExtendedLayout = UIRectEdgeNone;
  }
  self.view.backgroundColor = [PacoColor pacoBackgroundWhite];
  
  UILabel* titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  NSString* labelText = self.experiment.title;
  titleLabel.text = labelText;
  titleLabel.font = [PacoFont pacoTableCellFont];
  titleLabel.textColor = [PacoColor pacoDarkBlue];
  titleLabel.backgroundColor = [UIColor clearColor];
  titleLabel.numberOfLines = 0;
  [self.view addSubview:titleLabel];
  CGRect frame = titleLabel.frame;
  frame.origin.x = 10;
  frame.origin.y = 10;
  frame.size.width = self.view.frame.size.width - 20;
  frame.size.height = self.view.frame.size.height;
  titleLabel.frame = frame;
  [titleLabel sizeToFit];

  UILabel* desLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, titleLabel.frame.origin.y+titleLabel.frame.size.height + 10, self.view.frame.size.width - 20, 20)];
  NSString* desText = @"Description:";
  desLabel.text = desText;
  desLabel.font = [PacoFont pacoNormalButtonFont];
  desLabel.textColor = [PacoColor pacoDarkBlue];
  desLabel.backgroundColor = [UIColor clearColor];
  desLabel.numberOfLines = 0;
  [self.view addSubview:desLabel];

  UITextView *descriptionLabel = [[UITextView alloc] initWithFrame:CGRectMake(10, desLabel.frame.origin.y + 30, self.view.frame.size.width - 20, 140)];
  descriptionLabel.backgroundColor=[UIColor clearColor];
  descriptionLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:16];
  descriptionLabel.textColor = [PacoColor pacoDarkBlue];
  descriptionLabel.text = self.experiment.experimentDescription;
  descriptionLabel.editable = NO;
  [self.view addSubview:descriptionLabel];

  int yPosition = descriptionLabel.frame.origin.y + descriptionLabel.frame.size.height + 20;
  
  if (self.experiment.startDate) {
    UILabel* dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, yPosition, 300, 20)];
    dateLabel.text = @"Start Date:                 End Date:";
    dateLabel.font = [PacoFont pacoNormalButtonFont];
    dateLabel.textColor = [PacoColor pacoDarkBlue];
    dateLabel.backgroundColor = [UIColor clearColor];
    dateLabel.numberOfLines = 0 ;
    [self.view addSubview:dateLabel];
    yPosition = dateLabel.frame.origin.y + dateLabel.frame.size.height + 10;
    
    NSString* startDate = [PacoDateUtility stringWithYearAndDayFromDate:self.experiment.startDate];
    UILabel* dateText = [[UILabel alloc] initWithFrame:CGRectMake(10, yPosition, 300, 20)];
    dateText.text = [NSString stringWithFormat:@"%@               %@",
                     startDate,
                     self.experiment.inclusiveEndDateString];
    dateText.font = [UIFont fontWithName:@"HelveticaNeue" size:16];
    dateText.textColor = [PacoColor pacoDarkBlue];
    dateText.backgroundColor = [UIColor clearColor];
    dateText.numberOfLines = 0 ;
    [self.view addSubview:dateText];
    yPosition = dateText.frame.origin.y + dateText.frame.size.height + 20;
  }

  UILabel* creatorLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, yPosition, self.view.frame.size.width - 20, 20)];
  NSString* creText = @"Creator:";
  creatorLabel.text = creText;
  creatorLabel.font = [PacoFont pacoNormalButtonFont];
  creatorLabel.textColor = [PacoColor pacoDarkBlue];
  creatorLabel.backgroundColor = [UIColor clearColor];
  creatorLabel.numberOfLines = 0;
  [self.view addSubview:creatorLabel];

  UILabel* creatorValueLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  NSString* creatorText = self.experiment.creator;
  creatorValueLabel.text = creatorText;
  creatorValueLabel.font = [PacoFont pacoTableCellDetailFont];
  creatorValueLabel.textColor = [PacoColor pacoDarkBlue];
  creatorValueLabel.backgroundColor = [UIColor clearColor];
  creatorValueLabel.numberOfLines = 0;
  [self.view addSubview:creatorValueLabel];
  CGRect creatorframe = creatorValueLabel.frame;
  creatorframe.origin.x = 10;
  creatorframe.origin.y = creatorLabel.frame.origin.y + 30;
  creatorframe.size.width = self.view.frame.size.width - 20;
  creatorframe.size.height = self.view.frame.size.height;
  creatorValueLabel.frame = creatorframe;
  [creatorValueLabel sizeToFit];

  UIButton* join = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  [join setTitle:@"Join this Experiment" forState:UIControlStateNormal];
  if (IS_IOS_7) {
    join.titleLabel.font = [PacoFont pacoNormalButtonFont];
  }
  [join addTarget:self action:@selector(onJoin) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:join];
  [join sizeToFit];
  CGRect  joinframe = join.frame;
  joinframe.origin.x = (self.view.frame.size.width - join.frame.size.width) / 2;
  joinframe.origin.y = self.view.frame.size.height - 65 - self.navigationController.navigationBar.frame.size.height;
  join.frame = joinframe;
}

- (void)onJoin {
  BOOL joined = [[PacoClient sharedInstance] hasJoinedExperimentWithId:self.experiment.experimentId];
  if (joined) {
    [[[UIAlertView alloc] initWithTitle:@"Congratulations!"
                                message:@"You have joined this experiment,\n"
                                         "Check it out in Current Experiments."
                               delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    return;
  }
  
  PacoConsentViewController *consent =
      [PacoConsentViewController controllerWithDefinition:self.experiment];
  [self.navigationController pushViewController:consent animated:YES];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

@end
