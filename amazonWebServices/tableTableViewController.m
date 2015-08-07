//
//  tableTableViewController.m
//  amazonWebServices
//
//  Created by Aditya Narayan on 8/5/15.
//  Copyright © 2015 Karan Satia. All rights reserved.
//

#import "tableTableViewController.h"
#import <AWSCore/AWSCore.h>
#import <AWSCognito/AWSCognito.h>
#import "imageObject.h"

@interface UIViewController () {
    
}

@end

@implementation tableTableViewController

- (void)viewDidLoad {

    [super viewDidLoad];
    self.transferManager = [AWSS3TransferManager defaultS3TransferManager];

    self.view.backgroundColor = [UIColor whiteColor];
    [self listAllObjects];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)cameraRoll:(id)sender {
    UIImagePickerController *iPhonePicker = [[UIImagePickerController alloc]init];
    [iPhonePicker setDelegate:self];
    
    //UIPopoverController *iPadPicker = [[UIPopoverController alloc]init];
    
    UIImagePickerController *iPadPicker = [[UIImagePickerController alloc]init];
    [iPadPicker setDelegate:self];
    
    if ([[UIDevice currentDevice]userInterfaceIdiom]==UIUserInterfaceIdiomPhone) {
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            [iPhonePicker allowsEditing];
            [iPhonePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        }
        else {
            [iPhonePicker setAllowsEditing:YES];
            [iPhonePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
        }
        
        [self presentViewController:iPhonePicker animated:YES completion:nil];
    }
    
    
//    else if([[UIDevice currentDevice]userInterfaceIdiom]==UIUserInterfaceIdiomPad) {
//        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
//            [iPadPicker setAllowsEditing:YES];
//            [iPadPicker setSourceType:UIImagePickerControllerSourceTypeCamera];
//        }
//        else {
//            [iPadPicker allowsEditing];
//            [iPadPicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        //CREATE POPOVER
            
//        }
}


-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {

    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    
    [self.image setImage:image];
    
    [self uploadImage:info];

    if ([[UIDevice currentDevice]userInterfaceIdiom]==UIUserInterfaceIdiomPhone) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });

}



-(void) uploadImage:(NSDictionary*)info {

    imageObject *a = [imageObject new];
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    NSString *imagePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"upload-image.tmp"];
    NSData *imageData = UIImagePNGRepresentation(image);

    NSString *fileName = [[NSString alloc] initWithFormat:@"%f.jpg", [[NSDate date] timeIntervalSince1970 ] ];
    [imageData writeToFile:imagePath atomically:YES];
    a.image = image;
    a.key = fileName;
    [self.imageObjects addObject:a];
    
    
    AWSS3TransferManagerUploadRequest *uploadRequest = [AWSS3TransferManagerUploadRequest new];
    uploadRequest.bucket = @"karanphotos";
    uploadRequest.key = fileName;
    uploadRequest.body = [NSURL fileURLWithPath:imagePath];
    
    
    [[self.transferManager upload:uploadRequest] continueWithExecutor:[AWSExecutor mainThreadExecutor] withBlock:^id(AWSTask *task) {
    
        if (task.error != nil) {
            NSLog(@"%@ is causing error", uploadRequest.key);
        }
        else {
            NSLog(@"Upload successful");
        }
        return nil;
    }];
}


-(void) listAllObjects {

    AWSS3 *S3 = [AWSS3 defaultS3];
    AWSS3ListObjectsRequest *listObjects = [AWSS3ListObjectsRequest new];
    listObjects.bucket = @"karanphotos";
    self.imageNames = [NSMutableArray new];
    self.imageObjects = [NSMutableArray new];

    [[S3 listObjects:listObjects]continueWithBlock:^id(AWSTask *task) {
        if (task.error) {
            NSLog(@"listObjects failed-->%@", task.error);
        }
        else {
            AWSS3ListObjectsOutput *output = task.result;
            
            for (AWSS3Object *temp in output.contents) {
            
                    imageObject *a = [imageObject new];
                    a.key = temp.key;
                    [self.imageObjects addObject:a];
                }
            }
        
        [self downloadImages:self.imageObjects];
        return nil;
    }];
}


-(void) downloadImages:(NSMutableArray *)imageNames {
    for (imageObject *a in imageNames) {
        NSString *downloadingFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"downloaded-%@", a.key]];
        NSURL *url = [NSURL fileURLWithPath:downloadingFilePath];
        
        AWSS3TransferManagerDownloadRequest *download = [AWSS3TransferManagerDownloadRequest new];
        download.bucket = @"karanphotos";
        download.key = a.key;
        download.downloadingFileURL = url;
        
        [[self.transferManager download:download] continueWithExecutor:[AWSExecutor mainThreadExecutor] withBlock:^id(AWSTask *task) {
            if (task.error) {
                if ([task.error.domain isEqualToString:AWSS3TransferManagerErrorDomain]) {
                    switch (task.error.code) {
                        case AWSS3TransferManagerErrorCancelled:
                        case AWSS3TransferManagerErrorPaused:
                            break;
                        default:
                            NSLog(@"Error: %@", task.error);
                            break;
                    }
                }
                else {
                    NSLog(@"%@", task.error);
                }
            }
            
            if (task.result) {
                AWSS3TransferManagerDownloadOutput *downloadOutput = task.result;
                NSLog(@"success");
                UIImage *image = [[UIImage alloc]initWithData:[NSData dataWithContentsOfFile:downloadOutput.body]];
                a.image = image;
                dispatch_async(dispatch_get_main_queue(), ^{
                                [self.tableView reloadData];
                            });
            }
            return nil;
        }];
    }
}

- (IBAction)editButton:(id)sender {


}





 - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
 UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
     imageObject *a = [self.imageObjects objectAtIndex:indexPath.row];
     cell.textLabel.text = a.key;
     return cell;
 }

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    imageObject *a = [self.imageObjects objectAtIndex:indexPath.row];
    self.image.image = a.image;
}


 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }




 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 
     imageObject *a = [self.imageObjects objectAtIndex:indexPath.row];
     [self.imageObjects removeObject:a];
     [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
     AWSS3DeleteObjectRequest *deleteReqest = [AWSS3DeleteObjectRequest new];
     deleteReqest.bucket = @"karanphotos";
     deleteReqest.key = a.key;
     
     [self deleteObjectFromBucket:deleteReqest];
 } }


-(void)deleteObjectFromBucket:(AWSS3DeleteObjectRequest *)deleteRequest {

    AWSS3 *s3 = [AWSS3 defaultS3];
    
    [[s3 deleteObject:deleteRequest] continueWithBlock:^id(AWSTask *task) {
        if(task.error){
            if(task.error.code != AWSS3TransferManagerErrorCancelled && task.error.code != AWSS3TransferManagerErrorPaused){
                NSLog(@"Error: [%@]", task.error);
            }
        }
        else {
            NSLog(@"Successfully deleted");
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.imageObjects.count == 0) {
                [self.image setImage:nil];
            }
            [self.tableView reloadData];
        });
        
        return nil;
    }];
}


 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }


 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 return YES;
 }


#pragma mark - Navigation

 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 }


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.imageObjects.count;
}


@end
