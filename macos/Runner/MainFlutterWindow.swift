import Cocoa
import FlutterMacOS
#if canImport(LaunchAtLogin)
import LaunchAtLogin
#endif

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    FlutterMethodChannel(
      name: "launch_at_startup", binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    .setMethodCallHandler { call, result in
      switch call.method {
      case "launchAtStartupIsEnabled":
        #if canImport(LaunchAtLogin)
        result(LaunchAtLogin.isEnabled)
        #else
        result(false)
        #endif
      case "launchAtStartupSetEnabled":
        #if canImport(LaunchAtLogin)
        if let arguments = call.arguments as? [String: Any],
          let setEnabledValue = arguments["setEnabledValue"] as? Bool {
          LaunchAtLogin.isEnabled = setEnabledValue
          result(nil)
        } else {
          result(
            FlutterError(
              code: "invalid_args",
              message: "setEnabledValue is required",
              details: nil
            )
          )
        }
        #else
        result(
          FlutterError(
            code: "launch_at_login_unavailable",
            message: "LaunchAtLogin SPM package is not installed",
            details: nil
          )
        )
        #endif
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
