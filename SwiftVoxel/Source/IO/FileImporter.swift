
import UIKit

class FileImporter: NSObject {
    
    static func importFile(filename:String) -> Any? {
        let path = Bundle.main.url(forResource: filename, withExtension: "json")!
        
        do {
            let jsonFile = try! Data(contentsOf: path)
            let jsonResult = try! JSONSerialization.jsonObject(with: jsonFile, options: .mutableContainers) 
            return jsonResult
        }
    }
}
