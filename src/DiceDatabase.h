//
//  DiceDatabase.h
//  Liars Dice
//
//  Created by Miller Tinkerhess on 5/3/12.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GameRecord.h"

@interface DiceDatabase : NSObject

+ (GameTime) getCurrentGameTime;
- (void) addGameRecord:(GameRecord *)gameRecord;
- (NSArray *) getGameRecords;
- (void) reset;

@end