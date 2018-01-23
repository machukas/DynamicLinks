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
		/// URL base del dominio, sin '/' al final: https://developer.apple.com
		public static var baseURL: String = ""  //https://brain.aratech.org/"
		public static var backURLAndroid = ""    //https://play.google.com/store/apps/details?id=com.comuto&hl=es"
		public static var backURLiOS = ""        //https://itunes.apple.com/es/app/blablacar-compartir-coche/id341329033?mt=8"
	}
	
    public init(path: String) {
        self.path = path
		if !path.hasPrefix("/") { self.path = "/"+self.path }
		
		var urlComponents = URLComponents(string: type(of: self).Configuration.baseURL)!
		urlComponents.path = self.path
		
		self.link = urlComponents
    }
    
    // MARK: CustomStringConvertible
    
	public var description: String {
		return "Universal Link with host: \(self.link.host ?? "error") and path: \(self.link.path)"
    }
}

    

