import Flutter
import UIKit
import caresoft_customer_voice

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
 override func application(_ application: UIApplication,didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey:Any]?)->Bool {
  if let url=Bundle.main.url(forResource:"voice_config",withExtension:"json"),let data=try? Data(contentsOf:url),let config=(try? JSONSerialization.jsonObject(with:data)) as? [String:Any],let backend=config["backendUrl"] as? String,let backendURL=URL(string:backend),let account=config["accountId"] as? String,!account.isEmpty,let app=config["appId"] as? String,!app.isEmpty {
   do {try VoiceBootstrap.initialize(backendURL:backendURL,accountID:account,appID:app,supportName:config["supportName"] as? String ?? "Chăm sóc khách hàng",environment:config["pushEnvironment"] as? String == "sandbox" ? .sandbox:.production)} catch {/* Home reports unavailable configuration; never log credentials. */}
  }
  return super.application(application,didFinishLaunchingWithOptions:launchOptions)
 }
 func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {GeneratedPluginRegistrant.register(with:engineBridge.pluginRegistry)}
 override func application(_ application: UIApplication,didRegisterForRemoteNotificationsWithDeviceToken token: Data) {
  VoiceBootstrap.didRegisterForRemoteNotifications(deviceToken:token)
  super.application(application,didRegisterForRemoteNotificationsWithDeviceToken:token)
 }
 override func application(_ application: UIApplication,didReceiveRemoteNotification payload: [AnyHashable:Any],fetchCompletionHandler done:@escaping(UIBackgroundFetchResult)->Void) {
  Task {@MainActor in
   if await VoiceBootstrap.handleRemoteNotification(payload) {done(.newData)}
   else {super.application(application,didReceiveRemoteNotification:payload,fetchCompletionHandler:done)}
  }
 }
}
