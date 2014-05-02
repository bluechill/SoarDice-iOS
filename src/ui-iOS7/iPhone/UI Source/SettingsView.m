//
//  SettingsView.m
//  Liars Dice
//
//  Created by Alex Turner on 8/23/12.
//
//

#import "SettingsView.h"
#import "DiceDatabase.h"

@interface SettingsView ()

@end

@implementation SettingsView

@synthesize nameLabel;
@synthesize difficultyLabel;

@synthesize nameTextField;
@synthesize difficultySelector;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:@"SettingsView" bundle:nil];

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationController.navigationBarHidden = NO;
    self.navigationItem.title = @"Settings";

	DiceDatabase *database = [[[DiceDatabase alloc] init] autorelease];

	if ([database getPlayerName] != nil && [[database getPlayerName] length] != 0)
		self.nameTextField.text = [database getPlayerName];

	self.difficultySelector.selectedSegmentIndex = [database getDifficulty];
}

- (void)nameTextFieldTextFinalize:(id)sender
{
	if (sender != nameTextField)
		return;

	NSString *playerName = nameTextField.text;
	
	if ([playerName length] == 0 || [playerName isEqualToString:@"\n"])
		playerName = @"Player";
	
	DiceDatabase *database = [[[DiceDatabase alloc] init] autorelease];
	[database setPlayerName:playerName];
}

- (void)difficultySelectorValueChanged:(id)sender
{
	if (sender != difficultySelector)
		return;

	DiceDatabase *database = [[[DiceDatabase alloc] init] autorelease];
	[database setDifficulty:difficultySelector.selectedSegmentIndex];
}

- (IBAction)textFieldFinished:(id)sender
{
	[sender resignFirstResponder];
}

- (void)dealloc {
    [super dealloc];
}

@end