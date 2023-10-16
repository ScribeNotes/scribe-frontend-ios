import Foundation
import PencilKit

func PKDrawingToSVG(drawing: PKDrawing) -> String {
    let bounds = drawing.bounds
    func getRelative(_ point: CGPoint) -> CGPoint{
        return CGPoint(x: (point.x - bounds.origin.x), y: (point.y - bounds.origin.y))
    }
    
    var svg = "<svg width=\"\(Int(bounds.width))\" height=\"\(Int(bounds.height))\" xmlns=\"http://www.w3.org/2000/svg\">"

    for stroke in drawing.strokes {
        var path = "<path d=\"M"

        if stroke.path.count >= 3 {
            // Start with the first point
            let firstPoint = getRelative(stroke.path[0].location)
            path += "\(firstPoint.x) \(firstPoint.y)"

            // Use a cubic B-spline for the path
            for i in 1..<stroke.path.count - 2 {
                let p0 = getRelative(stroke.path[i - 1].location)
                let p1 = getRelative(stroke.path[i].location)
                let p2 = getRelative(stroke.path[i + 1].location)
                let p3 = getRelative(stroke.path[i + 2].location)

                // Calculate B-spline control points
                let controlPoint1 = CGPoint(
                    x: (p1.x + p2.x) / 2,
                    y: (p1.y + p2.y) / 2)
                
                let controlPoint2 = CGPoint(
                    x: (p1.x + p2.x) / 2,
                    y: (p1.y + p2.y) / 2)

                path += " S \(controlPoint1.x) \(controlPoint1.y), \(p2.x) \(p2.y)"
//                  path += " C \(controlPoint1.x) \(controlPoint1.y), \(controlPoint2.x) \(controlPoint2.y), \(p2.x) \(p2.y)"
            }

            // End with the last point
            let lastPoint = getRelative(stroke.path[stroke.path.count - 1].location)
            path += " L \(lastPoint.x) \(lastPoint.y)"
        }

        path += "\" stroke=\"black\" stroke-width=\"\(1)\" fill=\"none\" />"
        svg += path
    }

    svg += "</svg>"
    return svg
}
