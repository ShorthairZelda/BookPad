import AppKit
import ImageIO
import UniformTypeIdentifiers

// Code-drawn vector artwork: DualShock-style controller + an open book.
// Run from the repository root: xcrun swift Assets/GenerateIcon.swift
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let assets = root.appendingPathComponent("Assets")
func color(_ hex: UInt32) -> CGColor {
    CGColor(red: CGFloat((hex >> 16) & 255)/255, green: CGFloat((hex >> 8) & 255)/255, blue: CGFloat(hex & 255)/255, alpha: 1)
}
func path(_ commands: [(String, [CGFloat])]) -> CGPath {
    let p = CGMutablePath()
    for (op, v) in commands {
        switch op {
        case "M": p.move(to: CGPoint(x: v[0], y: v[1]))
        case "L": p.addLine(to: CGPoint(x: v[0], y: v[1]))
        case "C": p.addCurve(to: CGPoint(x: v[4], y: v[5]), control1: CGPoint(x: v[0], y: v[1]), control2: CGPoint(x: v[2], y: v[3]))
        default: p.closeSubpath()
        }
    }
    return p
}
let controller = path([
    ("M", [330,286]), ("C", [277,279,245,311,224,367]),
    ("L", [180,513]), ("C", [161,577,215,618,260,580]),
    ("L", [326,521]), ("C", [375,499,415,498,454,511]),
    ("L", [570,511]), ("C", [609,498,649,499,698,521]),
    ("L", [764,580]), ("C", [809,618,863,577,844,513]),
    ("L", [800,367]), ("C", [779,311,747,279,694,286]),
    ("C", [577,307,447,307,330,286]), ("Z", [])
])
let leftPage = path([("M",[512,578]), ("C",[448,539,366,535,284,551]), ("L",[284,733]), ("C",[371,719,445,730,512,774]), ("Z",[])])
let rightPage = path([("M",[512,578]), ("C",[576,539,658,535,740,551]), ("L",[740,733]), ("C",[653,719,579,730,512,774]), ("Z",[])])
func draw(_ c: CGContext, template: Bool) {
    c.setLineJoin(.round); c.setLineCap(.round)
    if !template {
        let tile = CGPath(roundedRect: CGRect(x:72,y:72,width:880,height:880), cornerWidth:190, cornerHeight:190, transform:nil)
        c.saveGState(); c.addPath(tile); c.clip()
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [color(0x4544A9),color(0x171F4B)] as CFArray, locations:[0,1])!
        c.drawLinearGradient(gradient,start:CGPoint(x:180,y:80),end:CGPoint(x:820,y:960),options:[])
        c.restoreGState()
        c.setShadow(offset: CGSize(width:0,height:14), blur:30,color:CGColor(gray:0,alpha:0.22))
    }
    c.setFillColor(template ? CGColor(gray:0,alpha:1) : color(0xF0F0FF))
    c.addPath(controller); c.fillPath()
    c.setShadow(offset:.zero,blur:0,color:nil)
    let ink = template ? CGColor(gray:1,alpha:1) : color(0x36376F)
    if template { c.setBlendMode(.clear) }
    c.setFillColor(ink)
    c.fill(CGRect(x:296,y:352,width:28,height:100)); c.fill(CGRect(x:260,y:388,width:100,height:28))
    c.addPath(CGPath(roundedRect:CGRect(x:435,y:338,width:154,height:86),cornerWidth:18,cornerHeight:18,transform:nil)); c.fillPath()
    for x: CGFloat in [404,620] { c.fillEllipse(in:CGRect(x:x-29,y:451,width:58,height:58)) }
    c.setLineWidth(12)
    // The four familiar face-button positions remain legible at small sizes.
    c.setStrokeColor(template ? ink : color(0x62BAAC))
    c.move(to:CGPoint(x:714,y:347)); c.addLine(to:CGPoint(x:692,y:382)); c.addLine(to:CGPoint(x:736,y:382)); c.closePath(); c.strokePath()
    c.setStrokeColor(template ? ink : color(0xD9899B)); c.strokeEllipse(in:CGRect(x:744,y:391,width:40,height:40))
    c.setStrokeColor(template ? ink : color(0xA2A7EC))
    c.move(to:CGPoint(x:697,y:450)); c.addLine(to:CGPoint(x:727,y:480)); c.move(to:CGPoint(x:727,y:450)); c.addLine(to:CGPoint(x:697,y:480)); c.strokePath()
    c.setStrokeColor(template ? ink : color(0xB391CA)); c.stroke(CGRect(x:641,y:392,width:35,height:35))
    c.setBlendMode(.normal)
    if !template {
        // A dark outline separates the book from the controller behind it.
        c.setLineWidth(26); c.setStrokeColor(color(0x232957))
        for page in [leftPage,rightPage] { c.addPath(page); c.strokePath() }
    } else {
        c.setBlendMode(.clear); c.setLineWidth(32)
        for page in [leftPage,rightPage] { c.addPath(page); c.strokePath() }
        c.setBlendMode(.normal)
    }
    c.setFillColor(template ? CGColor(gray:0,alpha:1) : color(0xFFFFFF)); c.addPath(leftPage); c.fillPath()
    c.setFillColor(template ? CGColor(gray:0,alpha:1) : color(0xDBDFFF)); c.addPath(rightPage); c.fillPath()
    c.setStrokeColor(template ? CGColor(gray:1,alpha:1) : color(0x737CCA)); c.setLineWidth(9)
    if template { c.setBlendMode(.clear); c.setLineWidth(14) }
    for y: CGFloat in [601,641,681] {
        c.move(to:CGPoint(x:329,y:y)); c.addCurve(to:CGPoint(x:465,y:y+22),control1:CGPoint(x:375,y:y-1),control2:CGPoint(x:422,y:y+4)); c.strokePath()
        c.move(to:CGPoint(x:559,y:y+22)); c.addCurve(to:CGPoint(x:695,y:y),control1:CGPoint(x:602,y:y+4),control2:CGPoint(x:649,y:y-1)); c.strokePath()
    }
    c.move(to:CGPoint(x:512,y:584)); c.addLine(to:CGPoint(x:512,y:764)); c.strokePath()
    if !template {
        c.setFillColor(color(0xF1B968))
        c.move(to:CGPoint(x:651,y:546)); c.addLine(to:CGPoint(x:681,y:548)); c.addLine(to:CGPoint(x:681,y:622)); c.addLine(to:CGPoint(x:666,y:610)); c.addLine(to:CGPoint(x:651,y:618)); c.closePath(); c.fillPath()
    }
}
func png(size: Int, template: Bool, url: URL) {
    let c = CGContext(data:nil,width:size,height:size,bitsPerComponent:8,bytesPerRow:size*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
    c.translateBy(x:0,y:CGFloat(size)); c.scaleBy(x:CGFloat(size)/1024,y:-CGFloat(size)/1024)
    if template {
        // Crop the transparent mark to use the available menu bar space.
        c.translateBy(x:-205,y:-260); c.scaleBy(x:1.4,y:1.4)
    }
    draw(c,template:template)
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString,1,nil)!
    CGImageDestinationAddImage(dest,c.makeImage()!,nil)
    precondition(CGImageDestinationFinalize(dest))
}
try FileManager.default.createDirectory(at:assets.appendingPathComponent("AppIcon.iconset"),withIntermediateDirectories:true)
for base in [16,32,128,256,512] {
    for scale in [1,2] {
        let name = "icon_\(base)x\(base)\(scale == 2 ? "@2x" : "").png"
        png(size:base*scale,template:false,url:assets.appendingPathComponent("AppIcon.iconset/"+name))
    }
}
png(size:1024,template:false,url:assets.appendingPathComponent("BookPad.png"))
// AppKit will render the menu mark as a template for light and dark menu bars.
png(size:44,template:true,url:assets.appendingPathComponent("MenuBar@2x.png"))
png(size:22,template:true,url:assets.appendingPathComponent("MenuBar.png"))
// ICNS consists of a header and typed PNG representations. Keeping this here
// makes regeneration independent of iconutil's system image-service availability.
func bigEndian(_ value: Int) -> Data {
    var number = UInt32(value).bigEndian
    return withUnsafeBytes(of:&number) { Data($0) }
}
var entries = Data()
for (kind, file) in [("icp4","icon_16x16.png"), ("icp5","icon_32x32.png"),
                     ("icp6","icon_32x32@2x.png"), ("ic07","icon_128x128.png"),
                     ("ic08","icon_256x256.png"), ("ic09","icon_512x512.png"),
                     ("ic10","icon_512x512@2x.png"), ("ic11","icon_16x16@2x.png"),
                     ("ic12","icon_32x32@2x.png"), ("ic13","icon_128x128@2x.png"),
                     ("ic14","icon_256x256@2x.png")] {
    let bytes = try Data(contentsOf: assets.appendingPathComponent("AppIcon.iconset/" + file))
    entries.append(Data(kind.utf8)); entries.append(bigEndian(bytes.count + 8)); entries.append(bytes)
}
var icns = Data("icns".utf8)
icns.append(bigEndian(entries.count + 8)); icns.append(entries)
try icns.write(to:assets.appendingPathComponent("AppIcon.icns"))
print("Generated BookPad icon assets")
