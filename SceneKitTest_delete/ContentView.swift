//
//  ContentView.swift
//  SceneKitTest_delete
//
//  Created by Daniel Dähling on 04.08.20.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .center) {
                SceneKitObjectRepresentable()
                    .frame(width: proxy.size.width - 30, height: proxy.size.width - 30)
            }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
