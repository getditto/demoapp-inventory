# Inventory

Demo app for showcasing Ditto's real-time sync and Conflict Resolution through the use of an inventory counter.

This inventory demo showcases the smoothness of Ditto's sync and conflict resolution, and how counters work with Ditto. You can also open up the Presence Viewer to see all existing devices and connections in the mesh.

Powered by [Ditto](https://www.ditto.live/).

For support, please contact Ditto Support (<support@ditto.live>).

- [Demo Video](https://www.youtube.com/watch?v=1P2bKEJjdec)
- [iOS Download](https://apps.apple.com/us/app/ditto-inventory/id1449905935)
- [Android Download](https://play.google.com/store/apps/details?id=live.ditto.inventory)


## How to build the apps

### iOS

1. Run `cp .env.template .env` at the root directory
1. Edit `.env` to add environment variables
1. Open the app project on Xcode and clean (<kbd>Command</kbd> + <kbd>Shift</kbd> + <kbd>K</kbd>)
1. Build (<kbd>Command</kbd> + <kbd>B</kbd>)
    - This will generate `Env.swift`

### Android

1. Create a folder called `secure` in the `Android` directory.
2. In the `secure` folder add a file called `debug_creds.properties` with the following content:

```
APP_ID="your_app_id"
ONLINE_AUTH_TOKEN="your_playground_token"
```
3. Replace `your_app_id` and `your_playground_token` with your App ID and Online Playground token from the Ditto portal. Keep the double quotes!
4. You can now run the debug build of the app.

If you need to create a release build follow the same steps above, except create a file called `release_creds.properties`.

Compatible with Android Automotive OS (AAOS)

## License

MIT
