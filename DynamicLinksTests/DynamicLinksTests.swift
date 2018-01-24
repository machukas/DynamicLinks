//
//  DynamicLinksTests.swift
//  DynamicLinksTests
//
//  Created by Nicolas Landa on 20/10/17.
//  Copyright © 2017 Nicolas Landa. All rights reserved.
//

import XCTest
@testable import DynamicLinks

extension UniversalLink.LinkType {
	static let testPurpose = UniversalLink.LinkType(key: "testingPurpose")
}

class DynamicLinksTests: XCTestCase {
	
	private func readUniversalLinkConfigurationFile() {
		
		let bundle: Bundle = Bundle(for: type(of: self))
		guard let filePath = bundle.path(forResource: "UniversalLinkConfiguration", ofType: "plist") else {
			fatalError("No configuration file found")
		}
		
		let fileURL = URL(fileURLWithPath: filePath)
		
		do {
			let data = try Data(contentsOf: fileURL)
			let decoder = PropertyListDecoder()
			let configuration = try decoder.decode(UniversalLink.Configuration.self, from: data)
			
			UniversalLink.configuration = configuration
			
		} catch let error{
			fatalError(error.localizedDescription)
		}
	}
	
	private func readDynamicLinkConfigurationFile() {
		
		let bundle: Bundle = Bundle(for: type(of: self))
		guard let filePath = bundle.path(forResource: "DynamicLinkConfiguration", ofType: "plist") else {
			fatalError("No configuration file found")
		}

		let fileURL = URL(fileURLWithPath: filePath)

		do {
			let data = try Data(contentsOf: fileURL)
			let decoder = PropertyListDecoder()
			let configuration = try decoder.decode(DynamicLink.Configuration.self, from: data)

			DynamicLink.configuration = configuration

		} catch let error{
			fatalError(error.localizedDescription)
		}
	}
	
	var universalLink: UniversalLink {
		return UniversalLink(type: .testPurpose, id: "id")
	}

	var metaInformation: DynamicLink.MetaInformation {
		return DynamicLink.MetaInformation(title: "Test Dynamic Link Title",
										   description: "Test Dynamic Link Description",
										   imageURL: "https://c24e867c169a525707e0-bfbd62e61283d807ee2359a795242ecb.ssl.cf3.rackcdn.com/imagenes/gato/etapas-clave-de-su-vida/gatitos/nuevo-gatito-en-casa/gatito-durmiendo-en-cama.jpg")
	}

	var dynamicLink: DynamicLink {
		return try! DynamicLink(link: self.universalLink.url, info: self.metaInformation)
	}
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
		
		readUniversalLinkConfigurationFile()
		readDynamicLinkConfigurationFile()
		
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func testUniversalLink() {
		let correctURL = URL(string: "\(UniversalLink.configuration.baseURL)/testingPurpose/id")!
		
		XCTAssert(self.universalLink.url == correctURL)
	}
	
	func testLongLink() {
		// This is an example of a functional test case.
		// Use XCTAssert and related functions to verify your tests produce the correct results.
		
		let longDynamicLink = self.dynamicLink.generateLink()

		XCTAssert(longDynamicLink != nil)
	}
	
	func testShortLink() {
		
		let shortLinkTestExpectation: XCTestExpectation = expectation(description: "shortLinkTest")

		try! self.dynamicLink.generateShortLink { (url, error) in
			XCTAssert(url != nil)
			shortLinkTestExpectation.fulfill()
		}

		waitForExpectations(timeout: 10, handler: nil)
	}
	
	func testNotConfigured() {
		
		DynamicLink.configuration.apiKey = ""

		do {
			try self.dynamicLink.generateShortLink { (url, error) in }
		} catch let error {
			if let dynamicError = error as? DynamicLink.DynamicLinkError,
				case .missingConfigurationParameter("apiKey") = dynamicError {
				XCTAssertTrue(true)
			}
		}
	}
	
	func testPerformanceExample() {
		// This is an example of a performance test case.
		self.measure {
			// Put the code you want to measure the time of here.
			_ = try? self.dynamicLink.generateShortLink()
		}
	}
	
}
