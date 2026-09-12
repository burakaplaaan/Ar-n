import UIKit

/// CarPlay Voice Control için 150pt hilâl — ChatGPT topunun değil, ayın dili.
enum ArinHilalOrb {
  enum State: String {
    case idle
    case listening
    case thinking
    case speaking
    case locked
  }

  static func image(for state: State) -> UIImage {
    let frames = (0..<12).map { frame in
      render(state: state, frame: frame, total: 12)
    }
    let duration: TimeInterval
    switch state {
    case .idle: duration = 2.8
    case .listening: duration = 1.1
    case .thinking: duration = 1.8
    case .speaking: duration = 0.9
    case .locked: duration = 3.2
    }
    return UIImage.animatedImage(with: frames, duration: duration) ?? frames[0]
  }

  private static func render(state: State, frame: Int, total: Int) -> UIImage {
    let size = CGSize(width: 150, height: 150)
    let renderer = UIGraphicsImageRenderer(size: size)
    let t = CGFloat(frame) / CGFloat(max(1, total - 1))
    return renderer.image { ctx in
      let cg = ctx.cgContext
      cg.setAllowsAntialiasing(true)
      let center = CGPoint(x: 75, y: 75)

      switch state {
      case .idle:
        drawHalo(cg, center: center, radius: 48 + 3 * sin(t * .pi), alpha: 0.18)
        drawCrescent(cg, center: center, radius: 34, phase: 0.12)
      case .listening:
        let pulse = 0.55 + 0.45 * sin(t * .pi)
        drawHalo(cg, center: center, radius: 52 + 16 * pulse, alpha: 0.10 + 0.16 * pulse)
        drawHalo(cg, center: center, radius: 40 + 8 * pulse, alpha: 0.22)
        drawCrescent(cg, center: center, radius: 32 + 4 * pulse, phase: 0.08)
      case .thinking:
        drawHalo(cg, center: center, radius: 50, alpha: 0.14)
        cg.saveGState()
        cg.translateBy(x: center.x, y: center.y)
        cg.rotate(by: t * .pi * 0.7)
        cg.translateBy(x: -center.x, y: -center.y)
        drawCrescent(cg, center: center, radius: 33, phase: 0.18)
        cg.restoreGState()
      case .speaking:
        let w = 0.35 + 0.65 * abs(sin(t * .pi * 2))
        drawArc(cg, center: center, radius: 46, width: w)
        drawArc(cg, center: center, radius: 58, width: w * 0.55)
        drawCrescent(cg, center: center, radius: 32 + 3 * w, phase: 0.1)
      case .locked:
        drawHalo(cg, center: center, radius: 50, alpha: 0.12)
        drawCrescent(cg, center: center, radius: 30, phase: 0.2, alpha: 0.55)
        drawLock(cg, center: CGPoint(x: 75, y: 86))
      }
    }
  }

  private static func drawHalo(
    _ cg: CGContext,
    center: CGPoint,
    radius: CGFloat,
    alpha: CGFloat
  ) {
    cg.setStrokeColor(UIColor(red: 0.72, green: 0.86, blue: 0.74, alpha: alpha).cgColor)
    cg.setLineWidth(1.4)
    cg.strokeEllipse(in: CGRect(
      x: center.x - radius,
      y: center.y - radius,
      width: radius * 2,
      height: radius * 2
    ))
  }

  private static func drawCrescent(
    _ cg: CGContext,
    center: CGPoint,
    radius: CGFloat,
    phase: CGFloat,
    alpha: CGFloat = 0.96
  ) {
    let outer = CGRect(
      x: center.x - radius,
      y: center.y - radius,
      width: radius * 2,
      height: radius * 2
    )
    let cutR = radius * 0.86
    let cut = CGRect(
      x: center.x - cutR + radius * (0.34 + phase),
      y: center.y - cutR - radius * 0.04,
      width: cutR * 2,
      height: cutR * 2
    )
    cg.saveGState()
    let path = CGMutablePath()
    path.addEllipse(in: outer)
    path.addEllipse(in: cut)
    cg.addPath(path)
    cg.setFillColor(UIColor(red: 0.86, green: 0.93, blue: 0.84, alpha: alpha).cgColor)
    cg.drawPath(using: .eoFill)
    cg.restoreGState()
  }

  private static func drawArc(
    _ cg: CGContext,
    center: CGPoint,
    radius: CGFloat,
    width: CGFloat
  ) {
    cg.setStrokeColor(UIColor(red: 0.78, green: 0.90, blue: 0.80, alpha: 0.28 + 0.4 * width).cgColor)
    cg.setLineWidth(1.6 + width)
    cg.setLineCap(.round)
    cg.addArc(
      center: center,
      radius: radius,
      startAngle: -.pi * 0.28,
      endAngle: .pi * 0.28,
      clockwise: false
    )
    cg.strokePath()
  }

  private static func drawLock(_ cg: CGContext, center: CGPoint) {
    let body = CGRect(x: center.x - 8, y: center.y - 2, width: 16, height: 13)
    cg.setStrokeColor(UIColor(white: 0.92, alpha: 0.9).cgColor)
    cg.setLineWidth(1.6)
    cg.stroke(body, width: 1.6)
    cg.addArc(
      center: CGPoint(x: center.x, y: center.y - 2),
      radius: 5.2,
      startAngle: .pi,
      endAngle: 0,
      clockwise: false
    )
    cg.strokePath()
  }
}
