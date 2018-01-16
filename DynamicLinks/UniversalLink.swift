//
//  UniversalLink.swift
//  ChassApp
//
//  Created by Aratech iOS on 4/10/17.
//  Copyright © 2017 ChassApp. All rights reserved.
//

import Foundation

// MARK:- Universal Links

public struct UniversalLink: CustomStringConvertible {
    
    private var path: String
    private var link: URLComponents
    
    public var url: URL {
        return link.url!
    }
	
	public struct Configuration {
		/// Esquema de la url: developer.apple.com
		static var urlScheme: String = "" //brain.aratech.org"
		/// URL base del dominio, sin '/' al final: https://developer.apple.com
		static var baseURL: String = ""  //https://brain.aratech.org/"
		static var backURLAndroid = ""    //https://play.google.com/store/apps/details?id=com.comuto&hl=es"
		static var backURLiOS = ""        //https://itunes.apple.com/es/app/blablacar-compartir-coche/id341329033?mt=8"
	}
	
//    init?(_ link: URLComponents) {
//
//        self.link = link
//
//        let linkComponents = link.path.components(separatedBy: "/")
//
//        // TODO: Separar baseURL para obtener path del enalce
//    }
	
    public init(path: String) {
        self.path = path
		if !path.hasPrefix("/") { self.path.append("/") }
		
		var urlComponents = URLComponents()
		urlComponents.host = type(of: self).Configuration.baseURL
		urlComponents.path = self.path
		
		self.link = urlComponents
    }
    
    // MARK: CustomStringConvertible
    
	public var description: String {
		return "Universal Link with host: \(self.link.host ?? "error") and path: \(self.link.path)"
    }
}

    

