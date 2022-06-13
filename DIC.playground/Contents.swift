import Cocoa
import Surge
import Algorithms
import Accelerate
import PlaygroundSupport

var greeting = "Hello, playground"



let subsetSize = 41
/// X_REF & Y_REF
let x_ref = Matrix(rows: subsetSize, columns: subsetSize, grid: (-subsetSize/2 ... subsetSize/2).map {Float($0)}.cycled(times: subsetSize).compactMap{$0})

let y_ref = Matrix(rows: subsetSize, columns: subsetSize, grid: (-subsetSize/2 ... subsetSize/2).map {Array(repeating: Float($0), count: subsetSize)}.flatMap {$0})


let f_img = Matrix<Float>.random(rows: 41, columns: 41)
let g_img = Matrix<Float>.random(rows: 41, columns: 41)


let fSubMean: Matrix<Float> = f_img - mean(f_img)
let gSubMean = g_img - mean(g_img)
let up = (fSubMean) * (gSubMean)

let fSqrtPowSubMean = sqrtf(sum(pow(fSubMean, 2)))
let gSqrtPowSubMean = sqrtf(sum(pow(gSubMean, 2)))

let CLs: Float = sum(pow(fSubMean / fSqrtPowSubMean - gSubMean / gSqrtPowSubMean, 2))




