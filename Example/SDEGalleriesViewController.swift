//
//  SDEGalleriesViewController.swift
//  Albums
//
//  Created by seedante on 15/7/6.
//  Copyright © 2015年 seedante. All rights reserved.
//

import UIKit
import Foundation
import Photos

private let reuseIdentifier = "Cell"
private let headerReuseIdentifier = "Header"

class SDEGalleriesViewController: UICollectionViewController, PHPhotoLibraryChangeObserver {
    
    var dataSource = [[PHAssetCollection]]()
    var headerDataSource = [String]()
    
    let fetchOptions = PHFetchOptions()
    
    var localAlbumsDataSource = [PHAssetCollection]()
    var filteredLocalAlbumsDataSource = [PHAssetCollection]()
    let localSubTypes = [PHAssetCollectionSubtype](arrayLiteral:
        .SmartAlbumUserLibrary,
        .SmartAlbumVideos,
        .SmartAlbumSlomoVideos,
        .SmartAlbumTimelapses,
        .SmartAlbumPanoramas,
        .SmartAlbumGeneric,
        .SmartAlbumBursts
    )
    
    
    var specialAlbumsDataSource = [PHAssetCollection]()
    var filteredSpecialAlbumsDataSource = [PHAssetCollection]()
    let specialSubTypes = [PHAssetCollectionSubtype](arrayLiteral:
        .SmartAlbumFavorites,
        .SmartAlbumAllHidden
    )
    
    var syncedAlbumsDataSource = [PHAssetCollection]()
    var filterdSyncedAlbumsDataSource = [PHAssetCollection]()
    let syncedSubTypes = [PHAssetCollectionSubtype](arrayLiteral:
        .AlbumSyncedEvent,
        .AlbumSyncedAlbum,
        .AlbumImported
    )

    var transitionDelegate: SDENavigationControllerDelegate?
    var pinchGestureRecognizer: UIPinchGestureRecognizer?{
        didSet(newValue){
            collectionView?.addGestureRecognizer(pinchGestureRecognizer!)
        }
    }

    //MARK: View Life Circle
    override func awakeFromNib() {
        fetchOptions.predicate = NSPredicate(format: "estimatedAssetCount > 0", argumentArray: nil)
        
        for subType in localSubTypes{
            let fetchResult = PHAssetCollection.fetchAssetCollectionsWithType(.SmartAlbum, subtype: subType, options: nil)
            fetchResult.enumerateObjectsUsingBlock({
                (item, index, stop) in
                self.localAlbumsDataSource.append(item as! PHAssetCollection)
            })
        }
        
        
        for subType in specialSubTypes{
            let fetchResult = PHAssetCollection.fetchAssetCollectionsWithType(.SmartAlbum, subtype: subType, options: nil)
            fetchResult.enumerateObjectsUsingBlock({
                (item, index, stop) in
                self.specialAlbumsDataSource.append(item as! PHAssetCollection)
            })
        }
        
        for subType in syncedSubTypes{
            let fetchResult = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: subType, options: nil)
            fetchResult.enumerateObjectsUsingBlock({
                (item, index, stop) in
                self.syncedAlbumsDataSource.append(item as! PHAssetCollection)
            })
        }
        
        fetchData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)
        pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: "handlePinch:")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.navigationItem.title = "Galleries"
    }

    deinit{
        PHPhotoLibrary.sharedPhotoLibrary().unregisterChangeObserver(self)
        if pinchGestureRecognizer != nil{
            collectionView?.removeGestureRecognizer(pinchGestureRecognizer!)
        }

    }

    func fetchData(){
        if headerDataSource.count > 0{
            headerDataSource.removeAll()
        }
        
        if dataSource.count > 0{
            dataSource.removeAll()
        }
        
        
        filteredLocalAlbumsDataSource = localAlbumsDataSource.filter({PHAsset.fetchAssetsInAssetCollection($0, options: nil).count > 0})
        filteredSpecialAlbumsDataSource = specialAlbumsDataSource.filter({PHAsset.fetchAssetsInAssetCollection($0, options: nil).count > 0})
        filterdSyncedAlbumsDataSource = syncedAlbumsDataSource.filter({$0.estimatedAssetCount > 0})
        
        if filteredLocalAlbumsDataSource.count > 0{
            headerDataSource.append("Albums")
            dataSource.append(filteredLocalAlbumsDataSource)
        }
        
        if filteredSpecialAlbumsDataSource.count > 0{
            headerDataSource.append("SpecialAlbums")
            dataSource.append(filteredSpecialAlbumsDataSource)
        }
        
        if filterdSyncedAlbumsDataSource.count > 0{
            headerDataSource.append("SyncedAlbums")
            dataSource.append(filterdSyncedAlbumsDataSource)
        }
    }
    
    // MARK: UICollectionViewDataSource
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return dataSource.count
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = dataSource[section]
        return sectionInfo.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath)
        // Configure the cell
        if let imageView = cell.viewWithTag(-10) as? UIImageView{
            imageView.layer.borderColor = UIColor.whiteColor().CGColor
            imageView.layer.borderWidth = 10.0
            
            let assetCollectionArray = dataSource[indexPath.section]
            let assetCollection = assetCollectionArray[indexPath.row]
            if let titleLabel = cell.viewWithTag(-20) as? UILabel{
                let titleText = NSAttributedString(string: assetCollection.localizedTitle!)
                let count = PHAsset.fetchAssetsInAssetCollection(assetCollection, options: nil).count
                let countText = NSAttributedString(string: " \(count)", attributes: [NSForegroundColorAttributeName: UIColor.grayColor(), NSFontAttributeName: UIFont(name: "Helvetica Neue", size: 15.0)!])
                let cellTitle = NSMutableAttributedString(attributedString: titleText)
                cellTitle.appendAttributedString(countText)
                titleLabel.attributedText = cellTitle
            }

            PHFetchResult.fetchPosterImageForAssetCollection(assetCollection, imageView: imageView, targetSize: CGSizeMake(170, 170))
        }        
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionHeader, withReuseIdentifier: headerReuseIdentifier, forIndexPath: indexPath)
        if let titleLabel = headerView.viewWithTag(-10) as? UILabel{
            titleLabel.text = headerDataSource[indexPath.section]
        }
        return headerView
    }

    //MARK: PHPhotoLibraryChangeObserver
    func photoLibraryDidChange(changeInstance: PHChange) {
        let localAlbumsCopy = localAlbumsDataSource
        for assetCollection in localAlbumsCopy{
            if let changeDetail = changeInstance.changeDetailsForObject(assetCollection){
                let index = localAlbumsDataSource.indexOf(assetCollection)
                let newAssetCollection = changeDetail.objectAfterChanges as! PHAssetCollection
                localAlbumsDataSource[index!] = newAssetCollection
            }

        }
        
        let specialAlbumsCopy = specialAlbumsDataSource
        for assetCollection in specialAlbumsCopy{
            if let changeDetail = changeInstance.changeDetailsForObject(assetCollection){
                let index = specialAlbumsDataSource.indexOf(assetCollection)
                let newAssetCollection = changeDetail.objectAfterChanges as! PHAssetCollection
                specialAlbumsDataSource[index!] = newAssetCollection
            }
        }
        
        let syncedAlbumsCopy = syncedAlbumsDataSource
        for assetCollection in syncedAlbumsCopy{
            if let changeDetail = changeInstance.changeDetailsForObject(assetCollection){
                let index = syncedAlbumsDataSource.indexOf(assetCollection)
                let newAssetCollection = changeDetail.objectAfterChanges as! PHAssetCollection
                syncedAlbumsDataSource[index!] = newAssetCollection
            }
        }
        
        fetchData()
    }

    //MARK: UICollectionView Delegate
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        self.selectedIndexPath = indexPath
        self.collectionView?.allowsSelection = false

        let layoutAttributes = self.collectionView!.layoutAttributesForItemAtIndexPath(indexPath)

        let circleView = UIView(frame: CGRectMake(0, 0, 30.0, 30.0))
        circleView.layer.cornerRadius = 15.0
        circleView.backgroundColor = UIColor.blueColor()
        self.collectionView?.addSubview(circleView)
        circleView.center = layoutAttributes!.center

        UIView.animateKeyframesWithDuration(0.3, delay: 0, options: UIViewKeyframeAnimationOptions.AllowUserInteraction, animations: {
            circleView.transform = CGAffineTransformMakeScale(2, 2)
            circleView.alpha = 0
            }, completion: {
                finish in

                circleView.removeFromSuperview()
                if let albumVC = self.storyboard?.instantiateViewControllerWithIdentifier("AlbumVC") as? SDEAlbumViewController{
                    let assetCollection = self.dataSource[indexPath.section][indexPath.row]
                    albumVC.assetCollection = assetCollection
                    self.navigationController?.pushViewController(albumVC, animated: true)
                    self.collectionView?.allowsSelection = true
                }
        })
    }

    //MARK: Pinch Push and Pop
    func getIndexPathForGesture(gesture: UIPinchGestureRecognizer) -> NSIndexPath?{
        let location0 = gesture.locationOfTouch(0, inView: gesture.view)
        let location1 = gesture.locationOfTouch(1, inView: gesture.view)
        let middleLocation = CGPointMake((location0.x + location1.x)/2, (location0.y + location1.y)/2)
        let indexPath = collectionView?.indexPathForItemAtPoint(middleLocation)
        return indexPath
    }

    func handlePinch(gesture: UIPinchGestureRecognizer){
        switch gesture.state{
        case .Began:
            if gesture.scale >= 1.0{
                guard let indexPath = getIndexPathForGesture(gesture) else{
                    return
                }

                self.selectedIndexPath = indexPath                

                if let toVC = storyboard?.instantiateViewControllerWithIdentifier("AlbumVC") as? SDEAlbumViewController{
                    let assetCollection = dataSource[indexPath.section][indexPath.row]
                    toVC.assetCollection = assetCollection

                    transitionDelegate = navigationController?.delegate as? SDENavigationControllerDelegate
                    transitionDelegate?.interactive = true
                    navigationController?.pushViewController(toVC, animated: true)
                }

            }else{
                //after view controller is poped, UIViewController.navigationController is nil. So you need to keep it somewhere before pop
                transitionDelegate = self.navigationController?.delegate as? SDENavigationControllerDelegate
                transitionDelegate?.interactive = true
                self.navigationController?.popViewControllerAnimated(true)
            }

        case .Changed:

            guard transitionDelegate != nil else{
                return
            }

            guard let interactionController = transitionDelegate?.interactionController else{
                return
            }

            var progress = gesture.scale
            if transitionDelegate!.isPush{
                progress = gesture.scale - 1.0 >= 0.9 ? 0.9 : gesture.scale - 1.0
            }else{
                progress = 1.0 - gesture.scale
            }

            interactionController.updateInteractiveTransition(progress)

        case .Ended, .Cancelled:
            guard transitionDelegate != nil else{
                return
            }

            guard let interactionController = transitionDelegate?.interactionController else{
                return
            }

            var progress = gesture.scale
            if transitionDelegate!.isPush{
                progress = gesture.scale - 1.0 >= 0.9 ? 0.9 : gesture.scale - 1.0
            }else{
                progress = 1.0 - gesture.scale
            }

            if progress >= 0.4{
                interactionController.finishInteractiveTransition()
            }else{
                interactionController.cancelInteractiveTransition()
            }
            transitionDelegate?.interactive = false

        default:
            guard transitionDelegate != nil else{
                return
            }
            transitionDelegate?.interactive = false
        }
    }

}
