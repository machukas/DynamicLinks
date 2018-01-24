//
//  UniversalLink.swift
//  ChassApp
//
//  Created by Nicolas Landa on 4/10/17.
//  Copyright © 2017 Nicolas Landa. All rights reserved.
//

import Foundation

public struct UniversalLink: CustomStringConvertible {
	
	public static var configuration: Configuration = Configuration()

	public typealias LinkID = String
	
	public struct LinkType: RawRepresentable {
		public init?(rawValue: String) {
			self.rawValue = rawValue
		}
		
		public init(key: String) {
			self.init(rawValue: key)!
		}
		
		public var rawValue: String
		
		public typealias RawValue = String
	}
	
	private var type: LinkType
	private var id: LinkID
	
    private var link: URLComponents
    
    public var url: URL {
        return link.url!
    }
	
	public struct Configuration: Codable {
		/// URL base del dominio, sin '/' al final: https://developer.apple.com
		public var baseURL: String = ""
		/// URL de la aplicación en la PlayStore
		public var backURLAndroid: String = ""
		/// URL de la aplicación en la AppStore
		public var backURLiOS: String = ""
	}
	
	public init(type: LinkType, id: LinkID) {
		self.type = type
		self.id = id
		
		var urlComponents = URLComponents(string: UniversalLink.configuration.baseURL)!
		urlComponents.path = "/"+type.rawValue+"/"+id
		
		self.link = urlComponents
	}
    
    // MARK: CustomStringConvertible
    
	public var description: String {
		return "Universal Link with host: \(self.link.host ?? "error") type: \(self.link.path)"
    }
}
