//
//  MongoDatabase.swift
//  MongoDB
//
//  Created by Kyle Jessup on 2015-11-20.
//  Copyright © 2015 PerfectlySoft. All rights reserved.
//
//===----------------------------------------------------------------------===//
//
// This source file is part of the Perfect.org open source project
//
// Copyright (c) 2015 - 2016 PerfectlySoft Inc. and the Perfect project authors
// Licensed under Apache License v2.0
//
// See http://perfect.org/licensing.html for license information
//
//===----------------------------------------------------------------------===//
//

import libmongoc

#if swift(>=3.0)
	extension UnsafeMutablePointer {
		public static func alloc(num: Int) -> UnsafeMutablePointer<Pointee> {
			return UnsafeMutablePointer<Pointee>.alloc(num)
		}
	}
#else
	typealias ErrorProtocol = ErrorType
	typealias OpaquePointer = COpaquePointer
	typealias OptionSet = OptionSetType
	extension String {
		init?(validatingUTF8: UnsafePointer<Int8>) {
			if let s = String.fromCString(validatingUTF8) {
				self.init(s)
			} else {
				return nil
			}
		}
	}
	extension UnsafeMutablePointer {
		var pointee: Memory {
			get { return self.memory }
			set { self.memory = newValue }
		}
		func deallocateCapacity(num: Int) {
			self.dealloc(num)
		}
		
		func deinitialize(count count: Int) {
			self.destroy(count)
		}
	}
#endif

public class MongoDatabase {

	var ptr: OpaquePointer

	public typealias Result = MongoResult

	public init(client: MongoClient, databaseName: String) {
		self.ptr = mongoc_client_get_database(client.ptr, databaseName)
	}
    
    deinit {
        close()
    }

	public func close() {
		if self.ptr != nil {
			mongoc_database_destroy(self.ptr)
			self.ptr = nil
		}
	}

	public func drop() -> Result {
		var error = bson_error_t()
		if mongoc_database_drop(self.ptr, &error) {
			return .Success
		}
		return Result.fromError(error)
	}

	public func name() -> String {
		return String(validatingUTF8: mongoc_database_get_name(self.ptr))!
	}

	public func createCollection(collectionName: String, options: BSON) -> Result {
		var error = bson_error_t()
		let col = mongoc_database_create_collection(self.ptr, collectionName, options.doc, &error)
		guard col != nil else {
			return Result.fromError(error)
		}
		return .ReplyCollection(MongoCollection(rawPtr: col))
	}

	public func getCollection(collectionName: String) -> MongoCollection {
		let col = mongoc_database_get_collection(self.ptr, collectionName)
        return MongoCollection(rawPtr: col)
	}

	public func collectionNames() -> [String] {
		let names = mongoc_database_get_collection_names(self.ptr, nil)
		var ret = [String]()
		if names != nil {
			var curr = names
			while curr.pointee != nil {
				ret.append(String(validatingUTF8: curr.pointee)!)
				curr = curr.successor()
			}
			bson_strfreev(names)
		}
		return ret
	}


}
