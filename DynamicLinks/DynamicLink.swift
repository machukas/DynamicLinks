//
//  DynamicLink.swift
//  DynamicLinks
//
//  Created by Nicolas Landa on 23/10/17.
//  Copyright © 2017 Nicolas Landa. All rights reserved.
//

/**

Permite generar DynamicLinks,
ver parametros disponibles en
[Documentación de Firebase](https://firebase.google.com/docs/dynamic-links/create-manually?hl=es-419)

Se debe inicializar primero la configuración global de los enlaces en la app,
estructura `Configuration` estática de la clase.

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
	public struct Configuration: Codable {
		
		/// Clave para la API web de Firebase, necesaría para crear el enlace corto
		public var apiKey = ""
		
		/// Código de la app (panel de control Firebase)
		public var appCode = ""
		/// .app.goo.gl
		private (set) var appCodeHost = ".app.goo.gl"
		
		/// Nombre del paquete iOS
		public var bundleiOS = ""
		
		/// Nombre del paquete Android
		public var packageNameAndroid = ""
		
		public var minimumiOSVersion = "-1" // 9
		
		/// Enlace a la Google Play Store por si no se tiene la aplicación instalada
		public var backURLAndroid = ""
		
		/// Enlace a la AppStore por si no se tiene la aplicación instalada
		public var backURLiOS = ""
		
		/// Flag para que en lugar de cargar el DynamicLink, se genere un gráfico de flujo para depurar el comportamiento
		private var debug = "false"
		
		/// Si los datos obligatorios están asignados.
		static func checkMandatoryData() throws {
			if DynamicLink.configuration.appCode == "" {
				throw DynamicLinkError.missingConfigurationParameter("appCode") }
			if DynamicLink.configuration.bundleiOS == "" {
				throw DynamicLinkError.missingConfigurationParameter("bundleiOS") }
			if DynamicLink.configuration.packageNameAndroid == "" {
				throw DynamicLinkError.missingConfigurationParameter("packageNameAndroid") }
			if DynamicLink.configuration.minimumiOSVersion == "-1" {
				throw DynamicLinkError.missingConfigurationParameter("minimumiOSVersion") }
		}
	}
	
	public static var configuration: Configuration = Configuration()
	
	public var configuration: DynamicLink.Configuration {
		return type(of: self).configuration
	}
	
	public struct MetaInformation {
		let title: String
		let description: String?
		let imageURL: URL?
		
		public init(title: String, description: String? = nil, imageURL: String? = nil) {
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
		
		guard let baseURL = URL(string: "https://"+DynamicLink.configuration.appCode+DynamicLink.configuration.appCodeHost)
			else { throw DynamicLinkError.baseURLNotValid }
		self.urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
		
	}
	
	// MARK: - Link Params
	
	/// Enlace destino del DynamicLink
	private var link: URLQueryItem {
		let link = URLQueryItem(name: "link",
								value: self.universalLink.absoluteString)
		return link
	}
	
	private var androidBackURL: URLQueryItem? {
		guard self.configuration.backURLAndroid != "" else { return nil }
		
		let afl = URLQueryItem(name: "afl",
							   value: self.configuration.backURLAndroid)
		return afl
	}
	
	private var iOSBackURL: URLQueryItem? {
		guard self.configuration.backURLiOS != "" else { return nil }
		
		let ifl = URLQueryItem(name: "ifl",
							   value: self.configuration.backURLiOS)
		return ifl
	}
	
	private var androidPackageName: URLQueryItem {
		let apn = URLQueryItem(name: "apn",
							   value: self.configuration.packageNameAndroid)
		return apn
	}
	
	private var iosPackageName: URLQueryItem {
		let ibi = URLQueryItem(name: "ibi",
							   value: self.configuration.bundleiOS)
		return ibi
	}
	
	private var minimumiOSVersion: URLQueryItem {
		let imv = URLQueryItem(name: "imv", value: "\(self.configuration.minimumiOSVersion)")
		return imv
	}
	
	private var previewImage: URLQueryItem? {
		guard let imageURL = self.metaInformation.imageURL else { return nil }
		
		let si = URLQueryItem(name: "si",
							  value: imageURL.absoluteString)
		return si
	}
	
	private var previewDescription: URLQueryItem? {
		guard let description = self.metaInformation.description else { return nil }
		
		let sd = URLQueryItem(name: "sd",
							  value: description)
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
	
	// MARK: - API
	
	public func generateLink() -> URL? {
		var linkComponents = self.urlComponents
		linkComponents.queryItems = [link,
									 androidBackURL,
									 iOSBackURL,
									 androidPackageName,
									 iosPackageName,
									 previewImage,
									 previewDescription,
									 previewTitle,
									 minimumiOSVersion].flatMap({ $0 })
		
		return linkComponents.url
	}
	
	public typealias GenerateShorLinkType = (url: URL?, error: DynamicLinkError?)
	/// Síncrono
	///
	/// - Returns: GenerateShorLinkType
	/// - Throws: DynamicLinkError
	public func generateShortLink() throws -> GenerateShorLinkType {
		guard self.configuration.apiKey != "" else { throw DynamicLinkError.missingConfigurationParameter("apiKey") }
		
		let semaphore = DispatchSemaphore(value: 0)
		var response: GenerateShorLinkType = (nil, nil)
		
		let session = URLSession.shared
		let dataTask = session.dataTask(with: self.shortLinkRequest(), completionHandler: { (data, _, error) -> Void in
			if let error = error as NSError? {
				response.error = DynamicLinkError.firebaseRequestError(error)
			} else if let data = data {
				if let responseJson = try? JSONSerialization.jsonObject(with: data,
																		options: JSONSerialization.ReadingOptions.allowFragments) as? [String: Any],
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
	
	public typealias GenerateShorLinkBlock = (URL?, DynamicLinkError?) -> Void
	public func generateShortLink(completion: @escaping GenerateShorLinkBlock) throws {
		
		guard self.configuration.apiKey != "" else { throw DynamicLinkError.missingConfigurationParameter("apiKey") }
		
		let session = URLSession.shared
		let dataTask = session.dataTask(with: self.shortLinkRequest(), completionHandler: { (data, _, error) -> Void in
			if let error = error as NSError? {
				completion(nil, DynamicLinkError.firebaseRequestError(error))
			} else if let data = data {
				if let responseJson = try? JSONSerialization.jsonObject(with: data,
																		options: JSONSerialization.ReadingOptions.allowFragments) as? [String: Any],
					let shortLink = responseJson?["shortLink"] as? String {
					
					completion(URL(string: shortLink), nil)
				}
			}
		})
		
		dataTask.resume()
	}
	
	// MARK: - ShortLink Request
	
	private let shortLinkApiURL = "https://firebasedynamiclinks.googleapis.com/v1/shortLinks"
	
	private func shortLinkRequest() -> URLRequest {
		
		let headers = [
			"content-type": "application/json",
			"cache-control": "no-cache"]
		
		let parameters = [
			"longDynamicLink": self.generateLink()?.absoluteString ?? "",
			"suffix": ["option": "SHORT"]
			] as [String: Any]
		
		//swiftlint:disable:next force_try
		let postData = try! JSONSerialization.data(withJSONObject: parameters, options: [])
		
		var request = URLRequest(url: URL(string: "\(shortLinkApiURL)?key=\(self.configuration.apiKey)")!,
								 cachePolicy: .useProtocolCachePolicy,
								 timeoutInterval: 10.0)
		request.httpMethod = "POST"
		request.allHTTPHeaderFields = headers
		request.httpBody = postData as Data
		
		return request
	}
}
