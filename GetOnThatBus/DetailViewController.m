//
//  DetailsViewController.m
//  GetOnThatBus
//
//  Created by Rachel Schneebaum on 7/28/15.
//  Copyright (c) 2015 Rachel Schneebaum. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "DetailViewController.h"

@interface DetailViewController () <MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITextView *addressTextView;
@property (weak, nonatomic) IBOutlet UILabel *routesLabel;
@property (weak, nonatomic) IBOutlet UILabel *intermodalLabel;
@property (weak, nonatomic) IBOutlet UILabel *intermodalTitleLabel;
@property (weak, nonatomic) IBOutlet MKMapView *detailMapView;

@end

@implementation DetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self prefersStatusBarHidden];
    self.detailMapView.delegate = self;
    [self setMapViewRegionWithStopAnnotation];

    //  assign label values from dictionary associated with selected stop
    self.titleLabel.text = self.stopDictionary[@"cta_stop_name"];
    self.addressTextView.text = self.stopDictionary[@"_address"];
    self.routesLabel.text = [NSString stringWithFormat:@"%@",self.stopDictionary[@"routes"]];
    
    //  display intermodal transfer(s) if value for @"inter_modal" exists
    if (self.stopDictionary[@"inter_modal"] != nil) {
        self.intermodalLabel.text = self.stopDictionary[@"inter_modal"];
    } else {
        self.intermodalTitleLabel.hidden = true;
        self.intermodalLabel.text = @"no intermodal transfers available";
    }
}

-(void)setMapViewRegionWithStopAnnotation {
    MKPointAnnotation *annotation = [MKPointAnnotation new];
    annotation.coordinate = CLLocationCoordinate2DMake([self.stopDictionary[@"latitude"] doubleValue], [self.stopDictionary[@"longitude"] doubleValue]);
    [self.detailMapView setRegion:MKCoordinateRegionMake(annotation.coordinate, MKCoordinateSpanMake(0.1, 0.1)) animated:false];
    [self.detailMapView addAnnotation:annotation];
    NSLog(@"# annotations in detail map: %lu", (unsigned long)self.detailMapView.annotations.count);
}

#pragma mark - mapview delegate methods
#pragma mark -

-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    MKPinAnnotationView *pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:nil];
    if (self.stopDictionary[@"inter_modal"] != nil) {
        if ([annotation.subtitle containsString:@"Metra"]) {
            pin.image = [UIImage imageNamed:@"metra"];
        } else {
            pin.image = [UIImage imageNamed:@"pace"];
        }
    } else {
        pin.image = [UIImage imageNamed:@"cta"];
    }

    pin.canShowCallout = false;
    pin.userInteractionEnabled = false;
    return pin;
}

- (IBAction)onDismissButtonTapped:(UIButton *)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}

@end
