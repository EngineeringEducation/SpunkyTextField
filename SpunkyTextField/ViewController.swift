//
//  ViewController.swift
//  SpunkyTextField
//
//  Created by Wren on 6/13/15.
//  Copyright (c) 2015 Janardan Yri. All rights reserved.
//

import UIKit

// Within this view controller, we have a single text field.
// Our goal is to keep it unobscured by the keyboard in a way that animates pleasantly.
// Note that this includes not only its appearance but also rotation and size changes...! It'll be an adventure.
// (Try landscape mode, smaller devices, showing/hiding the predictive text interface, switching keyboards.)

class ViewController: UIViewController {

  // This text field is the view we're going to move around.
  // It, like all views in the hierarchy, exists inside a "superview", which in this case is just the full-screen view associated with this view controller.
  @IBOutlet weak var spunkyTextField: UITextField!

  // Rather than explicitly positioning using frames, we're telling the autolayout system our set of priorities.
  // In our storyboard, our text field has three constraints that tell it to:
  // 1) Align its horizontal center with the horizontal center of its superview, at all times (priority 1000)
  // 2) Align its vertical center with the vertical center of its superview, if nothing else takes precedence (priority 500)
  // 3) Keep the bottom of the text field above the bottom of its superview, at all times (priority 1000)

  // So far so good. Those should be easy constraints to satisfy; the vertical center of the view should be nowhere near the bottom.
  // But you might remember that every constraint has a multiplier and a constant. We're going to acknowledge the space taken up by the keyboard by changing the constant on that constraint #3 so that the bottom of the text field is required to be a certain distance above the bottom of its superview, not just above it.
  // To change that constraint "constant" (this terminology is unfortunate), we'll need a reference to constraint #3, and here it is!
  @IBOutlet weak var spunkyTextFieldMinimumDistanceAboveBottomConstraint: NSLayoutConstraint!

  // We also might want the text field to not just stay above the keyboard, but also leave a bit of space. Here's a constant (Swift constant, not constraint constant) that specifies how much space.
  let minimumTextFieldKeyboardGap : CGFloat = 10

  // Now, the way that keyboard changes are communicated is through a series of NSNotifications.
  // If you haven't had a chance to use NSNotifications yet, they're  conceptually akin to the notifications you receive as a user in that a range of notifications from different sources flow through a single notification center and you can opt into or out of seeing any kinds of notifications you want.
  // In this case, though, these notifications are sent not by different apps but by different parts of our app, and they're not for the user but rather for whatever parts of the app want to subscribe to them.
  // It's good that the keyboard works via notifications because we want to get notified that a keyboard is obscuring the screen regardless of who's doing that in whatever way.

  // It's possible to receive keyboard notifications with these names:
  // UIKeyboardWillChangeFrameNotification
  // UIKeyboardDidChangeFrameNotification
  // UIKeyboardWillShowNotification
  // UIKeyboardDidShowNotification
  // UIKeyboardWillHideNotification
  // UIKeyboardDidHideNotification

  // I don't remember those names - instead I remember these things:
  // - The naming convention for notification names includes the word "Notification" at the end
  // - Keyboard notification names all begin with "UIKeyboard"
  // and so I can type something like 'uikeybonotif' into Dash and they all come up.

  // One thing worth knowing about "will..." and "did..." names that relate to transitions is that "will..." gets called or sent before the animation starts whereas "did..." gets called or sent after the animation completes.

  // So in this case, the UIKeyboardWillChangeFrameNotification is the most useful for us: we want a "Will" notification so that we get a chance to do our repositioning animation alongside the keyboard animation, and we want "ChangeFrame" because we want to be able to respond to any keyboard repositioning, not just appearance and disappearance.
  // (Note that this implies that every time Show or Hide gets sent, ChangeFrame also gets sent.)

  // Great! So we want UIKeyboardWillChangeFrameNotification. When do we want it? When we're on the screen! Which implies viewWillAppear, since the same will/did logic applies: immediately after viewWillAppear, we might be onscreen as part of a transition.
  // (Right now this app is sufficiently simple that there won't be any transitions, with only a single view controller and no segues, but we have to start listening for this notification somewhere and it's good to put that in a place that will be resilient against future changes.)

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)

    // And here's how we actually start observing for notifications getting sent out with the name UIKeyboardWillChangeFrameNotification.
    // You can in theory create multiple different independent NSNotificationCenters; you'll only see notifications that are sent through the specific notification center you pick.
    // Usually that distinction would be mostly just a source of unexpected bugs (why am I not seeing this thing that's clearly happening!) and so it's typical to use the default notification center, especially for something like keyboard notifications that's out of our control.
    let notificationCenter = NSNotificationCenter.defaultCenter()

    // One way to get a chance to work with notifications is to add an observer with a selector.
    // In this case, we want the observer to be "self" (this view controller) so that we can update constraints and possibly move views around.
    notificationCenter.addObserver(self,
      // "selector" lets us pick a method to get called. Parameters are represented with a single colon as in objc, so this selector will receive a single parameter. How did I know to do this...? If you look up the documentation for this function in Dash, you'll notice that it insists that the method we provide take a single parameter, which will be the NSNotification.
      selector: "keyboardWillChangeFrame:",
      // We need to specify the actual name of the notification, of course
      name: UIKeyboardWillChangeFrameNotification,
      // And finally, we could specify that we only want to see notifications that are sent by a particular object. But we need to adjust our textField in response to any and all keyboard notifications, so as specified by the documentation for this function, we pass nil to reflect that.
      object: nil
    )
  }

  // OK, we can successfully receive notifications when our view appears. Hooray! Now, subscribing to notifications should always be paired with an unsubscription at a symmetric and appropriate time. In this case, the symmetrically appropriate time to when our view appears would be when our view disappears. You might think that implies "viewWillDisappear" to go with "viewWillAppear", but remember that the view actually stays on-screen throughout any transition that might happen. The final disappearance is represented by a "did" method, in this case "viewDidDisappear."

  override func viewDidDisappear(animated: Bool) {
    super.viewDidDisappear(animated)

    // So here we should remove ourselves as the observer for that same notification we started watching earlier, so all the parameters should match. Note that there's no "selector" parameter here, just because the notification center doesn't need that in order to figure out what notifications we don't want to receive anymore.
    NSNotificationCenter.defaultCenter().removeObserver(self,
      name: UIKeyboardWillChangeFrameNotification,
      object: nil
    )
  }

  // Surprise fun fact about subscribing to notifications! We in general don't have to worry too much about memory management in 2015. Our objects stick around for just as long as we need them, and then magically go away when we don't need them anymore. But NSNotificationCenter doesn't know about all that magic, so if you forget to unsubscribe from a notification and your object goes away, NSNotificationCenter will still try to send it those notifications and your program will crash on the next attempt.
  // Unfortunately, since the logic for notification subscriptions is distributed through multiple functions, it's too complicated for the compiler to check for that automatically. So this is one of those things you just have to remember to be scrupulous about.

  // OK, cool, we're subscribing to notifications, let's actually implement what we want to do when it hits!

  // Here's our method with the same name as the selector. Note that it has its one notification parameter - we can call it whatever we want but we have to recognize that it will be an NSNotification.
  func keyboardWillChangeFrame(keyboardNotification: NSNotification) {

    // All our context about what's happening with the keyboard comes out of that keyboardNotification object. I've put all the logic for extracting that information inside a different function so we don't have to worry about it yet. This is a great time for a tuple, since we want multiple pieces of information and we want that other function to handle getting them all for us so we can concentrate on how we want to use them.
    let (nextKeyboardRectInScreen, animationDuration, animationOptions) = valuesFromKeyboardNotification(keyboardNotification)
    // So the pieces of information we've retrieved here include:
    // - nextKeyboardRectInScreen: The rect (size and position) the keyboard will have after this change completes
    // - animationDuration: How long the keyboard is going to spend animating to its new size and position
    // - animationOptions: The animation settings the keyboard will use, so we can animate alongside in a way that looks nice.

    // But our actual goal, if you recall, is to update our text field's constraint #3 "constant" to keep it above the keyboard. I've written a function that determines what the new value of that "constant" should be for a given keyboard rect, so let's get it!
    let nextMinimumDistanceAboveBottomConstraintConstant = self.textFieldDistanceAboveBottom(keyboardRectInScreen:nextKeyboardRectInScreen)



    // Which means we need to make sure autolayout does its updates within that closure. The way we prod autolayout into doing those updates is with the layoutIfNeeded() function.

    // Modern iOS animations work by taking a closure that defines the actual changes we want to be animated, so let's start writing that closure.
    let animations = { () -> Void in

      // Here we'll want to update our constraint with the new "constant" we've determined. This is where we need that IBOutlet we created earlier.
      self.spunkyTextFieldMinimumDistanceAboveBottomConstraint.constant = nextMinimumDistanceAboveBottomConstraintConstant

      // One big caveat here: since we're using auto layout, we don't actually define the changes to our view's positions, autolayout does, using our constraints. And autolayout doesn't just update every time you change a constraint - you might change twenty at once and it would be wasteful to do a layout pass after every single change! But we need to know that autolayout will do this update within this closure, or our animation won't work. So we can prod autolayout into doing that using the layoutIfNeeded() method, which does a layout pass on all the subviews of the view on which it's called. (Our textfield lives inside self.view, so self.view is a safe bet here.)
      self.view.layoutIfNeeded()

      // It's also possible that the keyboard will change in a way that doesn't result in our textfield moving around - maybe we're on an iPad and we've got lots of extra space. That's fine too.
    }

    // Now we have all the information we need to reposition our text field and animate that repositioning in a way that looks good next to the keyboard, so the last step is just to do that actual animation and pass in all the information we've collected. (Note that we don't need the "delay" parameter, nor do we need to do anything when the animation completes.)

    UIView.animateWithDuration(animationDuration,
      delay: 0,
      options: animationOptions,
      animations: animations,
      completion: nil)

    // And... that's it! That animation starts, this function immediately ends, everyone's happy.
  }

  // So that just leaves our helper functions. Remember that we wrote this one to give us the constant for the text field's minimum distance above the bottom of its enclosing view.
  func textFieldDistanceAboveBottom(#keyboardRectInScreen : CGRect) -> CGFloat {

    // You might be wondering about that "InScreen" business. Every view has its own coordinate grid, as does the screen of the device itself, and the rectangles we get from our keyboard notification are in reference to that device coordinate grid. (Every time you rotate your device, the coordinate grids of all your views move in relation to the screen.) So this isn't very useful to us - our text field is positioned with respect to self.view, so let's get the rect in relation to self.view's coordinate grid.
    let keyboardRect = self.view.convertRect(keyboardRectInScreen, fromView: nil)

    // OK, now we're working with the coordinate grid of self.view, and we need to be consistent about that. This will become relevant momentarily.

    // Now we'd like to know the amount of vertical space at the bottom of our view that's being covered by the keyboard, so I'm going to get the highest point occupied by the keyboard (minY) and subtract that from the lowest point occupied by self.view (maxY).
    let keyboardDistanceAboveBottom = self.view.bounds.maxY - keyboardRect.minY

    // A brief mention of bounds vs. frames: a view's "bounds" is its size and position with respect to its own coordinate grid, whereas "frame" is with respect to its superview's coordinate grid. As we're working with self.view's coordinate grid, we need to use self.view.bounds. (If for some reason we needed the text field's rect within this function, we would therefore use that text field's frame.)

    // So... now we know how much space we need to leave for the keyboard! Let's add our 'gap' constant that we specified earlier and call it a day!
    return keyboardDistanceAboveBottom + self.minimumTextFieldKeyboardGap
  }

}

//// Bonus Round: Take a shot at understanding this but don't beat yourself up about it.


// Here's that function we created to extract meaningful information from the keyboard notification.
// Notice that I haven't put it on the view controller class - it's not really related to the view controller, we just need it there.
// That means that right now it's a global function. We don't like the word "global" in programming - it's like eating lunch in your bathroom.
// I've tagged this function with the word 'private' to at least maintain discipline about not calling this willy-nilly from other files; if we find ourselves needing that, we should refactor this function into a more appropriate place.

private func valuesFromKeyboardNotification(keyboardNotification : NSNotification) -> (CGRect, NSTimeInterval, UIViewAnimationOptions) {

  // All the stuff we want is contained within the "userInfo" dictionary. Note that "user" doesn't necessarily mean us: it means whoever's using the notification system, in this case whoever at Apple writes keyboard code.
  let info = keyboardNotification.userInfo!

  // Hoo boy, here we go. So this is old code, and in the old days of objc, you couldn't just put CGRects and Integers and NSTimeIntervals into NSArrays; objects only. So we used NSValue and NSNumber objects to "wrap" that stuff.

  // And since userInfo is a dictionary, its contents are identified by specific key strings. If you look up the documentation for the keyboard notifications, it'll tell you what those keys are and what to expect to get for them. The ones we care about are UIKeyboardFrameEndUserInfoKey, UIKeyboardAnimationDurationUserInfoKey, and UIKeyboardAnimationCurveUserInfoKey.

  // Our keyboard's frame end is a CGRect wrapped with an NSValue
  let frameEnd = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()

  // Duration is an NSTimerInterval wrapped with an NSNumber. Note that NSTimeInterval is a typealias for Double, which is why doubleValue works here - NSNumbers don't have a timeIntervalValue property.
  let duration : NSTimeInterval = (info[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue

  // We get the chosen animation curve - the particular type of path over time that the keyboard takes from the starting point to the end point - as a selection from an enumerated set of values: .EaseInOut, .EaseIn, .EaseOut, or .Linear. That's awkward, but we can get an integer out of this NSNumber and use it as the rawValue for UIViewAnimationCurve - if you cmd-click on UIViewAnimationCurve, you'll see that it's represented as an Int under the hood.
  let curve = UIViewAnimationCurve(rawValue: (info[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).integerValue)!

  // ...Only - this is the worst bit - since iOS7 the keyboard doesn't use any of those enumerated values!! It uses its own secret curve! And for us to do our animation, the UIView animation function calls don't want UIViewAnimationCurve, they want UIViewAnimationOptions, of which specifying a curve is but one component! So we have to do our own conversion using questionable knowledge we acquired by watching all this stuff happen in a debugger, reading stack overflow, and/or just assuming this will continue to work the same way in Swift as it did in Objective-C.
  let options = UIViewAnimationOptions(rawValue:UInt(curve.rawValue << 16))

  // Alright, well, that was arduous. Whoever called this function has no idea what it took for us to get them this data. (Indeed, you might notice I've also used different variable names inside this function vs the calling function.)
  return (frameEnd, duration, options)
}

// OK, now we're really done. :) Hooray!
