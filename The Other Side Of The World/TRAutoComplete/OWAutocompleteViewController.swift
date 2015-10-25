//
//  OWAutoCompleteViewController.swift
//  The Far Side
//
//  Created by Max on 11/3/14.
//  Copyright (c) 2014 The Company. All rights reserved.
//

import UIkit

@objc class OWAutocompleteViewController: UIViewController {
    private var textField:UITextField!
    private var parentController:UIViewController!
    private var autoCompleteView:TRAutocompleteView!
    
    @objc convenience init(textField:UITextField, parentViewController:UIViewController) {
        self.init()
        self.textField = textField
        parentController = parentViewController

        autoCompleteView = TRAutocompleteView(bindedTo: textField,
            usingSource: TRGoogleMapsAutocompleteItemsSource(minimumCharactersToTrigger:1, apiKey:"AIzaSyA5gTRlULxXXzTDK9VaMWhGqEjKlGuGrr0"),
            cellFactory: TRGoogleMapsAutocompletionCellFactory(cellForegroundColor:UIColor.darkTextColor(), fontSize:14),
            presentingIn: self)
        
        self.modalPresentationStyle = UIModalPresentationStyle.FormSheet
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "show:", name: UIKeyboardWillShowNotification, object: textField)
    }
    
    override init() {
        super.init()
    }
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle:nibBundleOrNil)
    }

    required init(coder aDecoder: NSCoder) {
        super.init()
    }
    
    func show(notice:NSNotification) {
        parentController.presentViewController(self, animated: true, completion: nil)
    }
    
    func hide(notice:NSNotification) {
        parentController.dismissViewControllerAnimated(true, completion: nil)
    }
}
