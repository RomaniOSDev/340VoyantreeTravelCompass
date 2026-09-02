import SwiftUI

extension View {
    func screenBackdrop(_ imageName: String) -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                AppTheme.background
                    .overlay {
                        Image(imageName)
                            .resizable()
                            .scaledToFill()
                            .opacity(0.14)
                    }
                    .overlay {
                        CompassChartMesh()
                    }
                    .clipped()
                    .ignoresSafeArea()
            }
    }
}

private struct CompassChartMesh: View {
    var body: some View {
        GeometryReader { geo in
            let origin = CGPoint(x: geo.size.width * 0.9, y: geo.size.height * 0.08)
            Canvas { context, size in
                let gold = Color("AppPrimary")
                for index in 1...7 {
                    let radius = CGFloat(index) * min(size.width, size.height) * 0.075
                    var ring = Path()
                    ring.addEllipse(in: CGRect(
                        x: origin.x - radius,
                        y: origin.y - radius,
                        width: radius * 2,
                        height: radius * 2
                    ))
                    context.stroke(ring, with: .color(gold.opacity(index == 3 ? 0.16 : 0.07)), lineWidth: 0.8)
                }

                var axes = Path()
                axes.move(to: CGPoint(x: origin.x, y: 0))
                axes.addLine(to: CGPoint(x: origin.x, y: size.height))
                axes.move(to: CGPoint(x: 0, y: origin.y))
                axes.addLine(to: CGPoint(x: size.width, y: origin.y))
                context.stroke(axes, with: .color(gold.opacity(0.08)), lineWidth: 0.7)

                var diagonal = Path()
                diagonal.move(to: .zero)
                diagonal.addLine(to: CGPoint(x: size.width, y: size.height * 0.55))
                context.stroke(
                    diagonal,
                    with: .color(gold.opacity(0.06)),
                    style: StrokeStyle(lineWidth: 0.7, dash: [5, 6])
                )
            }
            .allowsHitTesting(false)
        }
        .allowsHitTesting(false)
    }
}
