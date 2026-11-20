import Flutter
import UIKit
import caresoft_customer_voice

class SceneDelegate: FlutterSceneDelegate {
 override func scene(_ scene: UIScene,willConnectTo session: UISceneSession,options connectionOptions: UIScene.ConnectionOptions) {
  // A reused Bundle ID can restore a scene from a host that had no storyboard.
  if window?.rootViewController==nil,let scene=scene as? UIWindowScene {
   let host=UIWindow(windowScene:scene)
   host.rootViewController=UIStoryboard(name:"Main",bundle:nil).instantiateInitialViewController()
   window=host;host.makeKeyAndVisible()
  }
  super.scene(scene,willConnectTo:session,options:connectionOptions)
 }
 override func sceneDidBecomeActive(_ scene: UIScene) {
  super.sceneDidBecomeActive(scene)
  if let host=window?.rootViewController {VoiceBootstrap.attach(to:host)}
  VoiceBootstrap.resume()
 }
}
