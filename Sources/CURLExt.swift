//
//  CURLExt.swift
//  PerfectCloudFormation
//
//  Created by Kyle Jessup on 2017-08-30.
//

import Foundation
import PerfectCURL
import PerfectCrypto
import PerfectHTTP
import PerfectLib

private let awsJSONContentType = "application/x-amz-json-1.1"
private let awsSignAlgo = "AWS4-HMAC-SHA256"

public protocol AWSCURLConfigurator {
	var method: HTTPMethod { get }
	var uri: String { get }
	var host: String { get }
	var target: String { get }
	var contentType: String { get }
	var service: String { get }
	var payload: [UInt8] { get }
	func configure(request: CURLRequest)
}

public extension AWSCURLConfigurator {
	var dateTime: (String, String) {
		let date = Date()
		let fmt = DateFormatter()
		fmt.timeZone = TimeZone(secondsFromGMT: 0)
		
		fmt.dateFormat = "YYYYMMdd"
		let d = fmt.string(from: date)
		
		fmt.dateFormat = "HHmmss"
		let t = fmt.string(from: date)
		return (d, t)
	}
	
	func configureAWS(request: CURLRequest) {
		guard let (id, key) = CloudFormation.accessKeyPair else {
			return
		}
		let region = CloudFormation.region
		let (date, time) = self.dateTime
		let fullDate = "\(date)T\(time)Z"
		let canonicalHeaders =
			"content-type:\(contentType)\n" +
			"host:\(host)\n" +
			"x-amz-date:\(fullDate)\n" +
			"x-amz-target:\(target)\n\n"
		let payload = self.payload
		guard let signedPayload = payload.digest(.sha256)?.encode(.hex),
				let payloadString = String(validatingUTF8: signedPayload) else {
			return
		}
		let headersList = "content-type;host;x-amz-date;x-amz-target"
		let canonicalRequest =
			"\(method.description)\n\(uri)\n\("")\n" +
			canonicalHeaders +
			headersList + "\n" +
			payloadString
		guard let hashedRequest = canonicalRequest.digest(.sha256)?.encode(.hex),
			let hashedRequestString = String(validatingUTF8: hashedRequest) else {
				return
		}
		let credentialScope = "\(date)/\(region)/\(service)/aws4_request"
		let stringToSign =
			"\(awsSignAlgo)\n\(fullDate)\n" +
			"\(credentialScope)\n" +
			hashedRequestString
		guard let dhash = Array(date.utf8).sign(.sha256, key: HMACKey(Array(("AWS4"+key).utf8))),
			let rhash = Array(region.utf8).sign(.sha256, key: HMACKey(dhash)),
			let shash = Array(service.utf8).sign(.sha256, key: HMACKey(rhash)),
			let signed = Array("aws4_request".utf8).sign(.sha256, key: HMACKey(shash)),
			let signature = Array(stringToSign.utf8).sign(.sha256, key: HMACKey(signed))?.encode(.hex),
			let signatureString = String(validatingUTF8: signature) else {
				return
		}
		let authorization =
			"\(awsSignAlgo) " +
			"Credential=\(id)/\(date)/\(region)/\(service)/aws4_request, " +
			"SignedHeaders=\(headersList), " +
			"Signature=\(signatureString)"
		
		request.options += [.httpMethod(method),
		                    .postData(payload),
		                    .addHeaders([(.contentType, contentType),
		                                 (.host, host),
		                                 (.custom(name: "x-amz-date"), fullDate),
		                                 (.custom(name: "x-amz-target"), target),
		                                 (.authorization, authorization)])] as [CURLRequest.Option]
	}
}

public extension CURLRequest {
	convenience init(aws: AWSCURLConfigurator) {
		self.init("https://\(aws.host)\(aws.uri)")
		aws.configureAWS(request: self)
		aws.configure(request: self)
	}
}

public struct AWSGetCertificate : AWSCURLConfigurator {
	public let method = HTTPMethod.post
	public let uri = "/"
	public var host: String { return "acm.\(CloudFormation.region).amazonaws.com" }
	public let target = "CertificateManager.GetCertificate"
	public let contentType = awsJSONContentType
	public let service = "acm"
	public var payload: [UInt8]
	
	public init(arn: String) {
		let bodyJSON = ["CertificateArn": arn] as [String:Any]
		do {
			payload = Array(try bodyJSON.jsonEncodedString().utf8)
		} catch {
			payload = Array("{}".utf8)
		}
	}
	
	public func configure(request: CURLRequest) {
		//...
	}
}





