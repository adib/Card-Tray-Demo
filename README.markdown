# Card Tray Demo

A clone of the credit/debit card storage of Apple’s _Wallet_ app. 

## Features

- Drag to re-order cards with physics animation.
- Enter credit card number via the camera.
- Credit/debit card number validation.
- Detection of card network type via the card number.
- User interface for showing back-of-card information.

<img src="https://cloud.githubusercontent.com/assets/176081/16175727/aed15f00-362a-11e6-855a-8bca4224a149.png" alt="Card Tray" width="320" height="568">

<img src="https://cloud.githubusercontent.com/assets/176081/16175729/be0a0ddc-362a-11e6-9252-c8817dfc5838.png" alt="Card Transactions" width="320" height="568">

### Known Issues and Limitations

- When dragging cards to re-order, sometimes the card was drawn at the top for a very brief moment before the snapping animation kicks in. This is probably a limitation of UIKit – may need to re-visit implementation with SceneKit.
- Card type detection only works for Visa and MasterCard.
- Card scanning does not read the cardholder name nor expiry date. This is a limitation of the Card.IO library.
- There is no backend connectivity implemented, hence the transaction list and services options are dummy values.
- There is no support for iPad.
- Accessibility support is very poor. E.g. there is no VoiceOver support on the card list and there is no support for people who uses a [switch control](https://support.apple.com/en-sg/HT201370).

## Requirements

 - iOS 9.3.2
 - Xcode 7.3.1
 - iPhone

### Not mandatory but good to have
 - [Affinity Designer](https://itunes.apple.com/app/affinity-designer/id824171161?mt=12&at=10lvzo&ct=chzmv).
 - Some credit cards, preferably Visa or MasterCard.

## Getting started

1. Open workspace `CardTrayDemo.xcworkspace` (**not** the project file since this relies on [Cocoapods](https://cocoapods.org)).
2. Press the Play button in Xcode to build and run for the Simulator.
3. Enjoy the card demo!

### Folder Structure

- `CardTrayDemo` – Demo app sources.
- `CardTray` – Framework sources.
- `CardTrayTests` – Unit tests for the `CardTray` framework.
- `assets` – original files for the icon and button glyphs.
- `Pods` – Cocoapods-managed sources.

## Terms of Use

Copyright(C) 2016 [Sasmito Adibowo](http://cutecoder.org). Licensed under GPL v3 – see `LICENSE.md` for details.

If you are in a job interview and the company request you to do a *new unpaid project* as part of the hiring process, **feel free to plagiarize this project** — remove my name from the source files and submit them "as is" *without further modification*. For any other uses, the GPL license applies. Please send me a postcard if you get hired because of my work.

Why am I encouraging plagiarism? Mainly because I feel that companies that requests "free work" as part of an interview process are engaging in unethical behavior. They show a **lack of respect of your time** and devalue programmers in general. This practice has reduced the value of artists, musicians, designers, and now the same is coming to software engineers. I feel that it's about time we push back.
