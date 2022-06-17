//
//  File.swift
//  
//
//  Created by Aaron Ge on 2022/6/10.
//

/// Contains the coordinates of a point in a 2D Cartesian coordinate system.
public struct Point: Hashable {
    /// The x-coordinate of the point.
    public var x: Double
    /// The y-coordinate of the point.
    public var y: Double
}

extension Array where Element == Point {
    /// Returns only the unique points in the array.
    var unique: [Point] {
        return Array(Set<Point>(self))
    }
}

/// Defines a polygon as a set of points and provides some utilities for working with the polygon.
public class Polygon {
    /// The points that form the polygon.
    public var points: [Point]
    
    init(points: [Point]) {
        self.points = points
    }
    
    /// Gives the x- and y-limits to form a bounding box around a polygon or line segment.
    private struct BoundingBox {
        /// The minimum x-value for the bounding box.
        internal var xMin: Double
        /// The maximum x-value for the bounding box.
        internal var xMax: Double
        /// The minimum y-value for the bounding box.
        internal var yMin: Double
        /// The maximum y-value for the bounding box.
        internal var yMax: Double
        
        /// Indicates whether the bounding box contains a given point.
        /// - parameter point: The point of interest.
        /// - returns: A boolean indicating whether the point is inside the bounding box.
        internal func contains(_ point: Point) -> Bool {
            if point.x > xMin, point.x < xMax, point.y > yMin, point.y < yMax {
                return true
            } else {
                return false
            }
        }
    }
    
    /// Defines a line segment as a pair of points.
    internal struct LineSegment: Hashable {
        /// The starting point of the line segment.
        internal var start: Point
        /// The endpoint of the line segment.
        internal var end: Point
        
        /// Whether the line segment is horizontal, sloped, or vertical.
        private enum LineType {
            /// The line segment is horizontal.
            case horizontal
            /// The line segment is neither horizontal nor vertical.
            case sloped
            /// The line segment is vertical.
            case vertical
        }
        
        /// Indicates whether the line is horizontal, vertical, or neither.
        private var type: LineType {
            if yMax == yMin {
                return .horizontal
            } else {
                if xMax == xMin {
                    return .vertical
                } else {
                    return .sloped
                }
            }
        }
        
        /// The minimum x-value in the line segment.
        private var xMin: Double {
            if start.x < end.x {
                return start.x
            } else {
                return end.x
            }
        }
        
        /// The maximum x-value in the line segment.
        private var xMax: Double {
            if start.x > end.x {
                return start.x
            } else {
                return end.x
            }
        }
        
        /// The minimum y-value in the line segment.
        private var yMin: Double {
            if start.y < end.y {
                return start.y
            } else {
                return end.y
            }
        }
        
        /// The maximum y-value in the line segment.
        private var yMax: Double {
            if start.y > end.y {
                return start.y
            } else {
                return end.y
            }
        }
        
        /// The slope of the line segment.
        private var slope: Double? {
            switch type {
            case .horizontal:
                return 0
            case .sloped:
                // A sloped line has slope defined as m = (rise) / (run).
                let rise = end.y - start.y
                let run = end.x - start.x
                return rise / run
            case .vertical:
                // A vertical line has slope m = ∞. Return nil.
                return nil
            }
        }
        
        /// The y-value along the line containing the line segment associated with x = 0.
        private var yAxisIntercept: Double? {
            if let slope = slope {
                return start.y - slope * start.x
            } else {
                return nil
            }
        }
        
        /// Determines the x-value at which a horizontal line through a given point would intercept the line segment.
        private func horizontalIntercept(for point: Point) -> Double? {
            if let slope = slope, let yAxisIntercept = yAxisIntercept, slope != 0 {
                return (point.y - yAxisIntercept) / slope
            } else {
                return nil
            }
        }
        
        /// The bounding box containing the line segment.
        private var bounds: BoundingBox {
            return BoundingBox(xMin: xMin, xMax: xMax, yMin: yMin, yMax: yMax)
        }
        
        /// Indicates whether a ray extending rightward from the given point will intersect the line segment.
        /// - parameter point: The point from which a ray will extend rightward.
        /// - returns: If there is an intersection, the function will return the coordinates of the intersection. If not, returns nil.
        internal func rightwardRayWillIntersect(from point: Point) -> Intersection? {
            guard point.y >= yMin, point.y <= yMax else {
                // The point is outside the vertical extent of the line segment so there will never be an intersection.
                return nil
            }
            
            switch type {
            case .horizontal:
                return nil
            case .vertical:
                if point.x < xMax {
                    return Intersection(x: xMax, y: point.y)
                } else {
                    return nil
                }
            case .sloped:
                // Determine whether the intercept of a line extending horizontally from the point happens to the left or right of the point.
                if let intercept = horizontalIntercept(for: point) {
                    if intercept < point.x {
                        // If the
                        return nil
                    } else {
                        return Intersection(x: intercept, y: point.y)
                    }
                } else {
                    return nil
                }
            }
        }
    }
    
    internal typealias Intersection = Point
    
    /// The line segments that make up the polygon.
    private var segments: [LineSegment] {
        var array: [LineSegment] = []
        for point in points {
            if let index = points.firstIndex(of: point) {
                let startPoint = points[index]
                if index.advanced(by: 1) == points.count {
                    if let first = points.first {
                        let endPoint = first
                        let line = LineSegment(start: startPoint, end: endPoint)
                        array.append(line)
                    }
                } else {
                    let endPoint = points[index.advanced(by: 1)]
                    let line = LineSegment(start: startPoint, end: endPoint)
                    array.append(line)
                }
            }
        }
        return array
    }
    
    /// The minimum x-value for the polygon.
    private var xMin: Double? {
        /// The point containing the minimum x-value for the polygon.
        let point = self.points.min { lhs, rhs in
            lhs.x < rhs.x
        }
        return point?.x
    }
    
    /// The maximum x-value for the polygon.
    private var xMax: Double? {
        /// The point containing the maximum x-value for the polygon.
        let point = self.points.max { lhs, rhs in
            lhs.x < rhs.x
        }
        return point?.x
    }
    
    /// The minimum y-value for the polygon.
    private var yMin: Double? {
        /// The point containing the minimum y-value for the polygon.
        let point = self.points.min { lhs, rhs in
            lhs.y < rhs.y
        }
        return point?.y
    }
    
    /// The maximum y-value for the polygon.
    private var yMax: Double? {
        /// The point containing the maximum y-value for the polygon.
        let point = self.points.max { lhs, rhs in
            lhs.y < rhs.y
        }
        return point?.y
    }
    
    /// The bounding box containing the polygon.
    private var bounds: BoundingBox? {
        if let xMin = xMin, let xMax = xMax, let yMin = yMin, let yMax = yMax {
            return BoundingBox(xMin: xMin, xMax: xMax, yMin: yMin, yMax: yMax)
        } else {
            return nil
        }
    }
    
    /// Determines whether the polygon contains a given point using the ray casting method.
    /// - warning: This does not work correctly if the polygon crosses itself.
    /// - parameter point: The point of interest.
    /// - returns: A boolean indicating whether or not the requested point is inside the polygon.
    public func contains(point: Point) -> Bool {
        guard self.points.unique.count >= 3 else {
            // With fewer than 3 unique points, we do not have an evaluable polygon.
            return false
        }
        
        if let bounds = bounds {
            guard bounds.contains(point) else {
                // The point is outside the bounding box containing the polygon, so it is definitely outside the polygon.
                return false
            }
            
            // Now we have a point inside the bounding box containing the polygon. Let's move on to the ray casting method.
            var intersections: [Intersection] = []
            for segment in segments {
                if let intersection = segment.rightwardRayWillIntersect(from: point) {
                    intersections.append(intersection)
                }
            }
            
            if intersections.unique.count % 2 == 0 {
                // If the number of intersections is even, the point is outside the polygon.
                return false
            } else {
                // If the number of intersections is odd, the point is inside the polygon.
                return true
            }
        } else {
            // A bounding box was unable to be generated, which implies that no points were supplied. Treat the point as outside.
            return false
        }
    }
}
