//
//  tableTableViewController.h
//  amazonWebServices
//
//  Created by Aditya Narayan on 8/5/15.
//  Copyright © 2015 Karan Satia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AWSS3/AWSS3.h>

@interface tableTableViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *image;

- (IBAction)cameraRoll:(id)sender;
- (IBAction)editButton:(id)sender;

@property (strong, nonatomic) NSMutableArray *imageNames;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSMutableArray *imageObjects;
@property (strong, nonatomic) AWSS3TransferManager *transferManager;


@end
