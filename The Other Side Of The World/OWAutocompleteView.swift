//
//  OWAutocompleteView.swift
//  The Far Side
//
//  Created by Max on 11/28/14.
//  Copyright (c) 2014 The Company. All rights reserved.
//

import UIKit

@objc class OWAutocompleteView: UIView, UITableViewDataSource, UITableViewDelegate {
	
	var parentView: UIView
	var textField:  UITextField
	var tableView:  UITableView
	var cellsText:  [NSAttributedString]?
	var popoverVC:  UIPopoverController?
	
	var isShownOnPopoverViewController:Bool
	
	@objc init(textField:UITextField, parentView:UIView) {
		isShownOnPopoverViewController = false
		
		self.textField = textField
		self.parentView = parentView
		tableView = UITableView()
		
		var calculatedY = 0 as CGFloat
		var calculatedHeight = 220 as CGFloat
		var width = 320 as CGFloat
		
		if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Phone {
			calculatedY = 64
			calculatedHeight = parentView.frame.size.height  - calculatedY;
			width = parentView.frame.size.width
		}
		
		super.init(frame: CGRectMake(0,
			calculatedY,
			width,
			calculatedHeight))
		tableView.frame = CGRect(origin: CGPointZero, size: self.frame.size)
		
		self.alpha = 0;
		self.backgroundColor = UIColor(white: 255, alpha: 1)
		
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "editingBegan:", name: UITextFieldTextDidBeginEditingNotification, object: textField)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "editingEnded:", name: UITextFieldTextDidEndEditingNotification, object: textField)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "textChanged:" , name: UITextFieldTextDidChangeNotification, object: textField)
		
		tableView.dataSource = self
		tableView.delegate   = self
		self.addSubview(tableView)
		
		if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad {
			
			let newVC = UIViewController()
			newVC.view = self
			newVC.preferredContentSize = self.frame.size
			popoverVC = UIPopoverController(contentViewController: newVC)
			
			tableView.backgroundColor = UIColor(white: 255, alpha: 0)
			self.backgroundColor = tableView.backgroundColor
		}

	}

	
	func editingBegan(notification:NSNotification) {
		textChanged(nil)
		if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Phone {
			parentView.addSubview(self)
			UIView.animateWithDuration(0.3) {
				self.alpha = 1;
			}
		}
		else {
			popoverVC?.presentPopoverFromRect(textField.frame, inView: parentView, permittedArrowDirections: UIPopoverArrowDirection.Up, animated: true)
		}
	}
	func editingEnded(notification:NSNotification) {
		if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Phone {
			UIView.animateWithDuration(0.3) {
				self.alpha = 0;
			}
			self.removeFromSuperview()
		}
		else {
			popoverVC?.dismissPopoverAnimated(true)
		}
	}
	
	func tableView(tableView:UITableView, didHighlightRowAtIndexPath indexPath:NSIndexPath) {
		textField.text = cellsText![indexPath.row].string
		textField.resignFirstResponder()
	}
	
	func textChanged(notification:NSNotification?) {
		createCells(textField.text!) { suggestions in
			self.cellsText = suggestions;
			dispatch_async(dispatch_get_main_queue()) {
				
				self.tableView.reloadData()
			}
		}
	}
	
	private func createCells(text:String, callback:([NSAttributedString]) -> ()) {
		var strings = [NSAttributedString]()
		let urlString = "https://maps.googleapis.com/maps/api/place/autocomplete/json?key=AIzaSyA5gTRlULxXXzTDK9VaMWhGqEjKlGuGrr0&input=\(text.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.alphanumericCharacterSet())!)&types=(regions)"
		
		let url = NSURL(string: urlString)!
		let req = NSURLRequest(URL: url)
		if NSURLConnection.canHandleRequest(req) {
			
			NSURLConnection.sendAsynchronousRequest(req, queue: NSOperationQueue()) { (response, responseData, error) -> Void in
				if responseData != nil {
					let data = (try? NSJSONSerialization.JSONObjectWithData(responseData!, options: NSJSONReadingOptions()))! as! [String : AnyObject]
					if data["status"] as! String == "OK" {
						
						
						let predictions = data["predictions"] as! [[String : AnyObject]];
						
						for (var i = 0; i < predictions.count; i++) {
							let prediction = predictions[i];
							let text = prediction["description"] as! String;
							let placesToBoldface = prediction["matched_substrings"] as! [[String : Int]];
							
							let attributedString = NSMutableAttributedString(string: text, attributes: [NSFontAttributeName	: UIFont.systemFontOfSize(16)])
							
							for (var j = 0; j < placesToBoldface.count; j++) {
								var placeToBoldface = placesToBoldface[j];
								
								attributedString.addAttribute(NSFontAttributeName,
									value: UIFont.boldSystemFontOfSize(16),
									range: NSMakeRange(placeToBoldface["offset"]!, placeToBoldface["length"]!))
							
							}
							strings.append(attributedString)
							
							/*var cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: nil)
							cell.textLabel.attributedText = attributedString
							
							cells.append(cell)*/
						}
						callback(strings)
					}
					else { callback(strings) }
				}
				else { callback(strings) }
			}
		}
		else { callback(strings) }
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if (cellsText != nil) {
			return cellsText!.count
		}
		else { return 0 }
	}
	
	/*func tableView(tableView:UITableView, willDisplayCell cell:UITableViewCell, forRowAtIndexPath indexPath:NSIndexPath) {
		if indexPath.row == (tableView.indexPathsForVisibleRows() as [NSIndexPath]).last!.row {
			let height = tableView.rectForSection(0).size.height
			tableView.frame.size.height = height
			if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad {
				popoverVC?.popoverContentSize.height = height
				self.frame.size.height = height
			}
		}
	}*/
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: nil)
		cell.textLabel!.attributedText = cellsText![indexPath.row]
		cell.backgroundColor = UIColor(white:255, alpha:0)
		return cell;
	}
	
	required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
}
