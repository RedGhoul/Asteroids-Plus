import SwiftUI
import SpriteKit

struct ContentView: View {

    func scene(for geometry: GeometryProxy) -> SKScene {
        let scene = MainMenuScene()
        scene.size = geometry.size
        scene.scaleMode = .aspectFill

        // Pass safe area insets to scene
        scene.userData = NSMutableDictionary()
        scene.userData?["safeAreaTop"] = geometry.safeAreaInsets.top
        scene.userData?["safeAreaBottom"] = geometry.safeAreaInsets.bottom
        scene.userData?["safeAreaLeading"] = geometry.safeAreaInsets.leading
        scene.userData?["safeAreaTrailing"] = geometry.safeAreaInsets.trailing

        return scene
     }

    var body: some View {
        GeometryReader { geometry in
            SpriteView(scene: scene(for: geometry))
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
