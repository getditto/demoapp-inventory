# Inventory

Demo app for showcasing Ditto's real-time sync and Conflict Resolution through the use of an inventory counter.

This inventory demo showcases the smoothness of Ditto's sync and conflict resolution, and how counters work with Ditto. You can also open up the Presence Viewer to see all existing devices and connections in the mesh.

Powered by [Ditto](https://www.ditto.live/).

For support, please contact Ditto Support (<support@ditto.live>).

- [Demo Video](https://www.youtube.com/watch?v=1P2bKEJjdec)
- [iOS Download](https://apps.apple.com/us/app/ditto-inventory/id1449905935)
- [Android Download](https://play.google.com/store/apps/details?id=live.ditto.inventory)


## How to build the apps

### Environment Variables
1. Copy the `.env.template` file to `.env`.
   - in a terminal: `cp .env.template .env`.
   - in a macOS Finder window, press `⇧⌘.` (SHIFT+CMD+period) to show hidden files.
1. Save your App ID, Online Playground Token, Auth URL, and WebSocket URL in the `.env` file.
### iOS

1. Open the app project on Xcode and clean (<kbd>Command</kbd> + <kbd>Shift</kbd> + <kbd>K</kbd>)
2. Build (<kbd>Command</kbd> + <kbd>B</kbd>)
    - This will generate `Env.swift`

### Android

Android looks at the same .env file that iOS does.  When gradle restores packages, it should auto load in the information from the .env file to the BuildConfig.  DittoManager then reads these values and uses them to connect to Ditto.  

For more information, see the [build.gradle](Android/app/build.gradle#L20) file.

Compatible with Android Automotive OS (AAOS)

## License

MIT
