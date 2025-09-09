//
//  CustomStepper.swift
//  SwiftUIInventory
//
//  Created by Alexander on 2025-09-09.
//

import SwiftUI

struct CustomStepper: View {
    @Binding var value: Int
    let step: Int
    @State private var animationDirection: AnimationDirection = .none

    enum AnimationDirection {
        case none, up, down
    }

    init(value: Binding<Int>, step: Int = 1) {
        self._value = value
        self.step = step
    }

    var body: some View {
        HStack(spacing: 0) {
            Button(action: decrementValue) {
                ZStack {
                    Circle()
                        .fill(value > 0 ? Color.red : Color.gray.opacity(0.3))
                        .frame(width: 44, height: 44)

                    Image(systemName: "minus")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                }
            }
            .disabled(value <= 0)
            .scaleEffect(value > 0 ? 1.0 : 0.8)
            .animation(.easeInOut(duration: 0.1), value: value)

            ZStack {
                Text("\(value)")
                    .font(.title.bold())
                    .foregroundColor(.primary)
                    .frame(minWidth: 45)
                    .transition(.asymmetric(
                        insertion: .move(edge: animationDirection == .up ? .top : .bottom)
                            .combined(with: .opacity),
                        removal: .move(edge: animationDirection == .up ? .bottom : .top)
                            .combined(with: .opacity)
                    ))
                    .id("value-\(value)")
            }
            .clipped()

            Button(action: incrementValue) {
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 44, height: 44)

                    Image(systemName: "plus")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                }
            }
        }
    }

    private func incrementValue() {
        animationDirection = .up
        withAnimation(.easeInOut(duration: 0.3)) {
            value += step
        }
    }

    private func decrementValue() {
        if value > 0 {
            animationDirection = .down
            withAnimation(.easeInOut(duration: 0.3)) {
                value = max(0, value - step)
            }
        }
    }
}

#Preview {
    @Previewable @State var count = 0
    CustomStepper(value: $count, step: 1)
}
