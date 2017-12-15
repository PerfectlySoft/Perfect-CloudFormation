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
//import PerfectCURL

private let paCloudFormationEnvPrefix = "PACF_"
private let paCloudFormationRDSPrefix = "RDS_"
private let paCloudFormationElastiCachePrefix = "ELASTICACHE_"
private let paCloudFormationSwiftletsPrefix = "SWIFTLETS"
private let paCloudFormationAccessKeyId = "ACCESS_KEY_ID"
private let paCloudFormationSecretAccessKey = "SECRET_ACCESS_KEY"
private let paCloudFormationCertDomainPrefix = "CERT_DOMAIN_"
private let paCloudFormationCertArnPrefix = "CERT_ARN_"
private let paCloudFormationRegion = "REGION"

private let paCloudFormationPostgres = "POSTGRES"
private let paCloudFormationMySQL = "MYSQL"
private let paCloudFormationRedis = "REDIS"

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
		
		public init(resourceType rt: DBType,
					resourceId ri: String,
					resourceName rn: String,
					userName un: String,
					password p: String,
					hostName hn: String,
					hostPort hp: Int) {
			resourceType = rt
			resourceId = ri
			resourceName = rn
			userName = un
			password = p
			hostName = hn
			hostPort = hp
		}
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
	
	public struct SwiftletInstance {
		public let resourceId: String
		public let resourceName: String
		public let hostName: String
		public let hostPorts: [Int]
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
	
	static func prefixedEnvList(_ named: String) -> [String] {
		if let e = env["\(paCloudFormationEnvPrefix)\(named)"] {
			return e.split(separator: ":").map(String.init)
		}
		return []
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
	private static func rdsByName(_ name: String, type: RDSInstance.DBType) -> RDSInstance? {
		guard let un = prefixedEnv("\(name)_USERNAME"),
			let pw = prefixedEnv("\(name)_PASSWORD"),
			let hst = prefixedEnv("\(name)_HOST"),
			let prtStr = prefixedEnv("\(name)_PORT"),
			let prt = Int(prtStr),
			let id = prefixedEnv("\(name)_ID") else {
				return nil
		}
		return RDSInstance(resourceType: type, resourceId: id, resourceName: name, userName: un, password: pw, hostName: hst, hostPort: prt)
	}
	
	static func listRDSInstances() -> [RDSInstance] {
		var ret: [RDSInstance] = []
		let postgresList = prefixedEnvList("\(paCloudFormationRDSPrefix)\(paCloudFormationPostgres)")
		ret.append(contentsOf: postgresList.flatMap { rdsByName($0, type: .postgres) })
		let mysqlList = prefixedEnvList("\(paCloudFormationRDSPrefix)\(paCloudFormationMySQL)")
		ret.append(contentsOf: mysqlList.flatMap { rdsByName($0, type: .mysql) })
		return ret
	}
	static func listRDSInstances(type: RDSInstance.DBType) -> [RDSInstance] {
		return listRDSInstances().filter { $0.resourceType == type }
	}
}

public extension CloudFormation {
	private static func elastiCacheByName(_ name: String, type: ElastiCacheInstance.ElastiCacheType) -> ElastiCacheInstance? {
		guard let hst = prefixedEnv("\(name)_HOST"),
			let prtStr = prefixedEnv("\(name)_PORT"),
			let prt = Int(prtStr),
			let id = prefixedEnv("\(name)_ID") else {
				return nil
		}
		return ElastiCacheInstance(resourceType: .redis, resourceId: id, resourceName: name, hostName: hst, hostPort: prt)
	}
	static func listElastiCacheInstances() -> [ElastiCacheInstance] {
		let redisList = prefixedEnvList("\(paCloudFormationElastiCachePrefix)\(paCloudFormationRedis)")
		return redisList.flatMap { elastiCacheByName($0, type: .redis) }
	}
	static func listElastiCacheInstances(type: ElastiCacheInstance.ElastiCacheType) -> [ElastiCacheInstance] {
		return listElastiCacheInstances().filter { $0.resourceType == type }
	}
}

public extension CloudFormation {
	private static func swiftletByName(_ name: String) -> SwiftletInstance? {
		guard let hst = prefixedEnv("\(name)_HOST"),
			let prtStr = prefixedEnv("\(name)_PORTS"),
			let id = prefixedEnv("\(name)_ID") else {
				return nil
		}
		let prts = prtStr.split(separator: ":").map(String.init).flatMap { Int($0) }
		return SwiftletInstance(resourceId: id, resourceName: name, hostName: hst, hostPorts: prts)
	}
	static func listSwiftlets() -> [SwiftletInstance] {
		let swiftletList = prefixedEnvList("\(paCloudFormationSwiftletsPrefix)")
		return swiftletList.flatMap { swiftletByName($0) }
	}
}


public extension CloudFormation {
	static func swiftletInput(named: String) -> String? {
		return prefixedEnv("SWIFTLET_INPUT_\(named.uppercased())")
	}
}

/*
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
*/

