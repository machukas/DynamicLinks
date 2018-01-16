//
//  DynamicLink.swift
//  DynamicLinks
//
//  Created by Nicolas Landa on 23/10/17.
//  Copyright © 2017 Nicolas Landa. All rights reserved.
//

/**

	Permite generar DynamicLinks, ver parametros disponibles en [Documentación de Firebase](https://firebase.google.com/docs/dynamic-links/create-manually?hl=es-419)

	Se debe inicializar primero la configuración global de los enlaces en la app, estructura `Configuration` estática de la clase.

*/
public struct DynamicLink {
	
	public enum DynamicLinkError: Error {
		case notConfigured
		case baseURLNotValid
		case missingConfigurationParameter(String)
		case firebaseRequestError(NSError)
		
		var localizedDescription: String {
			switch self {
			case .notConfigured:
				return "Configuration missing"
			case .baseURLNotValid:
				return "The base URL for the link is not valid"
			case .missingConfigurationParameter(let parameterName):
				return "The configuration parameter \(parameterName) is missing"
			case .firebaseRequestError(let error):
				return "There was some error with the Firebase API: \(error.localizedDescription)"
			}
		}
	}
	
	/// Configuración global de todos los `DynamicLink`
	public struct Configuration {
		
		/// Clave para la API web de Firebase, necesaría para crear el enlace corto
		public static var apiKey = ""
		
		/// Código de la app (panel de control Firebase)
		public static var appCode = ""
		/// .app.goo.gl
		private (set) static var appCodeHost = ".app.goo.gl"
		
		/// Nombre del paquete iOS
		public static var bundleiOS = ""
		
		/// Nombre del paquete Android
		public static var packageNameAndroid = ""
		
		public static var minimumiOSVersion = -1 // 9
		
		/// Enlace a la Google Play Store por si no se tiene la aplicación instalada
		public static var backURLAndroid = ""
		
		/// Enlace a la AppStore por si no se tiene la aplicación instalada
		public static var backURLiOS = ""
		
		/// Flag para que en lugar de cargar el DynamicLink, se genere un gráfico de flujo para depurar el comportamiento
		public static var debug = false
		
		/// Si los datos obligatorios están asignados.
		static func checkMandatoryData() throws {
			if Configuration.appCode == "" { throw DynamicLinkError.missingConfigurationParameter("appCode") }
			if Configuration.bundleiOS == "" { throw DynamicLinkError.missingConfigurationParameter("bundleiOS") }
			if Configuration.packageNameAndroid == "" { throw DynamicLinkError.missingConfigurationParameter("packageNameAndroid") }
			if Configuration.minimumiOSVersion == -1 { throw DynamicLinkError.missingConfigurationParameter("minimumiOSVersion") }
		}
	}
	
	public struct MetaInformation {
		let title: String
		let description: String?
		let imageURL: URL?
		
		init(title: String, description: String? = nil, imageURL: String? = nil) {
			self.title = title
			self.description = description
			
			if let url = imageURL {
				self.imageURL = URL(string: url)
			} else {
				self.imageURL = nil
			}
		}
	}
	
	private var urlComponents: URLComponents
	
	private let metaInformation: MetaInformation
	private let universalLink: URL
	
	public init(link: URL, info: MetaInformation) throws {
		self.universalLink = link
		self.metaInformation = info
		
		try Configuration.checkMandatoryData()
		
		guard let baseURL = URL(string: "https://"+Configuration.appCode+Configuration.appCodeHost) else { throw DynamicLinkError.baseURLNotValid }
		self.urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
		
	}
	
	// MARK:- Link Params
	
	/// Enlace destino del DynamicLink
	private var link: URLQueryItem {
		let link = URLQueryItem(name: "link",
		                        value: self.universalLink.absoluteString)
		return link
	}
	
	private var androidBackURL: URLQueryItem? {
		let afl = URLQueryItem(name: "afl",
		                       value: Configuration.backURLAndroid)
		return afl
	}
	
	private var iOSBackURL: URLQueryItem? {
		let ifl = URLQueryItem(name: "ifl",
		                       value: Configuration.backURLiOS)
		return ifl
	}
	
	private var androidPackageName: URLQueryItem {
		let apn = URLQueryItem(name: "apn",
		                       value: Configuration.packageNameAndroid)
		return apn
	}
	
	private var iosPackageName: URLQueryItem {
		let ibi = URLQueryItem(name: "ibi",
		                       value: Configuration.bundleiOS)
		return ibi
	}
	
	private var minimumiOSVersion: URLQueryItem {
		let imv = URLQueryItem(name: "imv", value: "\(Configuration.minimumiOSVersion)")
		return imv
	}
	
	private var previewImage: URLQueryItem {
		let si = URLQueryItem(name: "si",
		                      value: self.metaInformation.imageURL?.absoluteString)
		return si
	}
	
	private var previewDescription: URLQueryItem {
		let sd = URLQueryItem(name: "sd",
		                      value: self.metaInformation.description)
		return sd
	}
	
	private var previewTitle: URLQueryItem {
		let st = URLQueryItem(name: "st", value: self.metaInformation.title)
		return st
	}
	
	private var debug: URLQueryItem {
		let d = URLQueryItem(name: "d", value: "1")
		return d
	}
	
	// MARK:- API
	
	public func generateLink() -> URL? {
		var linkComponents = self.urlComponents
		linkComponents.queryItems = [link, androidBackURL, iOSBackURL, androidPackageName, iosPackageName, previewImage, previewDescription, previewTitle, minimumiOSVersion].flatMap({ $0 })
		
		return linkComponents.url
	}
	
	public typealias GenerateShorLinkType = (url: URL?, error: DynamicLinkError?)
	/// Síncrono
	///
	/// - Returns: GenerateShorLinkType
	/// - Throws: DynamicLinkError
	public func generateShortLink() throws -> GenerateShorLinkType {
		guard Configuration.apiKey != "" else { throw DynamicLinkError.missingConfigurationParameter("apiKey") }
		
		let semaphore = DispatchSemaphore(value: 0)
		var response: GenerateShorLinkType = (nil,nil)
		
		let session = URLSession.shared
		let dataTask = session.dataTask(with: self.shortLinkRequest(), completionHandler: { (data, _, error) -> Void in
			if let error = error as NSError? {
				response.error = DynamicLinkError.firebaseRequestError(error)
			} else if let data = data {
				if let responseJson = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? [String:Any],
					let shortLink = responseJson?["shortLink"] as? String {
					
					response.url = URL(string: shortLink)
				}
			}
			semaphore.signal()
		})
		
		dataTask.resume()
		semaphore.wait()
		
		return response
	}
	
	public typealias GenerateShorLinkBlock = (URL?, DynamicLinkError?)->Void
	public func generateShortLink(completion: @escaping GenerateShorLinkBlock) throws {
		
		guard Configuration.apiKey != "" else { throw DynamicLinkError.missingConfigurationParameter("apiKey") }
		
		let session = URLSession.shared
		let dataTask = session.dataTask(with: self.shortLinkRequest(), completionHandler: { (data, response, error) -> Void in
			if let error = error as NSError? {
				completion(nil, DynamicLinkError.firebaseRequestError(error))
			} else if let data = data {
				if let responseJson = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? [String:Any],
					let shortLink = responseJson?["shortLink"] as? String {
					
					completion(URL(string: shortLink), nil)
				}
			}
		})
		
		dataTask.resume()
	}
	
	// MARK:- ShortLink Request
	
	private let shortLinkApiURL = "https://firebasedynamiclinks.googleapis.com/v1/shortLinks"
	
	private func shortLinkRequest() -> URLRequest {
		
		let headers = [
			"content-type": "application/json",
			"cache-control": "no-cache",
		]
		
		let parameters = [
			"longDynamicLink": self.generateLink()?.absoluteString ?? "",
			"suffix": ["option": "SHORT"]
			] as [String : Any]
		
		let postData = try! JSONSerialization.data(withJSONObject: parameters, options: [])
		
		var request = URLRequest(url: URL(string: "\(shortLinkApiURL)?key=\(Configuration.apiKey)")!,
		                                  cachePolicy: .useProtocolCachePolicy,
		                                  timeoutInterval: 10.0)
		request.httpMethod = "POST"
		request.allHTTPHeaderFields = headers
		request.httpBody = postData as Data
		
		return request
	}
}
