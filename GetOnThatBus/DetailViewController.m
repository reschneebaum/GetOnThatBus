//
//  DetailsViewController.m
//  GetOnThatBus
//
//  Created by Rachel Schneebaum on 7/28/15.
//  Copyright (c) 2015 Rachel Schneebaum. All rights reserved.
//

#import "DetailViewController.h"


@interface DetailViewController ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITextView *addressTextView;
@property (weak, nonatomic) IBOutlet UILabel *routesLabel;
@property (weak, nonatomic) IBOutlet UILabel *intermodalLabel;
@property (weak, nonatomic) IBOutlet UILabel *intermodalTitleLabel;

@end

@implementation DetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self prefersStatusBarHidden];
    
    self.titleLabel.text = self.stopDictionary[@"cta_stop_name"];
    self.addressTextView.text = self.stopDictionary[@"_address"];
    self.routesLabel.text = [NSString stringWithFormat:@"%@",self.stopDictionary[@"routes"]];
    if (self.stopDictionary[@"inter_modal"] != nil) {
        self.intermodalLabel.text = self.stopDictionary[@"inter_modal"];
    } else {
        self.intermodalTitleLabel.hidden = true;
        self.intermodalLabel.text = @"no intermodal transfers available";
    }
}

- (IBAction)onDismissButtonTapped:(UIButton *)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}

@end
