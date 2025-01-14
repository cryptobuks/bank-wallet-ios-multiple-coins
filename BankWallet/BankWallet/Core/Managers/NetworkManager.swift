import Foundation
import RxSwift
import Alamofire
import ObjectMapper

enum NetworkError: Error {
    case invalidRequest
    case mappingError
    case noConnection
    case serverError(status: Int, data: Any?)
}

class RequestRouter: URLRequestConvertible {
    private let request: URLRequest
    private let encoding: ParameterEncoding
    private let parameters: [String: Any]?

    init(request: URLRequest, encoding: ParameterEncoding, parameters: [String: Any]?) {
        self.request = request
        self.encoding = encoding
        self.parameters = parameters
    }

    func asURLRequest() throws -> URLRequest {
        return try encoding.encode(request, with: parameters)
    }

}

class NetworkManager {
    private let apiUrl: String

    private let ipfsDayFormatter = DateFormatter()
    private let ipfsHourFormatter = DateFormatter()
    private let ipfsMinuteFormatter = DateFormatter()

    required init(appConfigProvider: IAppConfigProvider) {
        self.apiUrl = appConfigProvider.apiUrl

        ipfsHourFormatter.timeZone = TimeZone(abbreviation: "UTC")
        ipfsHourFormatter.dateFormat = "yyyy/MM/dd/HH"

        ipfsDayFormatter.timeZone = TimeZone(abbreviation: "UTC")
        ipfsDayFormatter.dateFormat = "yyyy/MM/dd"

        ipfsMinuteFormatter.timeZone = TimeZone(abbreviation: "UTC")
        ipfsMinuteFormatter.dateFormat = "mm"
    }

    private func request(withMethod method: HTTPMethod, path: String, parameters: [String: Any]? = nil) -> URLRequestConvertible {
        let baseUrl = URL(string: apiUrl)!
        var request = URLRequest(url: baseUrl.appendingPathComponent(path))
        request.httpMethod = method.rawValue

        request.setValue("application/json", forHTTPHeaderField: "Accept")

        return RequestRouter(request: request, encoding: method == .get ? URLEncoding.default : JSONEncoding.default, parameters: parameters)
    }

    private func observable(forRequest request: URLRequestConvertible) -> Observable<DataResponse<Any>> {
        let observable = Observable<DataResponse<Any>>.create { observer in
//            print("API OUT: \(request.urlRequest?.url?.path ?? "nil path")")

            let requestReference = Alamofire.request(request)
                    .validate()
                    .responseJSON(queue: DispatchQueue.global(qos: .background), completionHandler: { response in
                        observer.onNext(response)
                        observer.onCompleted()
                    })

            return Disposables.create {
                requestReference.cancel()
            }
        }

        return observable.do(onNext: { dataResponse in
            switch dataResponse.result {
            case .success:
//            case .success(let result):
//                print("API IN: SUCCESS: \(dataResponse.request?.url?.path ?? ""): response = \(result)")
                ()
            case .failure:
                let data = dataResponse.data.flatMap {
                    try? JSONSerialization.jsonObject(with: $0, options: .allowFragments)
                }

                print("API IN: ERROR: \(dataResponse.request?.url?.path ?? ""): status = \(dataResponse.response?.statusCode ?? 0), response: \(data.map { "\($0)" } ?? "nil")")
                ()
            }
        })
    }

    private func observable<T>(forRequest request: URLRequestConvertible, mapper: @escaping (Any) -> T?) -> Observable<T> {
        return self.observable(forRequest: request)
                .flatMap { dataResponse -> Observable<T> in
                    switch dataResponse.result {
                    case .success(let result):
                        if let value = mapper(result) {
                            return Observable.just(value)
                        } else {
                            return Observable.error(NetworkError.mappingError)
                        }
                    case .failure:
                        if let response = dataResponse.response {
                            let data = dataResponse.data.flatMap { try? JSONSerialization.jsonObject(with: $0, options: .allowFragments) }
                            return Observable.error(NetworkError.serverError(status: response.statusCode, data: data))
                        } else {
                            return Observable.error(NetworkError.noConnection)
                        }
                    }
                }
    }

    private func observable<T: ImmutableMappable>(forRequest request: URLRequestConvertible) -> Observable<[T]> {
        return observable(forRequest: request, mapper: { json in
            if let jsonArray = json as? [[String: Any]] {
                return jsonArray.compactMap { try? T(JSONObject: $0) }
            }
            return nil
        })
    }

    private func observable<T: ImmutableMappable>(forRequest request: URLRequestConvertible) -> Observable<T> {
        return observable(forRequest: request, mapper: { json in
            if let jsonObject = json as? [String: Any], let object = try? T(JSONObject: jsonObject) {
                return object
            }
            return nil
        })
    }

    private func observable<T>(forRequest request: URLRequestConvertible) -> Observable<T> {
        return observable(forRequest: request, mapper: { json in
            if let object = json as? T {
                return object
            }
            return nil
        })
    }

}

extension NetworkManager: IRateNetworkManager {

    func getLatestRateData(currencyCode: String) -> Observable<LatestRateData> {
        return observable(forRequest: request(withMethod: .get, path: "xrates/latest/\(currencyCode)/index.json"))
    }

    func getRate(coinCode: String, currencyCode: String, date: Date) -> Observable<Decimal?> {
        let dayPath = ipfsDayFormatter.string(from: date)
        let hourPath = ipfsHourFormatter.string(from: date)
        let minuteString = ipfsMinuteFormatter.string(from: date)

        let hourObservable: Observable<[String: String]> = observable(forRequest: request(withMethod: .get, path: "xrates/historical/\(coinCode)/\(currencyCode)/\(hourPath)/index.json"))
        let dayObservable: Observable<String> = observable(forRequest: request(withMethod: .get, path: "xrates/historical/\(coinCode)/\(currencyCode)/\(dayPath)/index.json"))

        return hourObservable
                .flatMap { rates -> Observable<Decimal?> in
                    if let rate = rates[minuteString], let decimal = Decimal(string: rate) {
                        return Observable.just(decimal)
                    }

                    return dayObservable.map { rate -> Decimal? in
                        return Decimal(string: rate)
                    }
                }
    }

}
extension NetworkManager: ITokenNetworkManager {

    func getTokens() -> Observable<[Coin]> {
        let tokenObservable: Observable<[[String: Any]]> = observable(forRequest: request(withMethod: .get, path: "blockchain/ETH/erc20/index.json"))
        return tokenObservable
                .map { tokens -> [Coin] in
                    var coins = [Coin]()
                    for token in tokens {
                        if let code = token["code"] as? String,
                           let name = token["name"] as? String,
                           let contract = token["contract"] as? String,
                           let decimal = token["decimal"] as? Int {
                                coins.append(Coin(title: name, code: code, type: .erc20(address: contract, decimal: decimal)))
                        }
                    }
                    return coins
                }
    }

}


extension NetworkManager: IJSONApiManager {

    func getJSON(url: String, parameters: [String: Any]? = nil) -> Observable<[String: Any]> {
        let baseUrl = URL(string: url)!

        var request = URLRequest(url: baseUrl)
        request.timeoutInterval = 10
        request.httpMethod = HTTPMethod.get.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestRouter = RequestRouter(request: request, encoding: URLEncoding.default, parameters: parameters)

        return observable(forRequest: requestRouter, mapper: { json in
            return (json as? [String: Any]) ?? [:]
        })
    }

}
