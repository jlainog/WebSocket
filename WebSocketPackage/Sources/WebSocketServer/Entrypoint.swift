import Vapor
import Logging

@main
enum Entrypoint {
    static func main() async throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)

        let app = try await Application.make(env)

        do {
            try configure(app)
        } catch {
            app.logger.report(error: error)
            throw error
        }

        try await app.execute()
        try await app.asyncShutdown()
    }
}
