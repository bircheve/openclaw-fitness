import Foundation

final class BridgeNutritionRepository: NutritionRepository, @unchecked Sendable {
    private let baseURL: URL
    private var cached: NutritionPlan?

    init(baseURL: URL) {
        self.baseURL = baseURL
    }

    func loadPlan() async throws -> NutritionPlan {
        if let cached { return cached }

        let url = baseURL.appendingPathComponent("nutrition")
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw RepoError.offline
        }

        guard let http = response as? HTTPURLResponse else { throw RepoError.unknown }

        switch http.statusCode {
        case 200: break
        case 404: throw RepoError.notFound
        default: throw RepoError.server
        }

        do {
            let dto = try JSONDecoder().decode(NutritionPlanDTO.self, from: data)
            let plan = NutritionPlan(dto: dto)
            cached = plan
            return plan
        } catch {
            throw RepoError.decoding
        }
    }
}
