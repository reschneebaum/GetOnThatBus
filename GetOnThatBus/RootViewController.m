//
//  ViewController.m
//  GetOnThatBus
//
//  Created by Rachel Schneebaum on 7/28/15.
//  Copyright (c) 2015 Rachel Schneebaum. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "RootViewController.h"
#import "DetailViewController.h"

@interface RootViewController () <MKMapViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property NSArray *rows;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property NSDictionary *selectedDictionary;

@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self prefersStatusBarHidden];
    self.mapView.delegate = self;
    
    [self parseJsonDataWithCompletion:^(NSArray *results) {
        self.rows = results;
        [self addAnnotationsFromJson];
        [self determineMapPosition];
        [self.tableView reloadData];
    }];
}

-(void)determineMapPosition {
    //  zooms map to display all annotations
    MKMapRect zoomRect = MKMapRectNull;
    for (id <MKAnnotation> annotation in self.mapView.annotations) {
        MKMapPoint annotationPoint = MKMapPointForCoordinate(annotation.coordinate);
        MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.1, 0.1);
        zoomRect = MKMapRectUnion(zoomRect, pointRect);
    }
    [self.mapView setVisibleMapRect:zoomRect animated:YES];
}

-(void)parseJsonDataWithCompletion:(void(^)(NSArray *))complete {
    NSURL *url = [NSURL URLWithString:@"https://s3.amazonaws.com/mmios8week/bus.json"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {

        NSDictionary *mainDict = [NSJSONSerialization JSONObjectWithData:data
                                                                 options:NSJSONReadingAllowFragments
                                                                   error:nil];

        NSArray *tempRows = [mainDict objectForKey:@"row"];
        complete([NSArray arrayWithArray:tempRows]);
        }];
}

-(void)addAnnotationsFromJson {
    CLLocationCoordinate2D location;
    MKPointAnnotation *newAnnotation;

    for (NSDictionary *dictionary in self.rows) {
        //   confirm correct location (avoids displaying point in China)
        if (dictionary[@"latitude"] == dictionary[@"location"][@"latitude"] && dictionary[@"longitude"] == dictionary[@"location"][@"longitude"]) {
            //  create annotations associated with each dictionary in JSON array & assign property values from dictionary
            location.latitude = [dictionary[@"latitude"] doubleValue];
            location.longitude = [dictionary[@"longitude"] doubleValue];
            newAnnotation = [MKPointAnnotation new];
            newAnnotation.title = dictionary[@"cta_stop_name"];
            if (dictionary[@"inter_modal"] != nil) {
                //  display intermodal connection if one exists
                newAnnotation.subtitle = [NSString stringWithFormat:@"Route(s): %@; %@ connection",dictionary[@"routes"], dictionary[@"inter_modal"]];
            } else {
                newAnnotation.subtitle = [NSString stringWithFormat:@"Route(s): %@",dictionary[@"routes"]];
            }
            newAnnotation.coordinate = location;
            [self.mapView addAnnotation:newAnnotation];
        } else {
            NSLog(@"lat/long don't match");
        }
    }
}


#pragma mark - mapview delegate methods
#pragma mark -

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    MKPinAnnotationView *pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:nil];
    if ([annotation isEqual:mapView.userLocation]) {
        return nil;
    }
    //  customize annotation image based on intermodal connection
    if ([annotation isKindOfClass:[MKPointAnnotation class]]) {
        if ([annotation.subtitle containsString:@"Metra"]) {
            pin.image = [UIImage imageNamed:@"metra"];
        } else if ([annotation.subtitle containsString:@"Pace"]) {
            pin.image = [UIImage imageNamed:@"pace"];
        } else {
            pin.image = [UIImage imageNamed:@"cta"];
        }
    }
    pin.canShowCallout = true;
    pin.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];

    return pin;
}

-(void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    if ([view.annotation isKindOfClass:[MKPointAnnotation class]]) {
        //  fast enumerate through JSON array to find dictionary associated with tapped annotation
        for (NSDictionary *dictionary in self.rows) {
            if ([view.annotation.title isEqual:dictionary[@"cta_stop_name"]]) {
                self.selectedDictionary = dictionary;
                break;
            } else {
                NSLog(@"error: no match");
            }
        }
    }
    [self performSegueWithIdentifier:@"mapViewSegue" sender:view];
}

#pragma mark - tableview delegate methods
#pragma mark -

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellID"];

    NSDictionary *stopDictionary = self.rows[indexPath.row];

    cell.textLabel.text = stopDictionary[@"cta_stop_name"];
    //  display intermodal connection if one exists & assign image based on @"inter_modal" value
    if (stopDictionary[@"inter_modal"] != nil) {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"Route(s): %@; %@ connection", stopDictionary[@"routes"], stopDictionary[@"inter_modal"]];
        if ([stopDictionary[@"inter_modal"] isEqual:@"Metra"]) {
            cell.imageView.image = [UIImage imageNamed:@"metra"];
        } else {
            cell.imageView.image = [UIImage imageNamed:@"pace"];
        }
    } else {
        //  if no intermodal connection exists, display only routes & assign CTA image
        cell.detailTextLabel.text = [NSString stringWithFormat:@"Route(s): %@", stopDictionary[@"routes"]];
        cell.imageView.image = [UIImage imageNamed:@"cta"];
    }
    //  ensure all text is displayed even for stops with numerous routes/connections
    cell.detailTextLabel.numberOfLines = 2;

    return cell;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.rows.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"tableViewSegue" sender:nil];
    [tableView deselectRowAtIndexPath:indexPath animated:false];
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"tableViewSegue" sender:nil];
}

#pragma mark - navigation
#pragma mark -

- (IBAction)onSegmentedControlSwitch:(UISegmentedControl *)sender {
    //  show/hide mapview or tableview based on segmented control selection
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        self.tableView.hidden = true;
        self.mapView.hidden = false;
    } else {
        self.tableView.hidden = false;
        self.mapView.hidden = true;
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    DetailViewController *dvc = segue.destinationViewController;
    if ([segue.identifier isEqual:@"mapViewSegue"]) {
        dvc.stopDictionary = self.selectedDictionary;
    } else {
        dvc.stopDictionary = [self.rows objectAtIndex:self.tableView.indexPathForSelectedRow.row];
    }
}

@end
