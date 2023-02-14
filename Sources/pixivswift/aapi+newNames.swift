//
//  aapi+newFNames.swift
//  
//
//  Created by theBreadCompany on 15.07.22.
//

import Foundation

extension AppPixivAPI {
    
    public func request(method: HttpMethod, url: URL, headers: Dictionary<String, String> = [:], params: Dictionary<String, String> = [:], data: Dictionary<String, String> = [:], req_auth: Bool = true) throws -> String {
        return try self.no_auth_requests_call(method: method, url: url, headers: headers, params: params, data: data, req_auth: true)
    }
    
    
}
