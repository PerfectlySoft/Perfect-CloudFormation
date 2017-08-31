//
//  PerfectCloudFormation.swift
//  Perfect-CloudFormation
//
//	Copyright (C) 2017 PerfectlySoft, Inc.
//
//===----------------------------------------------------------------------===//
//
// This source file is part of the Perfect.org open source project
//
// Copyright (c) 2015 - 2017 PerfectlySoft Inc. and the Perfect project authors
// Licensed under Apache License v2.0
//
// See http://perfect.org/licensing.html for license information
//
//===----------------------------------------------------------------------===//
//

import Foundation
import PerfectCURL

private let paCloudFormationEnvPrefix = "PACF_"
private let paCloudFormationRDSPrefix = "RDS_"
private let paCloudFormationElastiCachePrefix = "ELASTICACHE_"
private let paCloudFormationAccessKeyId = "ACCESS_KEY_ID"
private let paCloudFormationSecretAccessKey = "SECRET_ACCESS_KEY"
private let paCloudFormationCertDomainPrefix = "CERT_DOMAIN_"
private let paCloudFormationCertArnPrefix = "CERT_ARN_"
private let paCloudFormationRegion = "REGION"

public enum CloudFormation {
	public struct Error: Swift.Error, CustomStringConvertible {
		public var description: String { return message }
		public let message: String
	}
	public struct RDSInstance {
		public enum DBType {
			case postgres, mysql
		}
		public let resourceType: DBType
		public let resourceId: String
		public let resourceName: String
		public let userName: String
		public let password: String
		public let hostName: String
		public let hostPort: Int
	}
	
	public struct ElastiCacheInstance {
		public enum ElastiCacheType {
			case redis
		}
		public let resourceType: ElastiCacheType
		public let resourceId: String
		public let resourceName: String
		public let hostName: String
		public let hostPort: Int
	}
	
	public struct ACMCertificate {
		public let domainName: String
		public let arn: String
		public let certificate: String
		public let certificateChain: String
	}
	
	static var env: [String:String] {
		let e = ProcessInfo.processInfo.environment
		var r: [String:String] = [:]
		e.filter { $0.0.hasPrefix(paCloudFormationEnvPrefix) }.forEach { r[$0.0] = $0.1 }
		return r
	}
	
	static func prefixedEnv(_ named: String) -> String? {
		return env["\(paCloudFormationEnvPrefix)\(named)"]
	}
}

public extension CloudFormation {
	static var region: String {
		return prefixedEnv(paCloudFormationRegion) ?? "us-east-1"
	}
}

public extension CloudFormation {
	static var accessKeyId: String? {
		return prefixedEnv(paCloudFormationAccessKeyId)
	}
	static var secretAccessKey: String? {
		return prefixedEnv(paCloudFormationSecretAccessKey)
	}
	static var accessKeyPair: (String, String)? {
		guard let i = accessKeyId, let k = secretAccessKey else {
			return nil
		}
		return (i, k)
	}
	
}

public extension CloudFormation {
	static func listRDSInstances() -> [RDSInstance] {
		return []
	}
	static func listRDSInstances(type: RDSInstance.DBType) -> [RDSInstance] {
		return listRDSInstances().filter { $0.resourceType == type }
	}
}

public extension CloudFormation {
	static func listElastiCacheInstances() -> [ElastiCacheInstance] {
		return []
	}
	static func listElastiCacheInstances(type: ElastiCacheInstance.ElastiCacheType) -> [ElastiCacheInstance] {
		return listElastiCacheInstances().filter { $0.resourceType == type }
	}
}

public extension CloudFormation.ACMCertificate {
	init?(domain: String) {
		for i in 0..<Int.max {
			guard let certDomain = CloudFormation.prefixedEnv("\(paCloudFormationCertDomainPrefix)\(i)"),
					let certArn = CloudFormation.prefixedEnv("\(paCloudFormationCertArnPrefix)\(i)")else {
				break
			}
			guard certDomain.lowercased() == domain.lowercased() else {
				continue
			}
			let request = CURLRequest(aws: AWSGetCertificate(arn: certArn))
			do {
				let json = try request.perform().bodyJSON
				guard let chain = json["CertificateChain"] as? String,
					let cert = json["Certificate"] as? String else {
						return nil
				}
				self.init(domainName: domain, arn: certArn, certificate: cert, certificateChain: chain)
				return
			} catch {
				break
			}
		}
		return nil
	}
}


