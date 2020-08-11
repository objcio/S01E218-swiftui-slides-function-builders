//
//  ContentView.swift
//  Slides
//
//  Created by Chris Eidhof on 11.08.20.
//  Copyright © 2020 Chris Eidhof. All rights reserved.
//

import SwiftUI

struct SlideContainer<S: Slides, Theme: ViewModifier>: View {
    var slides: S
    var theme: Theme
    @State var currentSlide = 0
    @State var numberOfSteps = 1
    @State var currentStep = 0
    
    init(@SlideBuilder slides: () -> S, theme: Theme) {
        self.slides = slides()
        self.theme = theme
    }
    
    func previous() {
        if currentSlide > 0  {
            currentSlide -= 1
            currentStep = 0
        }
    }
    
    func next() {
        if currentStep + 1 < numberOfSteps {
            withAnimation(.default) {
                currentStep += 1
            }
        } else if currentSlide + 1 < slides.count {
            currentSlide += 1
            currentStep = 0
        }
    }
    
    var body: some View {
        VStack(spacing: 30) {
            HStack {
                Button("Previous") { self.previous() }
                Text("Slide \(currentSlide + 1) of \(slides.count) — Step \(currentStep + 1) of \(numberOfSteps)")
                Button("Next") { self.next() }
            }
            slides.slide(at: currentSlide)
                .onPreferenceChange(StepsKey.self, perform: {
                    self.numberOfSteps = $0
                })
                .environment(\.currentStep, currentStep)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .modifier(theme)
                .aspectRatio(CGSize(width: 16, height: 9), contentMode: .fit)
                .border(Color.black)
        }
    }
}

extension SlideContainer where Theme == EmptyModifier {
    init(@SlideBuilder slides: () -> S) {
        self.init(slides: slides, theme: .identity)
    }
}

struct MyTheme: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(.white)
            .background(Color.blue)
            .font(.custom("Avenir", size: 48))
    
        
    }
}

struct StepsKey: PreferenceKey {
    static let defaultValue: Int = 1
    static func reduce(value: inout Int, nextValue: () -> Int) {
        value = nextValue()
    }
}

struct CurrentStepKey: EnvironmentKey {
    static let defaultValue = 1
}

extension EnvironmentValues {
    var currentStep: Int {
        get { self[CurrentStepKey.self] }
        set { self[CurrentStepKey.self] = newValue }
    }
}

struct Slide<Content: View>: View {
    var steps: Int = 1
    let content: (Int) -> Content
    @Environment(\.currentStep) var step: Int
    
    var body: some View {
        content(step)
            .preference(key: StepsKey.self, value: steps)
    }
}

struct ImageSlide: View {
    var body: some View {
        Slide(steps: 2) { step in
            Image(systemName: "tortoise")
                .frame(maxWidth: .infinity, alignment: step > 0 ? .trailing :  .leading)
                .padding(50)
        }
            
    }
}

protocol Slides {
    associatedtype V: View
    func slide(at index: Int) -> V
    var count: Int { get }
}

struct Single<Content: View>: Slides {
    let view: Content
    let count = 1
    
    func slide(at index: Int) -> some View {
        view
    }
}

struct Pair<First: View, Second: Slides>: Slides {
    let first: First
    let remainder: Second
    var count: Int {
        remainder.count +  1
    }
    
    func slide(at index: Int) -> some View {
        Group {
            if index == 0 {
                first
            } else {
                remainder.slide(at: index-1)
            }
        }
    }
}

@_functionBuilder enum SlideBuilder {
    public static func buildBlock<Content>(_ content: Content) -> some Slides where Content : View {
        Single(view: content)
    }
    
    public static func buildBlock<C0, C1>(_ c0: C0, _ c1: C1) -> some Slides where C0 : View, C1 : View {
        Pair(first: c0, remainder: Single(view: c1))
    }
    
    public static func buildBlock<C0, C1, C2>(_ c0: C0, _ c1: C1, _ c2: C2) -> some Slides where C0 : View, C1 : View, C2: View {
        Pair(first: c0, remainder: Pair(first: c1, remainder: Single(view: c2)))
    }
}

struct ContentView: View {
    var body: some View {
        SlideContainer(slides: {
            Text("Hello, World!")
            ImageSlide()
            Slide(steps: 2) { step in
                HStack {
                    Text("Hello")
                    if step > 0 {
                        Text("World")
                    }
                }
            }
        }, theme: MyTheme())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
