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
        VStack {
            Text("\(value)")
                .font(.system(size: 25, weight: .bold))
                .foregroundColor(.primary)
                .frame(minWidth: 45, alignment: .center)
                .transition(.asymmetric(
                    insertion: .move(edge: animationDirection == .up ? .top : .bottom)
                        .combined(with: .opacity),
                    removal: .move(edge: animationDirection == .up ? .bottom : .top)
                        .combined(with: .opacity)
                ))
                .id("value-\(value)")

            HStack(spacing: 8) {
                Button(action: decrementValue) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(value > 0 ? Color.red : Color.gray.opacity(0.3))
                            .frame(width: 40, height: 40)

                        Image(systemName: "minus")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                    }
                }
                .disabled(value <= 0)
                .scaleEffect(value > 0 ? 1.0 : 0.8)
                .animation(.easeInOut(duration: 0.1), value: value)

                Button(action: incrementValue) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.blue)
                            .frame(width: 40, height: 40)

                        Image(systemName: "plus")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                    }
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
