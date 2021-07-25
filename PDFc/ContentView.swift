//
//  ContentView.swift
//  PDFc
//
//  Created by Sam Ryan on 2021-07-22.
//

import SwiftUI
import PDFKit
import Quartz

extension NSOpenPanel {
    
    static func openImage(completion: @escaping (_ result: Result<URL, Error>) -> ()) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedFileTypes = ["pdf"]
        panel.canChooseFiles = true
        panel.begin { (result) in
            if result == .OK,
               let url = panel.urls.first {
                print(type(of: url))
                completion(.success(url))
            } else {
                completion(.failure(
                    NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get file location"])
                ))
            }
        }
    }
    
    static func openSave(filename: String, completion: @escaping (_ result: Result<URL, Error>) -> ()) {
        let panel = NSSavePanel()
        panel.title = "Save Compressed PDF"
        panel.prompt = "Save"
        panel.nameFieldStringValue = filename
        panel.canCreateDirectories = true
        panel.begin { (result) in
            if result == .OK,
               let url = panel.url {
                print(type(of: url))
                completion(.success(url))
            } else {
                completion(.failure(
                    NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get file location"])
                ))
            }
        }
    }
    
}


struct ProgressIndicator: NSViewRepresentable {
    
    typealias TheNSView = NSProgressIndicator
    var configuration = { (view: TheNSView) in }
    
    func makeNSView(context: NSViewRepresentableContext<ProgressIndicator>) -> NSProgressIndicator {
        TheNSView()
    }
    
    func updateNSView(_ nsView: NSProgressIndicator, context: NSViewRepresentableContext<ProgressIndicator>) {
        configuration(nsView)
    }
}

struct InputImageView: View {
    
    @Binding var image: Image
    @State var urllPDF: URL?
    @State var newPDFLocation: URL?
    @State var newSize: String = ""
    @State var savedSize: String = ""
    @State var processing: Bool = false
    @State var selectedStrength = "150 DPI Average Quality"
    let strengths = ["75 DPI Low Quality",
                     "75 DPI Average Quality",
                     "110 DPI Average Quality",
                     "150 DPI Low Quality",
                     "150 DPI Average Quality",
                     "300 DPI Low Quality",
                     "300 DPI Average Quality",
                     "600 DPI Low Quality",
                     "600 DPI Average Quality"
                    ]
    
    var body: some View {
        VStack {
            ZStack {
                if self.image != Image("") {
                    VStack {
                        self.image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(8)
                        HStack {
                            if processing {
                                ProgressIndicator {
                                    $0.controlTint = .blueControlTint
                                    $0.style = .spinning
                                    $0.startAnimation(self)
                                }
//                                ProgressView()
                            } else {
//                              Text("2.2MB")
                                Text(newSize)
                                    .font(.headline)
                                    .foregroundColor(.black)
//                              Text("Saved 36% (0.79MB)")
                                Text(savedSize)
                                    .font(.headline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .frame(width: 320)
                } else {
                    HStack {
                        Text("Drop your PDF here...")

                        Button(action: selectFile) {
                            Text("Open")
                        }
                    }
                    .frame(width: 320)
                }
            }
            .frame(height: 320)
            .cornerRadius(8)
            .padding(15)
            
            HStack(alignment: .center) {
                
                Picker("", selection: $selectedStrength) {
                    ForEach(strengths, id: \.self) {
                        Text($0)
                    }
                }
                .frame(width: 190)
                
                Button(action: {
                    if urllPDF != nil {
                        runCompress(url: urllPDF!)
                    }
                }) {
                    Text("Compress")
                }
                
                Button(action: {
                    if newPDFLocation != nil {
                        let fileManager = FileManager.default
                        if fileManager.fileExists(atPath: newPDFLocation!.path) {
                            NSOpenPanel.openSave(filename: newPDFLocation!.lastPathComponent, completion: { (result) in
                                if case let .success(saveToPdf) = result {
                                    if fileManager.fileExists(atPath: saveToPdf.path) {
                                        do {
                                            try fileManager.removeItem(at: saveToPdf)
                                        } catch {
                                            print("Error Removing Item At \(saveToPdf.path)")
                                            print(error)
                                        }
                                    }
                                    do {
                                        try fileManager.moveItem(at: newPDFLocation!, to: saveToPdf)
                                    } catch {
                                        print("Error Copying Item from \(newPDFLocation!.path) to \(saveToPdf.path)")
                                        print(error)
                                    }
    
                                    self.image = Image("")
                                    
                                }
                            })
                        } else {
                            newPDFLocation = nil
                        }
                    }

                }) {
                    Text("Save")
                }
            }
            .padding(.trailing, 6)
        }
            
        .onDrop(of: ["public.url","public.file-url"], isTargeted: nil) { (items) -> Bool in
            processing = true
            if let item = items.first {
                if let identifier = item.registeredTypeIdentifiers.first {
                    print("onDrop with identifier = \(identifier)")
                    if identifier == "public.url" || identifier == "public.file-url" {
                        item.loadItem(forTypeIdentifier: identifier, options: nil) { (urlData, error) in
                            DispatchQueue.main.sync {
                                if let urlData = urlData as? Data {
                                    let urll = NSURL(absoluteURLWithDataRepresentation: urlData, relativeTo: nil) as URL
                                    if let img = NSImage(contentsOf: urll) {
                                        self.image = Image(nsImage: img)
                                        print("got it")
                                        urllPDF = urll
                                        print(type(of: urlData))
                                    }
                                }
                            }
                            runCompress(url: urllPDF!)
                        }
                    }
                }
                return true
            } else { print("item not here"); return false }
        }
    }
    
    private func runCompress(url: URL) {
        processing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            do {
                let convertedFilePath = self.compressPDF(pdfFile: url) as URL
                let attrNew = try FileManager.default.attributesOfItem(atPath: convertedFilePath.path)
                let attrOld = try FileManager.default.attributesOfItem(atPath: url.path)
                
                newPDFLocation = convertedFilePath
                newSize = Units(bytes: Int64(attrNew[FileAttributeKey.size] as! UInt64)).getReadableUnit()
                savedSize = "Saved \(String(format: "%.2f", 100-(Double(attrNew[FileAttributeKey.size] as! UInt64)/Double(attrOld[FileAttributeKey.size] as! UInt64))*100))% (\(Units(bytes: (Int64(attrOld[FileAttributeKey.size] as! UInt64)-Int64(attrNew[FileAttributeKey.size] as! UInt64))).getReadableUnit())) "
            } catch {
                print("Error: \(error)")
            }
            processing = false
        }
    }
    
    private func selectFile() {
        NSOpenPanel.openImage { (result) in
            if case let .success(image) = result {
                self.image = Image(nsImage: NSImage(contentsOf: image)!)
                
                DispatchQueue.main.async {
                    urllPDF = image
                    runCompress(url: image)
                }
            }
        }
    }
    
    public func compressPDF(pdfFile: URL) -> CFURL {
        var tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
        tempURL.appendPathComponent(pdfFile.lastPathComponent)
        
        let pdfContents: CGPDFDocument = PDFDocument(url: pdfFile)!.documentRef!
        let compressedPDF: CGContext = CGContext(tempURL as CFURL, mediaBox: nil, nil)!
        let filterURL = Bundle.main.url(forResource: selectedStrength, withExtension: "qfilter")
        let quartzFilter = QuartzFilter(url: filterURL)

        quartzFilter?.apply(to: compressedPDF)

        for index in 1...pdfContents.numberOfPages {
            // Get current page and its size (bounds) from input document
            let page: CGPDFPage = pdfContents.page(at: index)!
            var pageMediaBox: CGRect = page.getBoxRect(.mediaBox)

            // Redraw current page in output document
            compressedPDF.beginPage(mediaBox: &pageMediaBox)
            compressedPDF.drawPDFPage(page)
            compressedPDF.endPage()
        }
        // Close output document and return its location
        compressedPDF.closePDF()
        return (tempURL as CFURL)
    }
}


struct ContentView: View {
    @State var image = Image("")
    
    var body: some View {
        VStack {
            InputImageView(image: $image)
        }
        .frame(width: 340, height: 400, alignment: .top)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
