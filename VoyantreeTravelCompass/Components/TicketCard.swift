import SwiftUI

struct TicketShape: Shape {
    var notchRadius: CGFloat = 9
    var cornerRadius: CGFloat = 12

    func path(in rect: CGRect) -> Path {
        let corner = min(cornerRadius, rect.height / 3, rect.width / 4)
        let notch = min(notchRadius, rect.height / 4)
        let notchY = rect.midY
        var path = Path()

        path.move(to: CGPoint(x: rect.minX + corner, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - corner, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + corner),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: notchY - notch))
        path.addArc(
            center: CGPoint(x: rect.maxX, y: notchY),
            radius: notch,
            startAngle: .degrees(-90),
            endAngle: .degrees(90),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - corner))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - corner, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX + corner, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - corner),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX, y: notchY + notch))
        path.addArc(
            center: CGPoint(x: rect.minX, y: notchY),
            radius: notch,
            startAngle: .degrees(90),
            endAngle: .degrees(-90),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + corner))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + corner, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.closeSubpath()
        return path
    }
}

struct CompassDial: View {
    var size: CGFloat = 36
    var headingDegrees: Double? = nil
    var targetBearing: Double? = nil

    private var roseRotation: Double {
        -(headingDegrees ?? 0)
    }

    private var needleRotation: Double {
        if let targetBearing {
            return targetBearing - (headingDegrees ?? 0)
        }
        return -18
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.primary.opacity(0.28), lineWidth: 1)
            Circle()
                .stroke(AppTheme.primary.opacity(0.7), lineWidth: 1.2)
                .padding(3)
            Circle()
                .stroke(AppTheme.primary.opacity(0.2), style: StrokeStyle(lineWidth: 0.8, dash: [2, 2]))
                .padding(7)
            if headingDegrees != nil || targetBearing != nil {
                cardinals
                    .rotationEffect(.degrees(roseRotation))
            }
            Image(systemName: "location.north.fill")
                .font(.system(size: size * 0.32, weight: .bold))
                .foregroundStyle(AppTheme.goldLift)
                .rotationEffect(.degrees(needleRotation))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
        .animation(.easeOut(duration: 0.18), value: headingDegrees)
        .animation(.easeOut(duration: 0.18), value: targetBearing)
    }

    private var cardinals: some View {
        ZStack {
            Text("N")
                .offset(y: -size * 0.38)
            Text("S")
                .offset(y: size * 0.38)
            Text("E")
                .offset(x: size * 0.38)
            Text("W")
                .offset(x: -size * 0.38)
        }
        .font(.system(size: max(8, size * 0.11), weight: .bold, design: .rounded))
        .foregroundColor(AppTheme.primary)
    }
}

struct LiveBearingCompass: View {
    var heading: Double?
    var bearing: Double?
    var size: CGFloat = 196

    var body: some View {
        CompassDial(size: size, headingDegrees: heading, targetBearing: bearing)
            .overlay {
                Circle()
                    .stroke(AppTheme.primary.opacity(0.12), lineWidth: 18)
                    .padding(10)
            }
    }
}

struct TicketCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(.horizontal, 18)
            .padding(.vertical, 15)
            .background {
                TicketShape()
                    .fill(AppTheme.nightPanel)
                    .overlay {
                        TicketShape()
                            .stroke(AppTheme.primary.opacity(0.62), lineWidth: 1.15)
                    }
                    .overlay {
                        TicketShape()
                            .stroke(AppTheme.primary.opacity(0.18), style: StrokeStyle(lineWidth: 0.8, dash: [3, 3]))
                            .padding(4)
                    }
                    .shadow(color: Color.black.opacity(0.35), radius: 10, y: 7)
            }
    }
}

struct GoldActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AppTheme.goldLift)
                    Image(systemName: systemImage)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(AppTheme.background)
                }
                .frame(width: 36, height: 36)
                Text(title)
                    .font(.headline)
                    .foregroundColor(AppTheme.primary)
                Spacer(minLength: 0)
                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.primary.opacity(0.8))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                TicketShape(notchRadius: 8, cornerRadius: 16)
                    .fill(AppTheme.surface.opacity(0.92))
                    .overlay {
                        TicketShape(notchRadius: 8, cornerRadius: 16)
                            .stroke(AppTheme.goldLift, lineWidth: 1.4)
                    }
                    .shadow(color: AppTheme.primary.opacity(0.22), radius: 8, y: 4)
            }
        }
        .buttonStyle(GoldPressStyle())
        .frame(minHeight: 44)
    }
}

struct CompassChip: View {
    let title: String
    var selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(AppTheme.trackedLabel)
                .tracking(0.8)
                .padding(.horizontal, 12)
                .frame(minHeight: 36)
                .background {
                    TicketShape(notchRadius: 5, cornerRadius: 8)
                        .fill(selected ? AppTheme.primary.opacity(0.22) : AppTheme.surface.opacity(0.82))
                }
                .overlay {
                    TicketShape(notchRadius: 5, cornerRadius: 8)
                        .stroke(AppTheme.primary.opacity(selected ? 0.85 : 0.28), lineWidth: 1)
                }
                .foregroundColor(.primary)
        }
        .buttonStyle(.plain)
    }
}

extension View {
    func ticketClip(height: CGFloat) -> some View {
        self
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .clipped()
            .clipShape(TicketShape(notchRadius: 11, cornerRadius: 14))
            .overlay {
                TicketShape(notchRadius: 11, cornerRadius: 14)
                    .stroke(AppTheme.primary.opacity(0.5), lineWidth: 1.1)
            }
            .shadow(color: .black.opacity(0.32), radius: 10, y: 5)
    }
}
