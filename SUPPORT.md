# Bear Reader Support

This page provides help and resources for using Bear Reader, an open-source iOS/iPadOS reader for Bear Blog.

## Contact & Support

### Get Help

- **Report Issues**: [GitHub Issues](https://github.com/hugmouse/BearReaderApplication/issues)
- **Feature Requests**: [GitHub Issues](https://github.com/hugmouse/BearReaderApplication/issues)
- **Source Code**: [GitHub Repository](https://github.com/hugmouse/BearReaderApplication)

When reporting issues, please include:

- Your iOS/iPadOS version
- Your device model
- App version (found in Profile → About)
- Steps to reproduce the issue
- Screenshots if applicable

## Frequently Asked Questions

### General Questions

**Q: Is this affiliated with Bear Blog?**

A: No, this is an independent third-party reader. Bear Reader has permission from Bear Blog's – Herman Martinus creator to parse and display content.

**Q: How much does it cost?**

A: Bear Reader is completely free and open-source under the Apache 2.0 license.

### Using the App

**Q: How do I read posts offline?**

A: Simply open any post to cache it. Cached posts can be read without an internet connection.

**Q: How does search work?**

A: Search is completely local and only works on posts you've already encountered in Trending/Recent/Blogs tabs. No search requests are sent to remote servers.

**Q: How do I subscribe to blogs?**
A: Tap on any post to open it, then tap on "burger menu" on the top right and you will see a button that allows you to subscribe to author's blog. You'll be able to see their latest posts in Blogs tab.

**Q: How do I export my data?**

A: Go to Profile tab and use the export feature. All your data (except images and post cache) is stored in a single SQLite3 file.

**Q: Can I adjust text size?**

A: Yes! Bear Reader supports Dynamic Type. Change your system text size in Settings → Display & Brightness → Text Size.

### Troubleshooting

**Q: Posts/Blogs aren't loading**

A:
- Check your internet connection
- Try force-closing and reopening the app
- Clear app cache in Profile → Setting

**Q: Search isn't finding my posts**

A: Remember that search only works on posts you've previously encountered in Trending/Recent/Blogs tabs.

**Q: Images aren't displaying**

A:
- Check your internet connection for initial image load
- Check cache settings in Profile → Cache Settings
- Try clearing image cache and reloading
- In some rare cases, the image that you are trying to load is not supported by iOS:
  - To make sure, you can check it in the browser (if it loads in the browser – it should load in the app)

**Q: VoiceOver or other accessibility issues**

A: If you encounter accessibility issues, please report them via GitHub Issues. I'll try my best to fix them asap.

### Privacy & Data

**Q: What data does the app collect?**

A: See [Privacy Policy](https://github.com/hugmouse/BearReaderApplication/blob/master/PRIVACY.md) for complete details.

## Technical Support

### System Requirements

- iOS 17 or later
- iPadOS 17 or later

Check [GitHub Issues](https://github.com/hugmouse/BearReaderApplication/issues) for current known issues and their status.

## Bear Blog Resources

Bear Reader is a client for Bear Blog. For questions about Bear Blog itself:

- **Bear Blog**: [https://bearblog.dev](https://bearblog.dev)
- **Bear Blog Privacy Policy**: [https://docs.bearblog.dev/privacy-policy/](https://docs.bearblog.dev/privacy-policy/)
- **Bear Blog Terms of Service**: [https://docs.bearblog.dev/terms-of-service/](https://docs.bearblog.dev/terms-of-service/)

## License & Legal

- **App License**: [Apache 2.0](https://github.com/hugmouse/BearReaderApplication/blob/master/LICENSE)
- **Dependencies**: View all dependency licenses in the app under Profile → About → Dependencies and licenses
- **Parsing Permission**: Bear Reader has explicit permission from Bear Blog's creator to parse bearblog.dev for display purposes

## Version Information

You can find your current app version in:
Profile → About → Version

---

**Still need help?** Open an issue on [GitHub](https://github.com/hugmouse/BearReaderApplication/issues) and we'll assist you as soon as possible.
