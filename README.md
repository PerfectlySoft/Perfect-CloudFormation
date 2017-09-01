# Perfect-CloudFormation

This package provides support for services deployed to AWS through Perfect Assistant 2.1's CloudFormation deployment tools. It permits server instances to find and connect to the RDS and ElastiCache instances that were deployed along with the application.

To ustilize this package, `import PerfectCloudFormation` and then call either `CloudFormation.listRDSInstances()` or `CloudFormation.listElastiCacheInstances()`.

```swift
public extension CloudFormation {
	static func listRDSInstances() -> [RDSInstance]
	static func listRDSInstances(type: RDSInstance.DBType) -> [RDSInstance]
}

public extension CloudFormation {
	static func listElastiCacheInstances() -> [ElastiCacheInstance]
	static func listElastiCacheInstances(type: ElastiCacheInstance.ElastiCacheType) -> [ElastiCacheInstance]
}
```

RDS and ElastiCache instances are represented by the following structs.

```swift
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
}
```


