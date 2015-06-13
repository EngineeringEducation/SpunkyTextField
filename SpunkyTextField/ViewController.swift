//
//  ViewController.swift
//  SpunkyTextField
//
//  Created by Wren on 6/13/15.
//  Copyright (c) 2015 Janardan Yri. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  @IBOutlet weak var spunkyTextField: UITextField!
  @IBOutlet weak var spunkyTextFieldMinimumDistanceAboveBottomConstraint: NSLayoutConstraint!

  let minimumTextFieldKeyboardGap : CGFloat = 10

  // MARK: - View Lifecycle

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)

    NSNotificationCenter.defaultCenter().addObserver(self,
      selector: "keyboardWillChangeFrame:",
      name: UIKeyboardWillChangeFrameNotification,
      object: nil
    )
  }

  override func viewDidDisappear(animated: Bool) {
    super.viewDidDisappear(animated)

    NSNotificationCenter.defaultCenter().removeObserver(self,
      name: UIKeyboardWillChangeFrameNotification,
      object: nil
    )
  }

  // MARK: - Keyboard

  func keyboardWillChangeFrame(notification: NSNotification) {
    let info = notification.userInfo!

    let duration : NSTimeInterval = (info[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue

    let curve = UIViewAnimationCurve(rawValue: (info[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).integerValue)!
    let options = UIViewAnimationOptions(rawValue:UInt(curve.rawValue << 16))

    let nextKeyboardRectInScreen = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
    let nextKeyboardRect = self.view.convertRect(nextKeyboardRectInScreen, fromView: nil)
    let nextKeyboardDistanceAboveBottom = CGRectGetMaxY(self.view.bounds) - CGRectGetMinY(nextKeyboardRect)
    let nextMinimumDistanceAboveBottomConstraintConstant = nextKeyboardDistanceAboveBottom + self.minimumTextFieldKeyboardGap

    UIView.animateWithDuration(duration,
      delay: 0,
      options: options,
      animations: {
        self.spunkyTextFieldMinimumDistanceAboveBottomConstraint.constant = nextMinimumDistanceAboveBottomConstraintConstant
        self.view.layoutIfNeeded()
      },
      completion: nil)

  }
}

