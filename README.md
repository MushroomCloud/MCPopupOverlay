#MCPopupOverlay

This is a generic popup view which can be overlaid on top of other views. It does not provide any visuals itself, but serves more as a container for your own UI, and provides functionality common to some general use cases of popups.

The popup's content is placed in a scrollview whose content size and insets are adjusted in response to keyboard frame changes, and it will also monitor changes to the first responder to ensure a field is scrolled into view when it becomes first responder.

It can also allow the user to dismiss the popup with a pan gesture, and uses a UIDynamicAnimator (when available) to add a bit of pshwow to the interaction.

#Usage
To make use of this, subclass it and add your view hierarchy to the ```popupView``` property. If not using auto layout, it may be useful to override the ```layoutSubviews``` method as well.

To show an instance of the popup once created:

```
UIView *popupSuperview = ...
YourPopupSubclass *popup = [[YourPopupSubclass alloc] init];

... configure popup
    
[popup showInView:popupSuperview];
```

Dynamic dismissal is an opt-in feature, and can be activated via the ```panToDismissEnabled``` property.