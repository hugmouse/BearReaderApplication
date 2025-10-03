# Bear Reader – Privacy Policy

**Last Updated:** October 3, 2025

## Overview

This Privacy Policy explains how Bear Reader handles your information.

## Information We Do NOT Collect

Bear Reader does not collect, process, or transmit any personal information, including:
- No user accounts or authentication
- No personal identifiers (name, email, phone number)
- No device identifiers or advertising IDs
- No analytics or usage tracking
- No location data
- No behavioral profiling

## Network Communication

Bear Reader communicates with external servers only to fetch public blog content:

- **Blog Content**: Bear Reader retrieves publicly available blog posts from BearBlog (https://bearblog.dev) or other user-configured blog discovery services
- **Images**: Blog post images, video thumbnails are downloaded from their respective URLs
- **User-Agent Header**: Network requests include a User-Agent identifier ("BearReader/1.0") to identify Bear Reader to web servers

Bear Reader only makes READ requests (GET) and does not submit any user data, comments, or interactions to external servers.

## Local Data Storage

All user data remains exclusively on your device:

- **Reading History**: Bear Reader stores which posts you've viewed and when, using a local SQLite database
- **Bookmarks**: Your bookmarked posts are saved locally
- **Preferences**: App settings (service URL, display preferences) are stored in local app storage
- **Cache**: Blog content and images are cached locally for offline reading (HTTP cache: 1GB disk, 50MB memory; Image cache: 7-day retention)

This data is stored only on your device and is never transmitted to external servers or cloud services.

## Third-Party Libraries

Bear Reader uses the following open-source libraries for functionality:

- **SwiftSoup** - For parsing HTML content locally
- **SQLite.swift** - For local database management
- **Kingfisher** - For image downloading and local caching
- **SelectableText** - For text selection UI

Additional open-source libraries used internally by those dependencies: swift-toolchain-sqlite, swift-atomics, LRUCache.

These libraries operate locally and do not collect or transmit user data.

Libraries licenses can be found in README.md, available at: https://github.com/hugmouse/BearReaderApplication/blob/master/README.md

## Permissions

The App requests the following permission only when needed:

- **Photo Library (Write Only)**: Required only when you choose to save an image to your Photos. This permission is requested at the time of use and is entirely optional.

The App does NOT request or use:
- Camera access
- Location services
- Microphone access
- Contacts, calendar, or reminders
- Push notifications

## Data Sharing

The App does not share any data with third parties. All data remains on your device.

## Data Retention and Deletion

- All locally stored data remains on your device until you delete Bear Reader
- You can clear cached content by deleting and reinstalling Bear Reader
- You can also clear all stored data in Profile -> Storage -> Delete All Data
- No data is retained on external servers

## Contact

For questions about this Privacy Policy, please contact us through our GitHub repository at https://github.com/hugmouse/BearReaderApplication

App Store related issues can be reported directly to: app-store-contact@mysh.dev
