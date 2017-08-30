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

import PerfectAWS

// rds instance enumeration
// acm cert access
// ... future things

public enum CloudFormation {
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
	
	public struct ACMCertificate {
		public let certificate: String
		public let certificateChain: String
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

public extension CloudFormation.ACMCertificate {
	init?(arn: String) {
		
		return nil
	}
}


