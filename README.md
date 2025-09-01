# Bear Reader

**Warning**: There's no official release on App Store just yet. Screenshots will be added later.

SwiftUI-based iOS/iPadOS Bear Blog Reader. Optimized for iPhone SE. Supports iOS 17, 18 and 26. iPadOS is supported too, but not as a primary target.

## Features

- Built for offline use: open a post to cache it, read it when you feel like it
- Fully local search: no requests to remote server, only on posts that you encountered
- Export your data: everything – besides images cache and post cache – is stored in one SQLite3 file that you can easily export in Profile tab
- Accessible: every view is tested manually with VoiceOver and custom font size; every view is designed with high contrast in mind

And many small features like history, bookmarks, cache settings, custom parsing (using CSS selectors), various sharing options and more.

## Roadmap

I work on this in my free time – there will be no concrete timing on when those features will be implemented.

- Add view for viewing someone's blog: users can browse someone's blog to see their posts
- Add view for subscribing to blogs: so the one can read their favorite author
- Add ability to search for text inside of a post
- Reimplement menu that opens on long-tap on an image inside of a post for iOS 26 - currently it fully hides the image

## Contributing

Make sure that you have `git lfs` installed since JPGs, PNGs are stored in LFS.

There are no strict guidelines, but make sure to follow these when:

### Adding anything

- Release build uses `-Ofast` flag, which means "Fastest, aggressive optimizations". Check if your code still works with this flag being set. If not, document the behavior and open PR anyway.
- Make sure that your code compiles with Swift 6.0: https://www.swift.org/migration/documentation/migrationguide
- Warnings are treated as errors, so make sure not to have any warnings (like usage of deprecated functions)
- If possible, avoid creating code that requires being run on a main thread
- Write code that is concurrency-safe
- Use of `nonisolated(unsafe)` is discouraged

### Adding a new view

- Check your view for accessibility: with VoiceOver, custom font size and if it has good contrast ratio
- Check if your view looks good with different orientations
- Check if your view looks good on small screens (like iPhone SE) and big ones (like iPhone 17 Pro Max)
- Check if the view has any expensive calculations: you might need to move it to the background thread
- Check if your view looks alright both on iOS 18 and iOS 26
- If view introduces a new feature that requires network requests: 
- - See if you can cache the response
- - See if it is possible to use it offline

## License

Apache 2.0 License: https://www.apache.org/licenses/LICENSE-2.0.txt

Additionally I have a permission from Herman – Bear Blog owner and creator – to use his site for parsing purposes to display the results in the app.

- Any additional features that require usage of bearblog.dev endpoints should be discussed prior to implementation.
- Any additional dependencies that are not compatible with Apache 2.0 license should either be avoided or be granted an exclusive license for use in this project.

This project includes the following dependencies:

- SwiftSoup (MIT)
- swift-toolchain-sqlite (Apache 2.0)
- swift-atomics (Apache 2.0)
- SQLite.swift (MIT)
- SelectableText (MIT)
- LRUCache (MIT)
- Kingfisher (MIT)
